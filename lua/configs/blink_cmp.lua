
local M = {}
local use_ascii_icons = require("configs.icons").use_ascii_icons()

local ascii_icons = {
    Text = "[T]",
    Method = "[M]",
    Function = "[F]",
    Constructor = "[C]",

    Field = "[Fd]",
    Variable = "[V]",
    Property = "[P]",

    Class = "[Cl]",
    Interface = "[I]",
    Struct = "[S]",
    Module = "[Mo]",

    Unit = "[U]",
    Value = "[Val]",
    Enum = "[E]",
    EnumMember = "[Em]",

    Keyword = "[K]",
    Constant = "[Co]",

    Snippet = "[Snip]",
    Color = "[Col]",
    File = "[File]",
    Reference = "[Ref]",
    Folder = "[Dir]",
    Event = "[Evt]",
    Operator = "[Op]",
    TypeParameter = "[Ty]",
}

M.blinkConfig = function()
    local cmp = require("blink.cmp")

    cmp.setup({
        keymap = {
            preset = 'default',
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ["<Tab>"]   = { 'select_next', 'snippet_forward' , 'fallback' },
            ["<S-Tab>"] = { 'select_prev', 'snippet_backward', 'fallback' },
            ['<CR>']  = { 'accept', 'fallback' },
            ['<C-e>'] = { 'cancel' }, -- or {}
            ["<C-b>"] = false,
            ["<C-f>"] = false,
            ["<Down>"] = false,
            ["<Up>"]  = false,
            ["<C-n>"] = false,
            ["<C-p>"] = false,
            ["<C-h>"] = false,
        },
        appearance = {
            nerd_font_variant = 'mono',
            kind_icons = use_ascii_icons and ascii_icons or {},
        },
        cmdline = {
            keymap = {
                preset = 'cmdline',
                ['<C-j>'] = { 'select_next', 'fallback' },
                ['<C-k>'] = { 'select_prev', 'fallback' },
                -- ['<CR>']  = { 'show_and_insert', 'fallback' },
            },
            completion = {
                menu = { auto_show  = true },
                list = {
                    selection = { preselect = false, auto_insert = true },
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
            sorts = {
                'score',      -- Primary sort: by fuzzy matching score
                'sort_text',  -- Secondary sort: by sortText field if scores are equal
                'label',      -- Tertiary sort: by label if still tied
            }
        },
    })
end

return M

