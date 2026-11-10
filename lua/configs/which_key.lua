local M = {}

function M.setup()
    local wk = require('which-key')
    local use_ascii_icons = require("configs.icons").use_ascii_icons()
    require("which-key.plugins.registers").registers = '0123456789*+"-:.%/#=_abcdef'
    local opts = {
        preset = "helix",
        defaults = {},
        -- 仅对这些前缀显示 which-key，避免普通按键/鼠标事件误触发
        triggers = {
            { "<leader>", mode = { "n", "v" } },
            { "'", mode = { "n", "v" } },
            { '"', mode = { "n", "v" } },
            { "`", mode = { "n", "v" } },
            { "g", mode = { "n", "v" } },
            { "z", mode = { "n", "v" } },
            { "[", mode = { "n", "v" } },
            { "]", mode = { "n", "v" } },
        },
        spec = {
            {
                mode = { "n", "v" },
                {"<leader>a" , desc = "Avante keymap" },
                {"<leader>f", group = "Telescope" },
                {"<leader>b", group = "Buffer" },
                {"<leader>g", desc = "Git" },
                {"<leader>m", desc = "Marks" },
                {"<leader>w", desc = "LSP Workspace" },
                {"<leader>u", desc = "Disable/Dismiss/Toggle" },
                {"<leader><Space>", desc = "Remove the space ends" },
                {"<leader>K", hidden = true },
                {"<leader>ma", desc = "Bookmark picker" },
                {"<leader>mm", desc = "Bookmark Toggle" },
                {"<leader>mc", desc = "Bookmark Delete" },
                {"<leader>fs", desc = "Search with parameter" },
                {"<leader>fm", desc = "Mark list" },
                {"<leader>fe", desc = "Harpoon list" },
                {"<leader>ha" , desc = "Harpoon add current file" },
                {"<leader>t" , desc = "Table and todo" },
                {"<leader>tm", desc = "Table mode toggle" },
                {"<leader>s" , desc = "Surround, search, replace" },
                {"<leader>c" , desc = "Code action, rename, comment" },
                {"]D", desc = "Last diagnostic" },
            }
        },
        icons = {
            mappings = not use_ascii_icons, -- 在不支持nerd的里边不启用图标
            colors = true,
        }
    }
    wk.setup(opts)

    -- 等 VeryLazy 的配置执行完，再检查实际映射（包含 lazy 的快捷键占位）。
    -- 未绑定的字母直接吞掉，避免 which-key 回放后触发 m / Flash。
    vim.schedule(function()
        local prefix = (vim.g.mapleader or "\\") .. "m"
        local letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for _, mode in ipairs({ "n", "x" }) do
            local mappings = vim.api.nvim_get_keymap(mode)
            for letter in letters:gmatch(".") do
                local lhs = prefix .. letter
                local mapped = false
                for _, mapping in ipairs(mappings) do
                    local keys = vim.api.nvim_replace_termcodes(mapping.lhs, true, true, true)
                    if keys:sub(1, #lhs) == lhs then
                        mapped = true
                        break
                    end
                end
                if not mapped then
                    vim.keymap.set(mode, lhs, "<Nop>", {
                        silent = true,
                        desc = "which_key_ignore",
                    })
                    -- 显式覆盖已有的菜单描述（如 ma/mm），不显示任何兜底项。
                    wk.add({ { lhs, mode = mode, hidden = true } })
                end
            end
        end
    end)
end

return M
