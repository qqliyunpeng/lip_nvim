local M = {}

local copileOpts = {
    suggestion = { enabled = true, auto_trigger = false },  -- 自动补全
    panel = { enabled = true },                             -- Copilot 面板
    filetypes = {                                           -- 启用 Copilot 的文件类型
        lua = true,
        python = true,
        javascript = false,
        typescript = false,
        markdown = true,
    },
    keymap = {                                             -- 快捷键映射
        accept = "<CR>",
        -- accept = "<M-j>",
        next    = false,
        prev    = false,
        dismiss = false,
    },
}

function M.copileConfig()
    require("copilot").setup(copileOpts)

    local suggestion = require("copilot.suggestion")

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

    vim.keymap.set("i", "<CR>", function()
        if suggestion.is_visible() then
            suggestion.accept()
        else
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<CR>", true, false, true),
                "n",
                true
            )
        end
    end, { silent = true })
end

local avanteOpts = {
    provider = "chatgpt",
    providers = {
        copilot = {},
        qwen = {
            __inherited_from = "openai",
            endpoint = "https://coding.dashscope.aliyuncs.com/v1",
            model = "qwen3.5-plus",
            api_key_name = "QWEN_API_KEY",
            timeout = 30000, -- Timeout in milliseconds
            extra_request_body = {
                temperature = 0.75,
                max_tokens = 512,
            },
        },
        claude = {
            endpoint = "https://api.anthropic.com",
            model = "claude-sonnet-4-20250514",
            timeout = 30000, -- Timeout in milliseconds
            extra_request_body = {
                temperature = 0.75,
                max_tokens = 20480,
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
            -- model = "qwen3.5-plus",
            api_key_name = "CHATGPT_API_KEY",
            timeout = 30000, -- Timeout in milliseconds
            extra_request_body = {
                temperature = 0.75,
                max_tokens = 512,
            },
            -- tool_choice = "none",
        }
    },
    input = {
        provider = "snacks",
        provider_opts = {
            title = "Avante Input",
            iconns = " ",
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
        width = 30, -- default % based on available width
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
            start_insert = true, -- Start insert mode when opening the ask window
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
            enable_token_counting = true, -- Whether to enable token counting. Default to true.
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
    },
}

function M.avanteConfig()
    require('avante').setup(avanteOpts)

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
                pcall(vim.cmd, "cclose")
            end

            if has_avante then
                pcall(vim.cmd, "AvanteToggle")
            end
        end,
    })
end

return M

