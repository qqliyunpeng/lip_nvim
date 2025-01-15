
local M = {}

M.miniSurroundConfig = function ()
    require'mini.surround'.setup({
        mappings = {
            add = '<leader>sa',
            delete = '<leader>sd',
            replace = '<leader>sc',
            find = '<leader>sf',
            find_left = '<leader>sF',
            highlight = '<leader>sh',
            update_n_lines = '<leader>sn',

            suffix_last = 'l',
            suffix_next = 'n',
        }
    })
end

M.yankKeys = {
    { "<leader>y", function() require("telescope").extensions.yank_history.yank_history({ }) end, desc = "Open Yank History" },
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after cursor" },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before cursor" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after selection" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before selection" },
    { "<c-p>", "<Plug>(YankyPreviousEntry)", desc = "Select previous entry through yank history" },
    -- { "<c-n>", "<Plug>(YankyNextEntry)", desc = "Select next entry through yank history" },
    { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
    { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
    { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
    { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
    { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and indent right" },
    { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and indent left" },
    { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put before and indent right" },
    { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put before and indent left" },
    { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put after applying a filter" },
    { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put before applying a filter" },
}

M.yankConfig = function ()
    local utils = require("yanky.utils")
    local mapping = require("yanky.telescope.mapping")

    require('yanky').setup({
        ring = {
            history_length = 20,
            storage = "shada",
        },
        highlight = {
            on_put = true,
            on_yank = true,
            timer = 150,
        },
        preserve_cursor_position = {
            enabled = true,
        },
        textobj = {
            enable = true,
        },
        picker = {
            telescope = {
                use_default_mappings = false,
                mappings = {
                    default = mapping.put("p"),
                    i = {
                        ["<c-p>"] = mapping.put("p"),
                        ["<c-P>"] = mapping.put("P"),
                        ["<c-x>"] = mapping.delete(),
                        ["<c-r>"] = mapping.set_register(utils.get_default_register()),
                    },
                    n = {
                        p = mapping.put("p"),
                        P = mapping.put("P"),
                        x = mapping.delete(),
                        r = mapping.set_register(utils.get_default_register())
                    },
                }
            }
        },
    })

    vim.cmd([[
    hi! link YankyPut    Cursearch
    hi! link YankyYanked Cursearch
    ]])

    vim.keymap.set({ "o", "x" }, "lp", function()
        require("yanky.textobj").last_put()
    end, {desc = 'Last yank put'})
end

return M

