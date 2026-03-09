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
    provider = "qwen",
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
}

function M.avanteConfig()
    require('avante').setup(avanteOpts)

    vim.api.nvim_create_autocmd("FileType", {
        -- pattern = { "Avante", "AvanteInput" },
        pattern = { "AvanteInput" },
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

