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
-- 验证开关（改完需要重启 nvim 才生效）
--------------------------------------------------------------------------------
-- ENABLED.takeover_render = false
--     关掉「我们自己接管渲染」这一层，回到上游每帧整段重写的渲染方式：
--       - 顶部 B2：render-markdown 复用未变化的 extmark（否则是「清空全部 + 重建」）
--       - 下方 B1：avante 只从「第一行不同处」往后写 buffer（否则整段重写）
--       - B5：只写变化尾部时顺带做的 highlight namespace 清理
--     副作用：流式输出的闪烁 / 重复解析会回来（B2 当初就是为消除闪烁做的）。
--     其余与渲染方式无关的补丁（流式不进渲染缓存、侧栏 undolevels、
--     spinner 定时器、ACP 分片合并、logo extmark）继续生效，避免这些既有的
--     内存放大项污染这次对照。
local ENABLED = {
    takeover_render = false,
}

--------------------------------------------------------------------------------
-- B2: render-markdown 增量渲染
--------------------------------------------------------------------------------

function M.setup_render_markdown()
    if not ENABLED.takeover_render then
        return false
    end
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
-- B6: ACP 流式分片合并
--------------------------------------------------------------------------------

--- 把「连续同类的文本分片」攒起来合并成一条 update 再交给上游 handler。
---
--- 上游 _stream_acp 每收到一个 agent_message_chunk 就做一次
--- `content = content .. text`（agent_thought_chunk 的 thinking 字段同理），
--- 而 codex-acp 的分片只有几十字节级，于是整条回答会被反复整段复制：
--- O(分片数 × 回答长度)。实测 1MB 回答 / 32B 分片要拷贝约 16GB、主线程卡 5.1s、
--- 峰值内存 +70MB；合并后同样内容只要 3ms。
--- 上游语义本来就是把分片追加到最后一条 assistant 消息，所以合并后最终内容不变，
--- 只是交付频率从「每个分片」降到「每 window_ms 一次」，与侧栏 50ms 的渲染节流对齐。
---@param handler fun(update: table): nil
---@param window_ms? integer
---@return fun(update: table): nil
function M.coalesce_session_update_handler(handler, window_ms)
    window_ms = window_ms or 50
    local pending = nil
    local flush

    local function deliver(update)
        if update then
            handler(update)
        end
    end

    flush = function()
        if not pending then
            return
        end
        local update = pending
        pending = nil
        update.content.text = table.concat(update._lip_chunks)
        update._lip_chunks = nil
        deliver(update)
    end

    return function(update)
        -- 与上游的判定保持一致：只有 agent 正文 / 思考正文分片可以合并
        local kind = update and update.sessionUpdate
        local text = nil
        if update and type(update.content) == "table" and update.content.type == "text" then
            text = update.content.text
        end
        local coalescable = (kind == "agent_message_chunk" or kind == "agent_thought_chunk")
            and type(text) == "string"

        if coalescable and pending and pending.sessionUpdate == kind then
            pending._lip_chunks[#pending._lip_chunks + 1] = text
            return
        end

        -- 换类或来了别的 update：先把攒着的交付出去，保证顺序
        flush()
        if not coalescable then
            return deliver(update)
        end

        pending = update
        update._lip_chunks = { text }
        vim.defer_fn(flush, window_ms)
    end
end

--- B6: 把上面这个 wrapper 挂到 ACPClient 上。
--- 客户端是每次 _stream_acp 时新建的（ACPClient:new），在构造时包一层最省事：
--- 不改插件目录，`:Lazy update` 之后依然有效。
---@return boolean
function M.setup_acp_coalesce()
    if M._acp_coalesce_installed then
        return true
    end
    local ok, err = pcall(function()
        local ACPClient = require("avante.libs.acp_client")
        if rawget(ACPClient, "_lip_session_update_coalesced") then
            M._acp_coalesce_installed = true
            return
        end
        rawset(ACPClient, "_lip_session_update_coalesced", true)

        local orig_new = rawget(ACPClient, "new")
        rawset(ACPClient, "new", function(self, config)
            local handlers = config and config.handlers
            if
                handlers
                and not rawget(handlers, "_lip_coalesced")
                and type(handlers.on_session_update) == "function"
            then
                rawset(handlers, "_lip_coalesced", true)
                handlers.on_session_update = M.coalesce_session_update_handler(handlers.on_session_update)
            end
            return orig_new(self, config)
        end)

        M._acp_coalesce_installed = true
    end)
    if not ok then
        vim.notify("avante_incremental_render: ACP 分片合并补丁失败: " .. tostring(err), vim.log.levels.WARN)
    end
    return M._acp_coalesce_installed == true
end

--- B7: render_logo 每次 update_content 都会被调用，并重新给 logo 那几行加 extmark，
--- 旧的同样不会被清掉（每帧 +N 个，流式时随输出线性堆积）。这里包一层：先把上一次
--- 的 logo 区域清掉（正文的 extmark 都在 skip_line_count 之下，不受影响），再让上游照旧重建。
---@return boolean
function M.setup_logo_extmarks()
    if M._logo_installed then
        return true
    end
    local ok, err = pcall(function()
        local Sidebar = require("avante.sidebar")
        if rawget(Sidebar, "_lip_logo_patched") then
            M._logo_installed = true
            return
        end
        -- 同一个名字拿到的 namespace id 一定相同，可以直接按名字取。
        local result_ns = vim.api.nvim_create_namespace("AVANTE_RESULT_BUF_HL")
        local orig_render_logo = rawget(Sidebar, "render_logo")
        local logo_lines = 0
        rawset(Sidebar, "render_logo", function(self, ...)
            local result = self.containers and self.containers.result
            if logo_lines > 0 and result and result.bufnr and vim.api.nvim_buf_is_valid(result.bufnr) then
                vim.api.nvim_buf_clear_namespace(result.bufnr, result_ns, 0, logo_lines)
            end
            logo_lines = orig_render_logo(self, ...) or 0
            return logo_lines
        end)
        rawset(Sidebar, "_lip_logo_patched", true)
        M._logo_installed = true
    end)
    if not ok then
        vim.notify("avante_incremental_render: logo extmark 补丁失败: " .. tostring(err), vim.log.levels.WARN)
    end
    return M._logo_installed == true
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

        -- B3: 流式输出的那条消息不进「消息 → 渲染行」缓存。
        -- 上游 get_message_lines 的 LRU 键是 uuid:state:text_len（容量 100），流式时
        -- text_len 每个 chunk 都变，于是每个 chunk 都会塞进一份「整条回答」的渲染结果；
        -- 100 份 × 回答长度 → 内存随回答线性增长，而且答完也不会立刻释放。
        -- 流式中的消息下次渲染键必然失效，缓存本来就没有收益，跳过写入即可。
        if not rawget(Sidebar, "_lip_stream_cache_patched") then
            local orig_get_message_lines = rawget(Sidebar, "get_message_lines")
            -- 与上游状态判定保持一致：只有这些状态下「最后一条消息」才是增长中的
            local streaming_states = {
                generating = true,
                ["tool calling"] = true,
                thinking = true,
            }
            rawset(Sidebar, "get_message_lines", function(self, ctx, message, messages, ignore_record_prefix)
                if
                    message
                    and streaming_states[self.current_state]
                    and messages
                    and messages[#messages] == message
                    and message.state ~= "generating"
                    and not message.is_calling
                then
                    -- 复刻上游「缓存未命中」路径，只是不回写缓存
                    local lines = self:_get_message_lines(ctx, message, messages, ignore_record_prefix)
                    while #lines > 0 and tostring(lines[#lines]) == "" do
                        table.remove(lines)
                    end
                    return lines
                end
                return orig_get_message_lines(self, ctx, message, messages, ignore_record_prefix)
            end)
            rawset(Sidebar, "_lip_stream_cache_patched", true)
        end

        M.setup_acp_coalesce()
        M.setup_logo_extmarks()

        local Utils = require("avante.utils")
        -- avante.utils 有 __index 元表：读取未知字段会 require("avante.utils.<字段>")。
        -- 因此必须用 rawget/rawset 存标记，不能直接下标访问。
        if rawget(Utils, "_lip_incremental_update_buffer_lines") then
            return
        end

        local orig = rawget(Utils, "update_buffer_lines")

        if not ENABLED.takeover_render then
            -- 不接管写入（交回上游整段重写），但仍保留与渲染方式无关的两项：
            -- 侧栏 buffer 关掉 undo 记录（B4）、重写前清掉该区间的 highlight extmark（B5）。
            Utils.update_buffer_lines = function(ns_id, bufnr, old_lines, new_lines, skip_line_count)
                skip_line_count = skip_line_count or 0
                if vim.api.nvim_buf_is_valid(bufnr) then
                    if Utils.is_sidebar_buffer(bufnr) and vim.bo[bufnr].undolevels ~= -1 then
                        vim.bo[bufnr].undolevels = -1
                    end
                    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, skip_line_count, -1)
                end
                return orig(ns_id, bufnr, old_lines, new_lines, skip_line_count)
            end
            rawset(Utils, "_lip_incremental_update_buffer_lines", true)
            M._avante_installed = true
            return
        end

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

            -- B5: 上游 Line:set_highlights 走的是 vim.highlight.range，它建的是非
            -- ephemeral 的 extmark（不传 timeout 就不会自动清除），而 nvim_buf_set_lines
            -- 只会把被替换区间里的 extmark 折叠到末尾、并不删除。上游每帧给整段历史重上色，
            -- 于是这个 namespace 里的幽灵 extmark 一路堆积，且永远不会被回收
            -- （实测 1500 行 ≈ 112 万个 / +265MB）。B1 之后每帧只重上尾部，残留降到
            -- 「每行约 3 个」（同一行重渲染几次就多几个），这里再抹平：写尾部前先把
            -- [boundary, 末尾) 整段清掉再重新上色，boundary 以上的 extmark 保持不动。
            vim.api.nvim_buf_clear_namespace(bufnr, ns_id, boundary, -1)

            for i, line in ipairs(new_lines) do
                local line_pos = positions[i] or (skip_line_count + i - 1)
                local next_pos = positions[i + 1] or total
                if next_pos > boundary then
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
            -- B4: 侧边栏结果 buffer 只读展示，undo 没有意义，但每次 set_lines 都会留下
            -- undo 记录（上游整段重写时是 O(chunk²) 的内存）。只对 avante 自己的
            -- 侧边栏 buffer 关掉 undolevels，避免误伤真正的代码 buffer。
            if
                vim.api.nvim_buf_is_valid(bufnr)
                and Utils.is_sidebar_buffer(bufnr)
                and vim.bo[bufnr].undolevels ~= -1
            then
                vim.bo[bufnr].undolevels = -1
            end
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
