
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
    { "<leader>y", function() require('telescope').extensions.yank_history.yank_history({ }) end, desc = "Open Yank History" },
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
    -- { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after cursor" },
    -- { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before cursor" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after selection" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before selection" },
    -- 在已经粘贴的上边换成列表中之前的一个
    { "]y", "<Plug>(YankyPreviousEntry)", desc = "Select previous entry through yank history" },
    { "[y", "<Plug>(YankyNextEntry)", desc = "Select next entry through yank history" },
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
            history_length = 100,
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
            enable = false,
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
                        d = mapping.delete(),
                        r = mapping.set_register(utils.get_default_register()),
                    },
                }
            }
        },
    })

    vim.cmd([[
    hi! link YankyPut    Cursearch
    hi! link YankyYanked Cursearch
    ]])

    vim.keymap.set({ "i" }, "<C-y>", "<cmd>Telescope yank_history<CR>",
        {noremap = true, silent = true, desc = 'Yanky Picker in Insert Mode'})
end

M.nvimToggleConfig = function ()
    require('nvim-toggler').setup({
        inverses = {
            ['YES']    = 'NO',
            ['ON']     = 'OFF',
            ['UP']     = 'DOWN',
            ['LEFT']   = 'RIGHT',
            ['TRUE']   = 'FALSE',
            ['ENABLE'] = 'DISABLE',
            ['GET']    = 'SET',
            ['get']    = 'set',
            ['SHOW']   = 'HIDE',
            ['show']   = 'hide',
            ['top']    = 'bottom',
            ['TOP']    = 'BOTTOM',
        },
        -- removes the default <leader>i keymap
        remove_default_keybinds = true,
        -- auto-selects the longest match when there are multiple matches
        autoselect_longest_match = false
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>ui', require('nvim-toggler').toggle,
                                                    { desc = "True <-> False" })
end

M.visualMulConfig = function ()
    vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_start",
        callback = function ()
            vim.keymap.set("n", "<A-q>", "<cmd>call vm#reset()<CR>")
        end
    })
    vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_exit",
        callback = function ()
            vim.keymap.set("n", "<A-q>", "<Esc><cmd>noh<CR>")
        end
    })
end

M.ColorizerToggleDo = function ()
    local map = vim.keymap.set
    local is_open = require('colorizer').is_buffer_attached(0)

    if is_open then
        vim.cmd([[ColorizerToggle]])
        vim.notify("Disable colorizer", vim.log.levels.WARN)
        map("n", "<leader>uo", function() require("configs.edit").ColorizerToggleDo() end, { desc = "Enable colorizer" })
    else
        vim.cmd([[ColorizerToggle]])
        vim.notify("Enable colorizer")
        map("n", "<leader>uo", function() require("configs.edit").ColorizerToggleDo() end, { desc = "Disable colorizer" })
    end
end

M.pasteSmart = function ()
    local clipboard_content = vim.fn.getreg('"')
    local ends_with_newline = clipboard_content:sub(-1) == '\n'

    if clipboard_content == nil or not ends_with_newline then
        vim.cmd('execute "normal \\<Plug>(YankyPutAfter)"')
        return
    end

    if ends_with_newline then
        vim.cmd('execute "normal \\<Plug>(YankyPutAfterFilter)"')
    end
end

M.PasteSmart = function ()
    local clipboard_content = vim.fn.getreg('"')
    local ends_with_newline = clipboard_content:sub(-1) == '\n'

    if clipboard_content == nil or not ends_with_newline then
        vim.cmd('execute "normal \\<Plug>(YankyPutBefore)"')
        return
    end

    if ends_with_newline then
        vim.cmd('execute "normal \\<Plug>(YankyPutBeforeFilter)"')
    end
end

return M

