
local M = {}

M.blinkConfig = function()
    local cmp = require("blink.cmp")

    cmp.setup({
        keymap = {
            preset = 'default',
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ['<Tab>'] = { 'select_next', 'fallback' },
            ['<S-Tab>'] = { 'select_prev', 'fallback' },
            -- ["<Tab>"]   = { "snippet_forward", "fallback" },
            -- ["<S-Tab>"] = { "snippet_backward", "fallback" },
            ['<CR>']  = { 'accept', 'fallback' },
            ['<C-e>'] = { 'cancel' }, -- or {}
        },
        appearance = {
            nerd_font_variant = 'mono'
        },
        cmdline = {
            keymap = {
                preset = 'cmdline',
                ['<C-j>'] = { 'select_next', 'fallback' },
                ['<C-k>'] = { 'select_prev', 'fallback' },
                -- ['<CR>']  = { 'show_and_insert', 'fallback' },
            },
            completion = {
                -- menu = { auto_show  = true },
                list = {
                    selection = { preselect = true, auto_insert = true },
                },
                ghost_text = {
                    enabled = true,
                },
            },
        },
        completion = {
            list = {
                selection = { preselect = false, auto_insert = true }, -- 不自动选择，自动插入
            },
            ghost_text = {  -- 虚拟文本
                enabled = true,
                -- Show the ghost text when an item has been selected
                show_with_selection = true,
                -- Show the ghost text when no item has been selected, defaulting to the first item
                show_without_selection = true,
                -- Show the ghost text when the menu is open
                show_with_menu = true,
                -- Show the ghost text when the menu is closed
                show_without_menu = true,
            },
            menu = {
                enabled = true,
                -- min_width = 5,
                max_height = 15,
                border = "rounded",
                winblend = 0,
            },
            documentation = {
                auto_show = true,
                window = {
                    min_width = 10,
                    max_width = 80,
                    max_height = 20,
                    border = "rounded",
                }
            },
        },
        snippets = { preset = 'luasnip' },
        sources = {
            default = { 'lsp', 'path', 'snippets', 'buffer' },
        },
        fuzzy = {
            prebuilt_binaries = {
                force_version = "v1.6.0",
            },
        },
    })
end

return M

