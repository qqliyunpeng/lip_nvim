local M = {}
local use_ascii_icons = require("configs.icons").use_ascii_icons()
-- 边栏尺寸的唯一定义源（见 configs/edgy.lua 顶部注释）
local edgy_cfg = require("configs.edgy")

-- NOTE: Copilot config intentionally kept separate from llm.nvim and Avante.
local copileOpts = {
    suggestion = { enabled = true, auto_trigger = vim.g.blink_enable_copilot or false }, -- 自动补全
    panel = { enabled = true }, -- Copilot 面板
    filetypes = { -- 启用 Copilot 的文件类型
        lua = true,
        python = true,
        javascript = false,
        typescript = false,
        markdown = true,
    },
    keymap = { -- 快捷键映射
        accept = "<Tab>",
        -- accept = "<M-j>",
        next = false,
        prev = false,
        dismiss = false,
    },
}

function M.copileConfig()
    require("copilot").setup(copileOpts)

    Snacks.toggle({
        name = "copilot",
        get = function()
            return vim.g.blink_enable_copilot or false
        end,
        set = function(state)
            vim.g.blink_enable_copilot = state
            vim.b.copilot_suggestion_auto_trigger = state
        end,
    }):map("<leader>uc")
end

local avanteOpts = {
    provider = "pi",
    session_recovery = {
        include_history_count = 1,
    },
    -- Disable diff-based apply flow and diff view as much as possible.
    -- (Keeps Avante usable for chat/ask without opening diff UIs.)
    diff = {
        enabled = false,
    },
    acp_providers = {
        codex = {
            command = "codex-acp",
            args = {},
            env = {
                OPENAI_API_KEY = os.getenv("CHATGPT_API_KEY"),
            },
        },
        pi = {
            command = "pi-acp",
            args = {},
        },
    },
    providers = {
        copilot = {},
        qwen = {
            __inherited_from = "openai",
            endpoint = "https://coding.dashscope.aliyuncs.com/v1",
            model = "qwen3.5-plus",
            api_key_name = "QWEN_API_KEY",
            timeout = 30000, -- Timeout in milliseconds
            extra_request_body = {
                temperature = 0.3,
                max_tokens = 1024,
            },
        },
        claude = {
            endpoint = "https://api.anthropic.com",
            model = "claude-sonnet-4-20250514",
            timeout = 30000, -- Timeout in milliseconds
            extra_request_body = {
                temperature = 0.3,
                max_tokens = 4096,
            },
        },
        moonshot = {
            endpoint = "https://api.moonshot.ai/v1",
            model = "kimi-k2-0711-preview",
            timeout = 30000, -- 超时时间（毫秒）
            extra_request_body = {
                temperature = 0.75,
                max_tokens = 32768,
            },
        },
        chatgpt = {
            __inherited_from = "openai",
            endpoint = "http://172.16.9.15:8317/v1",
            model = "gpt-5.2",
            api_key_name = "CHATGPT_API_KEY",
            timeout = 30000, -- Timeout in milliseconds
            extra_request_body = {
                temperature = 0.3,
                max_tokens = 1024,
            },
        },
    },
    input = {
        provider = "snacks",
        provider_opts = {
            title = "Avante Input",
            icon = " ",
            win = {
                keys = {
                    i_up = { "<Up>", "<Up>", mode = { "i", "n" }, expr = true },
                    i_down = { "<Down>", "<Down>", mode = { "i", "n" }, expr = true },
                },
            },
        },
    },
    mappings = {
        sidebar = {
            close = { "<Esc>", "q", "<C-c>" },
        },
    },

    behaviour = {
        enable_fastapply = false,
        auto_apply_diff = false,
        auto_suggestions = false, -- Experimental stage
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = false,
        minimize_diff = false, -- Whether to remove unchanged lines when applying a code block
        enable_token_counting = false, -- Whether to enable token counting. Default to true.
        auto_add_current_file = true, -- Whether to automatically add the current file when opening a new chat. Default to true.
        auto_approve_tool_permissions = true, -- Default: auto-approve all tools (no prompts)
        -- Examples:
        -- auto_approve_tool_permissions = false,                -- Show permission prompts for all tools
        -- auto_approve_tool_permissions = {"bash", "replace_in_file"}, -- Auto-approve specific tools only
        ---@type "popup" | "inline_buttons"
        confirmation_ui_style = "inline_buttons",
        --- Whether to automatically open files and navigate to lines when ACP agent makes edits
        ---@type boolean
        acp_follow_agent_locations = true,
    },

    windows = {
        -- position 只在 edgy 没接管时生效；接管后窗口归左侧 edgebar（configs/edgy.lua 的 left）
        position = "left", -- the position of the sidebar
        wrap = true, -- similar to vim.o.wrap
        -- 尺寸只有一个定义源：configs/edgy.lua 的 avante_width（接管后由 edgebar 实际分配）
        width = math.floor(edgy_cfg.avante_width * 100),
        spinner = {
            thinking = use_ascii_icons and { "?" } or { "󱍋" },
        },
        sidebar_header = {
            enabled = false, -- true, false to enable/disable the header
            align = "left", -- left, center, right for title
            rounded = true,
        },
        input = {
            prefix = "> ",
            -- Height of the input window in vertical layout。
            -- 必须和 edgebar 分给 AvanteInput 的行数一致，否则会跳动（见 configs/edgy.lua）。
            height = edgy_cfg.avante_input_height,
        },
        edit = {
            border = "rounded",
            start_insert = true, -- Start insert mode when opening the edit window
        },
        ask = {
            floating = false, -- Open the 'AvanteAsk' prompt in a floating window
            start_insert = false, -- Tab enters insert mode; Ctrl-h/j/k/l keeps normal mode
            border = "rounded",
            ---@type "ours" | "theirs"
            focus_on_apply = "ours", -- which diff to focus after applying
        },
    },
}

-- 历史载入和 edgy 排版都可能延后执行；等挂载后的布局回调结束再定位末尾。
-- 只在重新打开侧栏时调用，不干预用户随后向上翻阅历史。
local function follow_avante_history(sidebar)
    local result = sidebar.containers and sidebar.containers.result
    if not result then
        return
    end
    local winid, bufnr = result.winid, result.bufnr
    vim.schedule(function()
        vim.schedule(function()
            local current = sidebar.containers and sidebar.containers.result
            if
                not sidebar:is_open()
                or not current
                or current.winid ~= winid
                or current.bufnr ~= bufnr
                or not vim.api.nvim_win_is_valid(winid)
                or vim.api.nvim_win_get_buf(winid) ~= bufnr
            then
                return
            end
            sidebar.scroll = true
            vim.api.nvim_win_call(winid, function()
                vim.cmd("normal! Gzb")
            end)
        end)
    end)
end

local max_avante_history_sessions = 10
local avante_thinking_icon = use_ascii_icons and "[?]" or "󱍋"

local function set_avante_window_highlights(active)
    local sidebar_link = active == false and "NormalNC" or "Normal"
    pcall(vim.api.nvim_set_hl, 0, "AvanteSidebarNormal", { link = sidebar_link })
    pcall(vim.api.nvim_set_hl, 0, "AvantePromptInput", { link = "Normal" })
end

local function avante_winhighlight(winhl, filetype, active)
    local normal_group = "AvanteSidebarNormal"
    if filetype == "AvantePromptInput" then
        normal_group = "AvantePromptInput"
    end
    if not active then
        normal_group = "NormalNC"
    end

    local pieces = {}
    for piece in string.gmatch(winhl or "", "[^,]+") do
        if not piece:match("^Normal:") then
            table.insert(pieces, piece)
        end
    end
    -- 放到最后：winhighlight 里同名的 Normal 以后出现的为准；
    -- edgy 在 WinEnter 时还会追加视图自己的 Normal 映射，必须让焦点状态压过它。
    table.insert(pieces, "Normal:" .. normal_group)
    return table.concat(pieces, ",")
end

local avante_window_filetypes = {
    Avante = true,
    AvanteInput = true,
    AvantePromptInput = true,
    AvanteSelectedFiles = true,
    AvanteTodos = true,
}

local function update_avante_window_highlight(active)
    local filetype = vim.bo.filetype
    if not avante_window_filetypes[filetype] then
        return
    end

    vim.wo.winhighlight = avante_winhighlight(vim.wo.winhighlight, filetype, active)
end

local function sync_avante_window_highlights()
    local current_filetype = vim.bo.filetype
    local active = avante_window_filetypes[current_filetype] == true
    set_avante_window_highlights(active)

    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(winid) then
            vim.api.nvim_win_call(winid, function()
                update_avante_window_highlight(active)
            end)
        end
    end
end

local function setup_avante_window_highlight_autocmds()
    local group = vim.api.nvim_create_augroup("LipAvanteWindowHighlights", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "Avante", "AvanteInput", "AvantePromptInput", "AvanteSelectedFiles", "AvanteTodos" },
        callback = function()
            vim.schedule(sync_avante_window_highlights)
        end,
    })
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        group = group,
        callback = function()
            vim.schedule(sync_avante_window_highlights)
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = group,
        callback = function()
            vim.schedule(sync_avante_window_highlights)
        end,
    })
end

local function disable_avante_quitpre()
    -- Avante 默认按所有非侧栏窗口判断退出，会把浮动辅助窗口也计算在内；
    -- 移除默认逻辑，改由下方的普通文件窗口数量决定是否关闭侧栏。
    local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
        group = "avante_autocmds",
        event = "QuitPre",
    })
    if not ok then return end

    for _, autocmd in ipairs(autocmds) do
        pcall(vim.api.nvim_del_autocmd, autocmd.id)
    end
end

local function count_file_windows()
    local count = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        -- 仅统计当前标签页的普通窗口；未命名缓冲区也计入，sp/vs 分别计数。
        if vim.api.nvim_win_get_config(win).relative == ""
            and vim.bo[buf].buftype == ""
        then
            count = count + 1
        end
    end
    return count
end

local function close_explorer()
    require("configs.explorer").close()
end

-- Avante 会把 ACP 的 thinking 流(大量 agent_thought_chunk)累积成一条
-- thinking 消息并逐行展开渲染。这里在渲染出口拦截该消息,只输出一行占位,
-- 既保留完整思考过程(不改 thinkingLevel),又不让思考刷屏。
-- thinking 消息只用于本地显示,不会进入发给 ACP 的 prompt,因此是纯显示层改动。
-- 渲染出口 Render.message_to_lines 是 sidebar(含全屏视图)唯一的消息渲染入口。
local avante_thinking_placeholder = "Thinking..."

local function install_avante_thinking_placeholder()
    local ok, Render = pcall(require, "avante.history.render")
    if not ok or Render._lip_thinking_placeholder then
        return
    end

    local Helpers = require("avante.history.helpers")
    local Line = require("avante.ui.line")
    local Utils = require("avante.utils")

    local original_message_to_lines = Render.message_to_lines
    local function is_thinking_message(message)
        if type(message) ~= "table" or type(message.message) ~= "table" then
            return false
        end
        local ok, result = pcall(Helpers.is_thinking_message, message)
        return ok and result == true
    end

    Render.message_to_lines = function(message, messages, expanded)
        if is_thinking_message(message) then
            return { Line:new({ { Utils.icon("🤔 ") .. avante_thinking_placeholder } }) }
        end
        return original_message_to_lines(message, messages, expanded)
    end

    Render._lip_thinking_placeholder = true
end

function M.avanteConfig()
    -- Lazy.nvim 可能在 Avante 模块仍处于加载状态时再次进入配置回调
    -- （例如上一次命令调用加载失败后）。保持回调幂等，避免重复进入
    -- `require("avante")`。
    if vim.g.lip_avante_configuring or vim.g.lip_avante_configured then
        return
    end
    vim.g.lip_avante_configuring = true

    local avante_build_cpath = vim.fn.stdpath("data") .. "/lazy/avante.nvim/build/?.so"
    if not package.cpath:find(avante_build_cpath, 1, true) then
        package.cpath = package.cpath .. ";" .. avante_build_cpath
    end

    local ok, avante = pcall(require, "avante")
    if not ok then
        vim.g.lip_avante_configuring = false
        error(avante)
    end

    local Utils = require("avante.utils")
    if not rawget(Utils, "_lip_single_width_thinking_icon") then
        local original_icon = Utils.icon
        Utils.icon = function(icon, fallback)
            if icon == "🤔 " then
                icon = avante_thinking_icon .. " "
                fallback = icon
            end
            return original_icon(icon, fallback)
        end
        rawset(Utils, "_lip_single_width_thinking_icon", true)
    end

    avante.setup(avanteOpts)
    -- Plan B：让流式输出只重写 buffer 尾部，配合 render-markdown 增量渲染
    require("configs.avante_incremental_render").setup_avante()
    install_avante_thinking_placeholder()
    disable_avante_quitpre()
    vim.g.lip_avante_configured = true
    vim.g.lip_avante_configuring = false
    set_avante_window_highlights()
    setup_avante_window_highlight_autocmds()

    -- Avante 完成回答后主动检查磁盘变化，及时刷新 AI 已修改的文件。
    local refresh_group = vim.api.nvim_create_augroup("LipAvanteRefreshFiles", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = refresh_group,
        pattern = "AvanteViewBufferUpdated",
        callback = function()
            local views = {}
            for _, winid in ipairs(vim.api.nvim_list_wins()) do
                views[winid] = vim.api.nvim_win_call(winid, vim.fn.winsaveview)
            end

            vim.cmd("checktime")
            vim.schedule(function()
                -- `checktime` 会重新加载已变更的缓冲区，但 Gitsigns 可能仍缓存着旧索引。
                -- 重新加载后刷新标记，使图标和状态栏及时反映 Avante 的修改。
                local ok, gitsigns = pcall(require, "gitsigns")
                if ok then
                    pcall(gitsigns.refresh)
                end

                for winid, view in pairs(views) do
                    if vim.api.nvim_win_is_valid(winid) then
                        vim.api.nvim_win_call(winid, function()
                            view.lnum = math.min(view.lnum, vim.api.nvim_buf_line_count(0))
                            vim.fn.winrestview(view)
                        end)

                        local bufnr = vim.api.nvim_win_get_buf(winid)
                        if vim.bo[bufnr].filetype == "Avante" then
                            local ok, render_markdown = pcall(require, "render-markdown")
                            if ok then
                                pcall(render_markdown.render, {
                                    buf = bufnr,
                                    win = winid,
                                    event = "AvanteViewBufferUpdated",
                                })
                            end
                        end
                    end
                end
                vim.cmd("redraw")
            end)
        end,
    })

    local Path = require("avante.path")
    local History = require("avante.history")

    local original_history_new = Path.history.new
    Path.history.new = function(bufnr)
        local history = original_history_new(bufnr)
        local max_index = 0
        for _, existing in ipairs(Path.history.list(bufnr)) do
            local index = tonumber(existing.filename:match("^(%d+)%.json$"))
            max_index = math.max(max_index, index or 0)
        end
        history.filename = string.format("%d.json", max_index + 1)
        return history
    end

    local function prune_avante_history(bufnr)
        if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        local histories = Path.history.list(bufnr)
        for _, history in ipairs(histories) do
            if #History.get_history_messages(history) == 0 and #history.entries == 0 then
                Path.history.delete(bufnr, history.filename)
            end
        end

        histories = Path.history.list(bufnr)
        for i = max_avante_history_sessions + 1, #histories do
            Path.history.delete(bufnr, histories[i].filename)
        end
    end

    local Api = require("avante.api")
    local original_ask = Api.ask
    Api.ask = function(opts)
        if opts and opts.new_chat == true then
            prune_avante_history(vim.api.nvim_get_current_buf())
        end
        return original_ask(opts)
    end

    -- Avante auto-connects ACP providers by submitting an empty request when
    -- the sidebar opens. With Codex ACP this can restore the previous session
    -- and show "generating" immediately, so suppress only that empty submit.
    local ok_sidebar, Sidebar = pcall(require, "avante.sidebar")
    if ok_sidebar and not Sidebar._lip_input_hint_in_heirline then
        Sidebar.show_input_hint = function(self)
            self:close_input_hint()
        end
        Sidebar._lip_input_hint_in_heirline = true
    end
    if ok_sidebar and not Sidebar._lip_tab_enters_input_insert then
        local original_switch_window_focus = Sidebar.switch_window_focus
        Sidebar.switch_window_focus = function(self, direction)
            local result = original_switch_window_focus(self, direction)
            if vim.bo.filetype == "AvanteInput" then
                vim.cmd("noautocmd startinsert!")
            end
            return result
        end
        Sidebar._lip_tab_enters_input_insert = true
    end
    -- Avante 只把 Tab/<S-Tab> 绑定到 n/i 模式。在 visual/visual-line/visual-block
    -- 下按 Tab 原本没有任何反应，这里补上 x 模式的窗口切换映射。
    if ok_sidebar and not Sidebar._lip_switch_window_in_visual_mode then
        local Config = require("avante.config")
        local original_setup_window_navigation = Sidebar.setup_window_navigation
        Sidebar.setup_window_navigation = function(self, container)
            original_setup_window_navigation(self, container)

            local buf = vim.api.nvim_win_get_buf(container.winid)
            local map_opts = { buffer = buf, noremap = true, silent = true, nowait = true }
            vim.keymap.set("x", Config.mappings.sidebar.switch_windows, function()
                self:switch_window_focus("next")
            end, map_opts)
            vim.keymap.set("x", Config.mappings.sidebar.reverse_switch_windows, function()
                self:switch_window_focus("previous")
            end, map_opts)
        end
        Sidebar._lip_switch_window_in_visual_mode = true
    end
    -- Avante 提交时会强制聚焦输出框。仅当请求来自输入框时
    -- 拦截这一次聚焦，并在提交后保持输入窗口的 Normal 模式。
    if ok_sidebar and not Sidebar._lip_keep_input_focus_on_submit then
        local original_update_content = Sidebar.update_content
        Sidebar.update_content = function(self, content, opts)
            if self._lip_submitting_from_input and opts and opts.focus then
                opts = vim.tbl_extend("force", {}, opts, { focus = false })
            end
            return original_update_content(self, content, opts)
        end

        local original_submit_input = Sidebar.submit_input
        Sidebar.submit_input = function(self)
            local input_winid = self.containers.input.winid
            local keep_input_focus = vim.api.nvim_get_current_win() == input_winid
            self._lip_submitting_from_input = keep_input_focus
            local ok_submit, result = pcall(original_submit_input, self)
            self._lip_submitting_from_input = nil
            if keep_input_focus then
                vim.cmd("noautocmd stopinsert")
            end
            if not ok_submit then
                error(result)
            end
            return result
        end
        Sidebar._lip_keep_input_focus_on_submit = true
    end
    -- handle_submit() 会先渲染，再追加当前用户消息。ACP 续接历史会话时
    -- 不会回显该消息，因此追加后刷新一次，以显示提问及历史分隔符。
    if ok_sidebar and not Sidebar._lip_render_submitted_user_message then
        local original_handle_submit = Sidebar.handle_submit
        Sidebar.handle_submit = function(self, request)
            local messages = History.get_history_messages(self.chat_history)
            local previous_count = #messages
            local result = original_handle_submit(self, request)
            messages = History.get_history_messages(self.chat_history)
            local last_message = messages[#messages]
            if #messages > previous_count and last_message and last_message.is_user_submission then
                self:update_content("", { focus = false })
            end
            return result
        end
        Sidebar._lip_render_submitted_user_message = true
    end
    if ok_sidebar and not Sidebar._lip_skip_empty_open_submit then
        local original_open = Sidebar.open
        Sidebar.open = function(self, opts)
            local was_open = self:is_open()
            local had_local_handle_submit = rawget(self, "handle_submit") ~= nil
            local original_handle_submit = self.handle_submit

            self.handle_submit = function(sidebar, request, ...)
                if request == "" then
                    return
                end
                return original_handle_submit(sidebar, request, ...)
            end

            local ok_open, result = pcall(original_open, self, opts)
            if had_local_handle_submit then
                self.handle_submit = original_handle_submit
            else
                self.handle_submit = nil
            end
            if not ok_open then
                error(result)
            end
            if not was_open then
                follow_avante_history(self)
                vim.schedule(function()
                    if vim.bo.filetype == "AvanteInput" then
                        vim.cmd("noautocmd startinsert!")
                    end
                end)
            end
            return result
        end
        Sidebar._lip_skip_empty_open_submit = true
    end
    -- edgy 接管 avante 容器后（configs/edgy.lua 的 M.avante = true），高度只能有一个权威。
    -- avante 的 adjust_layout() 按「整屏行数」算自己该多高
    -- （sidebar.lua 的 get_result_container_height = lines - input.height - selected_code
    --  - selected_files - todos），既不知道 tabline/statusline/cmdheight，
    -- 也不知道自己只是 40% 宽边栏里的一列；它一 nvim_win_set_height，
    -- nvim 只能从同列的 Explorer / 选中代码 / todos 身上扣行（实测会被压成 1 行），
    -- 接下来 edgy 再改回来 —— 两边来回抢就是高度抖动 / 底部留白。
    -- 因此把那四个「avante 认为自己该有多高」的 getter 改成「读当前窗口高度」：
    -- adjust_layout() 和 render_selected_files() 里的 set_height 就都变成同一个值（空转），
    -- 尺寸完全交给 edgebar（configs/edgy.lua 里的绝对行数）。
    -- 容器窗口还没建或已销毁时返回原值，保证首次 mount 仍能正常开窗。
    if ok_sidebar and edgy_cfg.avante and not Sidebar._lip_edgy_owns_heights then
        local function live_height(container)
            if not container or type(container.winid) ~= "number" then
                return nil
            end
            if not vim.api.nvim_win_is_valid(container.winid) then
                return nil
            end
            return vim.api.nvim_win_get_height(container.winid)
        end

        for _, spec in ipairs({
            { getter = "get_result_container_height", container = "result" },
            { getter = "get_selected_code_container_height", container = "selected_code" },
            { getter = "get_selected_files_container_height", container = "selected_files" },
            { getter = "get_todos_container_height", container = "todos" },
        }) do
            local original = Sidebar[spec.getter]
            Sidebar[spec.getter] = function(self, ...)
                local height = live_height(self.containers and self.containers[spec.container])
                if height then
                    return height
                end
                return original(self, ...)
            end
        end
        Sidebar._lip_edgy_owns_heights = true
    end

    -- edgy 的 BufWinEnter layout 是同步的，而 Avante 的 render() 会连续 mount
    -- result / input / selected_files 等多个 nui Split。中途提前排版会让 input
    -- 先占满整列，随后 nui 缩回 10 行时多出的行被塞进 cmdheight，heirline 就会
    -- 停在上半屏。render 期间暂停 edgy layout，结束后再补一次排版；同时把
    -- cmdheight 恢复成打开前的值，避免残留空白。
    if ok_sidebar and edgy_cfg.avante and not Sidebar._lip_edgy_pause_render then
        local original_render = Sidebar.render
        Sidebar.render = function(self, opts)
            local cmdheight = vim.o.cmdheight
            vim.g.lip_edgy_pause = true
            local ok_render, result = pcall(original_render, self, opts)
            vim.g.lip_edgy_pause = nil
            if vim.o.cmdheight ~= cmdheight then
                vim.o.cmdheight = cmdheight
            end
            if not ok_render then
                error(result)
            end
            vim.schedule(function()
                pcall(function()
                    require("edgy.layout").update()
                end)
            end)
            return result
        end
        Sidebar._lip_edgy_pause_render = true
    end

    -- Avante 选择编辑会在构建提示词前创建新的 ACP 会话。
    -- 编辑请求没有聊天历史，因此强制走普通提示词路径；
    -- 否则 Codex ACP 会收到空提示词并拒绝请求。
    local ok_llm, Llm = pcall(require, "avante.llm")
    -- 加载已有 ACP 会话时会重放远端历史。本地已经保存了同一份历史，
    -- 因此加载期间忽略重放消息，避免它们插到当前提问之后并打乱顺序。
    if ok_llm and not Llm._lip_skip_loaded_session_replay then
        Llm._load_acp_session_and_continue = function(opts, acp_client, session_id)
            local original_on_messages_add = opts.on_messages_add
            opts.on_messages_add = function() end
            acp_client:load_session(session_id, require("avante.utils").root.get(), {}, function(_, err)
                if err then
                    opts.on_messages_add = original_on_messages_add
                    Llm._create_acp_session_and_continue(opts, acp_client)
                    return
                end
                vim.schedule(function()
                    opts.on_messages_add = original_on_messages_add
                    if not opts.just_connect_acp_client then
                        Llm._continue_stream_acp(opts, acp_client, session_id)
                    end
                end)
            end)
        end
        Llm._lip_skip_loaded_session_replay = true
    end
    if ok_llm and not Llm._lip_acp_edit_prompt_fix then
        local original_continue_stream_acp = Llm._continue_stream_acp
        Llm._continue_stream_acp = function(opts, acp_client, session_id)
            if opts and opts.mode == "editing" and opts.acp_session_id and not opts.history_messages then
                local original_acp_session_id = opts.acp_session_id
                opts.acp_session_id = nil
                local ok_continue, result = pcall(original_continue_stream_acp, opts, acp_client, session_id)
                opts.acp_session_id = original_acp_session_id
                if not ok_continue then
                    error(result)
                end
                return result
            end
            return original_continue_stream_acp(opts, acp_client, session_id)
        end
        Llm._lip_acp_edit_prompt_fix = true
    end

    -- 某些 Neovim/Avante 组合会漏掉用于清理可视选择提示的
    -- buffer-local ModeChanged 事件。在编辑器不再处于可视模式时，
    -- 仅清除 Avante 快捷键提示 extmark。
    local ok_selection, Selection = pcall(require, "avante.selection")
    if ok_selection and not Selection._lip_visual_hint_cleanup_fix then
        local avante_selection_ns = vim.api.nvim_create_namespace("avante_selection")
        local visual_block = vim.api.nvim_replace_termcodes("<C-v>", true, true, true)

        local function is_visual_mode()
            local mode = vim.fn.mode()
            return mode == "v" or mode == "V" or mode == visual_block
        end

        local function clear_avante_selection_hints()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) then
                    pcall(vim.api.nvim_buf_clear_namespace, buf, avante_selection_ns, 0, -1)
                end
            end
        end

        vim.api.nvim_create_autocmd({ "ModeChanged", "BufLeave", "WinLeave", "InsertEnter" }, {
            callback = function()
                vim.schedule(function()
                    if not is_visual_mode() then
                        clear_avante_selection_hints()
                    end
                end)
            end,
        })

        local original_on_exiting_visual_mode = Selection.on_exiting_visual_mode
        Selection.on_exiting_visual_mode = function(self, ...)
            local ok_exit, result = pcall(original_on_exiting_visual_mode, self, ...)
            clear_avante_selection_hints()
            if not ok_exit then
                error(result)
            end
            return result
        end

        Selection._lip_visual_hint_cleanup_fix = true
    end

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "Avante", "AvanteInput" },
        callback = function(ev)
            vim.keymap.set({ "n", "i", "x" }, "<C-End>", function()
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "Avante" then
                        vim.api.nvim_win_call(win, function()
                            vim.cmd("normal! Gzb")
                        end)
                    end
                end
            end, {
                buffer = ev.buf,
                silent = true,
                desc = "跳到 Avante 回答底部",
            })
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "AvanteSelectedFiles", "AvanteTodos", "AvanteInput" },
        callback = function(ev)
            local opts = { buffer = ev.buf, silent = true }

            -- normal mode: q 退出
            vim.keymap.set("n", "q", "<cmd>AvanteToggle<cr>", opts)

            -- normal mode: Ctrl-c 退出
            vim.keymap.set("n", "<C-c>", "<cmd>AvanteToggle<cr>", opts)

            -- normal mode: Tab 先进入 Insert，Insert 中再按 Tab 切换窗口
            vim.keymap.set("n", "<Tab>", "<cmd>startinsert<cr>", opts)

            -- insert mode: Ctrl-c 退出
            -- vim.keymap.set("i", "<C-c>", "<Esc><cmd>AvanteToggle<cr>", opts)
        end,
    })

    M.setup_quit_sidebars()
end

function M.setup_quit_sidebars()
    if vim.g.lip_quit_sidebars_installed then
        return
    end
    vim.g.lip_quit_sidebars_installed = true

    vim.api.nvim_create_autocmd("QuitPre", {
        callback = function()
            -- 有未保存修改时交给 Neovim 原生退出确认（yes/no），
            -- 不要先关闭窗口而打断确认流程。
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
                    return
                end
            end

            local has_qf = false
            local has_avante = false
            local has_explorer = require("configs.explorer").is_open()
            local file_window_count = count_file_windows()

            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
                if ok then
                    local bt = vim.bo[buf].buftype
                    local ft = vim.bo[buf].filetype

                    if bt == "quickfix" then
                        has_qf = true
                    end

                    if ft == "Avante" or ft == "AvanteInput" then
                        has_avante = true
                    end
                end
            end

            if has_qf then
                pcall(function()
                    vim.cmd("cclose")
                end)
            end

            local current_buf = vim.api.nvim_get_current_buf()
            if vim.bo[current_buf].buftype == "" and file_window_count == 1 then
                if has_avante then
                    pcall(function()
                        vim.cmd("AvanteToggle")
                    end)
                end

                if has_explorer then
                    close_explorer()
                end
            end
        end,
    })
end

M._test = {
    follow_avante_history = follow_avante_history,
    avante_winhighlight = avante_winhighlight,
    count_file_windows = count_file_windows,
    disable_avante_quitpre = disable_avante_quitpre,
    install_avante_thinking_placeholder = install_avante_thinking_placeholder,
    set_avante_window_highlights = set_avante_window_highlights,
}

return M
