local M = {}

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
    provider = "codex",
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

    windows = {
        position = "left", -- the position of the sidebar
        wrap = true, -- similar to vim.o.wrap
        width = 40, -- default % based on available width
        sidebar_header = {
            enabled = true, -- true, false to enable/disable the header
            align = "left", -- left, center, right for title
            rounded = true,
        },
        input = {
            prefix = "> ",
            height = 10, -- Height of the input window in vertical layout
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
            auto_add_current_file = false, -- Whether to automatically add the current file when opening a new chat. Default to true.
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
    },
}

local max_avante_history_sessions = 50

local function set_avante_window_highlights()
    pcall(vim.api.nvim_set_hl, 0, "AvanteSidebarNormal", { link = "Normal" })
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
    local found_normal = false
    for piece in string.gmatch(winhl or "", "[^,]+") do
        if piece:match("^Normal:") then
            table.insert(pieces, "Normal:" .. normal_group)
            found_normal = true
        else
            table.insert(pieces, piece)
        end
    end
    if not found_normal then
        table.insert(pieces, "Normal:" .. normal_group)
    end
    return table.concat(pieces, ",")
end

local avante_window_filetypes = {
    Avante = true,
    AvanteInput = true,
    AvantePromptInput = true,
}

local function update_avante_window_highlight(active)
    local filetype = vim.bo.filetype
    if not avante_window_filetypes[filetype] then
        return
    end

    vim.wo.winhighlight = avante_winhighlight(vim.wo.winhighlight, filetype, active)
end

local function setup_avante_window_highlight_autocmds()
    local group = vim.api.nvim_create_augroup("LipAvanteWindowHighlights", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "Avante", "AvanteInput", "AvantePromptInput" },
        callback = function()
            local winid = vim.api.nvim_get_current_win()
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(winid) then
                    local active = vim.api.nvim_get_current_win() == winid
                    vim.api.nvim_win_call(winid, function()
                        update_avante_window_highlight(active)
                    end)
                end
            end)
        end,
    })
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        group = group,
        callback = function()
            update_avante_window_highlight(true)
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = group,
        callback = function()
            update_avante_window_highlight(false)
        end,
    })
end

function M.avanteConfig()
    local avante_build_cpath = vim.fn.stdpath("data") .. "/lazy/avante.nvim/build/?.so"
    if not package.cpath:find(avante_build_cpath, 1, true) then
        package.cpath = package.cpath .. ";" .. avante_build_cpath
    end

    require("avante").setup(avanteOpts)
    set_avante_window_highlights()
    setup_avante_window_highlight_autocmds()

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
    if ok_sidebar and not Sidebar._lip_input_hint_at_bottom then
        Sidebar.get_input_float_window_row = function(self)
            return math.max(vim.api.nvim_win_get_height(self.containers.input.winid) - 1, 0)
        end
        Sidebar._lip_input_hint_at_bottom = true
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

    -- Avante 选择编辑会在构建提示词前创建新的 ACP 会话。
    -- 编辑请求没有聊天历史，因此强制走普通提示词路径；
    -- 否则 Codex ACP 会收到空提示词并拒绝请求。
    local ok_llm, Llm = pcall(require, "avante.llm")
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
        pattern = { "AvanteSelectedFiles", "AvanteTodos", "AvanteInput" },
        callback = function(ev)
            local opts = { buffer = ev.buf, silent = true }

            -- normal mode: q 退出
            vim.keymap.set("n", "q", "<cmd>AvanteToggle<cr>", opts)

            -- normal mode: Ctrl-c 退出
            vim.keymap.set("n", "<C-c>", "<cmd>AvanteToggle<cr>", opts)

            -- insert mode: Ctrl-c 退出
            -- vim.keymap.set("i", "<C-c>", "<Esc><cmd>AvanteToggle<cr>", opts)
        end,
    })

    vim.api.nvim_create_autocmd("QuitPre", {
        callback = function()
            local has_qf = false
            local has_avante = false

            for _, win in ipairs(vim.api.nvim_list_wins()) do
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

            if has_avante then
                pcall(function()
                    vim.cmd("AvanteToggle")
                end)
            end
        end,
    })
end

M._test = {
    avante_winhighlight = avante_winhighlight,
    set_avante_window_highlights = set_avante_window_highlights,
}

return M
