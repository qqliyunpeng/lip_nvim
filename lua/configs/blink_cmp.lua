
local M = {}

M.blinkConfig = function()
    local cmp = require("blink.cmp")
    cmp.setup({
        keymap = {
            preset = 'default',
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ['<CR>']  = { 'accept', 'fallback' },
            ['<C-e>'] = false, -- or {}
        },
        appearance = {
            nerd_font_variant = 'mono'
        },
        completion = {
            ghost_text = {  -- 虚拟文本
                enabled = true,
                -- Show the ghost text when an item has been selected
                show_with_selection = true,
                -- Show the ghost text when no item has been selected, defaulting to the first item
                show_without_selection = false,
                -- Show the ghost text when the menu is open
                show_with_menu = true,
                -- Show the ghost text when the menu is closed
                show_without_menu = true,
            },
            menu = {
                enabled = true,
                -- min_width = 5,
                max_width = 10, -- 不起作用, 可能需要设置截断
                max_height = 15,
                border = "rounded",
                winblend = 0,
                -- winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
            },
            documentation = {
                auto_show = true,
                window = {
                    min_width = 10,
                    max_width = 80,
                    max_height = 20,
                    border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                    -- winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
                }
            }
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

