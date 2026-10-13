-- Plan B：让 avante 流式输出「增量渲染」——流式过程中持续渲染，但已经输出
-- 的内容不再被反复清空 / 重建（消除闪烁与重复解析）。
--
-- 需要两个补丁配合，缺一不可：
--   B1. avante 侧：update_buffer_lines 不再整段重写 buffer，只从「第一行不同处」
--       开始写。否则 nvim_buf_set_lines 会把整段范围内 render-markdown 的
--       extmark 全部折叠到末尾（已实测），增量就无从谈起。
--   B2. render-markdown 侧：把「清空全部 + 重建」换成「对标记做 diff」——位置与
--       内容都没变的标记直接复用旧 extmark（保留 id），只重建变化的部分。
--
-- 两个补丁都以运行时 monkey-patch 的方式实现（不直接改插件目录），
-- 这样 `:Lazy update` 之后依然有效。
local M = {}

--------------------------------------------------------------------------------
-- B2: render-markdown 增量渲染
--------------------------------------------------------------------------------

function M.setup_render_markdown()
    if M._rm_installed then
        return true
    end
    local ok, err = pcall(function()
        local ui = require("render-markdown.core.ui")
        local Decorator = require("render-markdown.lib.decorator")
        local Extmark = require("render-markdown.lib.extmark")
        local compat = require("render-markdown.lib.compat")
        local state = require("render-markdown.state")

        -- (1) 在构造时就把 opts.strict 固定为 false。
        --     否则 Extmark:show 会在渲染后改写旧标记的 opts，导致新旧标记
        --     deep_equal 失败、永远无法复用。
        if not Extmark._lip_strict_normalized then
            Extmark._lip_strict_normalized = true
            local orig_new = Extmark.new
            Extmark.new = function(mark)
                if mark.opts then
                    mark.opts.strict = false
                end
                return orig_new(mark)
            end
        end

        -- (2) 判断旧 extmark 是否仍然有效：buffer 编辑可能把它移动 / 折叠到别处。
        if not Extmark.is_valid_at then
            function Extmark:is_valid_at(ns, buf)
                if not self.id then
                    return false
                end
                local ok2, pos = pcall(vim.api.nvim_buf_get_extmark_by_id, buf, ns, self.id, {})
                if not ok2 or type(pos) ~= "table" or pos[1] == nil then
                    return false
                end
                return pos[1] == self.mark.start_row and pos[2] == self.mark.start_col
            end
        end

        -- (3) 用一个「标记级别的 diff」替换 clear() + set()。
        if not Decorator.reconcile then
            function Decorator:reconcile(ns, marks)
                -- 旧标记按 (row,col) 建索引
                local old = {}
                for _, extmark in ipairs(self.marks) do
                    local mark = extmark:get()
                    local pos = mark.start_row .. ":" .. mark.start_col
                    local list = old[pos]
                    if not list then
                        list = {}
                        old[pos] = list
                    end
                    list[#list + 1] = extmark
                end

                local result = {}
                for _, extmark in ipairs(marks) do
                    local mark = extmark:get()
                    local pos = mark.start_row .. ":" .. mark.start_col
                    local list = old[pos]
                    local reused = false
                    if list then
                        for i = #list, 1, -1 do
                            local candidate = list[i]
                            local cmark = candidate:get()
                            if
                                candidate:is_valid_at(ns, self.buf)
                                and vim.deep_equal(cmark.conceal, mark.conceal)
                                and vim.deep_equal(cmark.opts, mark.opts)
                                and vim.deep_equal(cmark.replace, mark.replace)
                            then
                                table.remove(list, i)
                                result[#result + 1] = candidate
                                reused = true
                                break
                            end
                        end
                    end
                    if not reused then
                        result[#result + 1] = extmark
                    end
                end

                -- 不再出现的旧标记：清掉
                for _, list in pairs(old) do
                    for _, extmark in ipairs(list) do
                        extmark:hide(ns, self.buf)
                    end
                end

                self.marks = result
                self.tick = self:get_tick()
                self.n = self.n + 1
            end
        end

        -- (4) 把 Updater:render 里的 clear() + set() 换成 reconcile()
        if not ui.updater._lip_incremental then
            ui.updater._lip_incremental = true
            ui.updater.render = function(self)
                if self:changed() then
                    self:parse(function(extmarks)
                        if not extmarks then
                            return
                        end
                        local initial = self.decorator:initial()
                        self.decorator:reconcile(ui.ns, extmarks)
                        if initial then
                            compat.fix_lsp_window(self.buf, self.win, extmarks)
                            state.on.initial({ buf = self.buf, win = self.win })
                        end
                        self:display()
                    end)
                else
                    self:display()
                end
            end
        end

        M._rm_installed = true
    end)

    if not ok then
        vim.notify("avante_incremental_render: render-markdown 补丁失败: " .. tostring(err), vim.log.levels.WARN)
    end
    return M._rm_installed == true
end

--------------------------------------------------------------------------------
-- B1: avante 最小化 buffer 写入
--------------------------------------------------------------------------------

function M.setup_avante()
    if M._avante_installed then
        return true
    end
    local ok, err = pcall(function()
        -- B2: 状态行 spinner 自循环——只在“进行中”的状态才续期。
        -- 上游 render_state 结尾是无条件 vim.defer_fn(..., 160)，终态（succeeded/failed/…）
        -- 也会每 160ms 重建一条 virt_lines extmark，空闲时白白触发整窗重绘。
        local Sidebar = require("avante.sidebar")
        if not rawget(Sidebar, "_lip_state_timer_patched") then
            local orig_render_state = rawget(Sidebar, "render_state")
            -- 与上游 render_state 中 spinner_char 的判定保持一致；
            -- 若 fork 新增了“进行中”状态，需要同步加到这里。
            local active_states = {
                generating = true,
                ["tool calling"] = true,
                thinking = true,
                compacting = true,
            }
            rawset(Sidebar, "render_state", function(self, ...)
                local ret = orig_render_state(self, ...)
                if not active_states[self.current_state] and self.state_timer then
                    pcall(function()
                        self.state_timer:stop()
                    end)
                    self.state_timer = nil
                end
                return ret
            end)
            rawset(Sidebar, "_lip_state_timer_patched", true)
        end

        local Utils = require("avante.utils")
        -- avante.utils 有 __index 元表：读取未知字段会 require("avante.utils.<字段>")。
        -- 因此必须用 rawget/rawset 存标记，不能直接下标访问。
        if rawget(Utils, "_lip_incremental_update_buffer_lines") then
            return
        end

        local orig = rawget(Utils, "update_buffer_lines")

        local function build(new_lines, skip_line_count)
            local cleaned, positions = {}, {}
            local cur = skip_line_count
            for idx, line in ipairs(new_lines) do
                local pieces = vim.split(tostring(line), "\n")
                positions[idx] = cur
                vim.list_extend(cleaned, pieces)
                cur = cur + #pieces
            end
            return cleaned, positions, cur
        end

        local function patched(ns_id, bufnr, old_lines, new_lines, skip_line_count)
            skip_line_count = skip_line_count or 0
            old_lines = old_lines or {}
            new_lines = new_lines or {}

            local cleaned, positions, total = build(new_lines, skip_line_count)

            -- 与当前 buffer 求公共前缀，只重写变化的那一段（流式时就是尾部）
            local current = vim.api.nvim_buf_get_lines(bufnr, skip_line_count, -1, false)
            local max = math.min(#current, #cleaned)
            local prefix = 0
            while prefix < max and current[prefix + 1] == cleaned[prefix + 1] do
                prefix = prefix + 1
            end
            if prefix == #current and prefix == #cleaned then
                return
            end
            local boundary = skip_line_count + prefix

            -- 沿用上游约定解绑旧事件
            for i, old_line in ipairs(old_lines) do
                if old_line and type(old_line.unbind_events) == "function" then
                    pcall(old_line.unbind_events, old_line, bufnr, skip_line_count + i)
                end
            end

            -- 关键：只写变化尾部，保持 boundary 以上的 extmark 不被破坏
            vim.api.nvim_buf_set_lines(bufnr, boundary, -1, false, vim.list_slice(cleaned, prefix + 1))

            for i, line in ipairs(new_lines) do
                local line_pos = positions[i] or (skip_line_count + i - 1)
                local next_pos = positions[i + 1] or total
                if next_pos > boundary then
                    if line_pos < boundary then
                        -- 跨越边界的行：先清掉它旧的 highlight，避免重复
                        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_pos, line_pos + 1)
                    end
                    if type(line.set_highlights) == "function" then
                        line:set_highlights(ns_id, bufnr, line_pos)
                    end
                end
                if type(line.bind_events) == "function" then
                    pcall(line.bind_events, line, ns_id, bufnr, line_pos + 1)
                end
            end

            vim.cmd("redraw")
        end

        Utils.update_buffer_lines = function(ns_id, bufnr, old_lines, new_lines, skip_line_count)
            local ok2, err2 = pcall(patched, ns_id, bufnr, old_lines, new_lines, skip_line_count)
            if not ok2 then
                vim.notify(
                    "avante_incremental_render: 尾部写入失败，回退到整段写入: " .. tostring(err2),
                    vim.log.levels.WARN
                )
                return orig(ns_id, bufnr, old_lines, new_lines, skip_line_count)
            end
        end
        rawset(Utils, "_lip_incremental_update_buffer_lines", true)
        M._avante_installed = true
    end)

    if not ok then
        vim.notify("avante_incremental_render: avante 补丁失败: " .. tostring(err), vim.log.levels.WARN)
    end
    return M._avante_installed == true
end

return M
