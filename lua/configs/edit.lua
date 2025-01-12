
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

return M

