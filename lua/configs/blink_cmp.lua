
local M = {}

M.blinkConfig = function()
    local cmp = require("blink.cmp")
    cmp.setup({
        keymap = {
            preset = 'default',
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ['<C-e>'] = false, -- or {}
        },
        appearance = {
            nerd_font_variant = 'mono'
        },
        completion = { documentation = { auto_show = false } },
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

