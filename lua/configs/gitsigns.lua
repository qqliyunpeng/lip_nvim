
local map = vim.keymap.set

local M = {}

M.config = function ()
    local opts = {
        signs = {
            delete = { text = "󰍵"},
            changedelete = { text = "󱕖" },
        },
    }

    require('gitsigns').setup(opts)

    map('n', ']g', ':Gitsigns next_hunk<CR>', { desc = "next git changes", noremap = true, silent = true })
    map('n', '[g', ':Gitsigns prev_hunk<CR>', { desc = "prev git changes", noremap = true, silent = true })
end

return M

