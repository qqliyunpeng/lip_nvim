local M = {}
local map = vim.keymap.set
local use_ascii_icons = require("configs.icons").use_ascii_icons()

local nerd_signs = {
    delete       = { text = "󰍵" },
    changedelete = { text = "󱕖" },
}

function M.config()
    local opts = {
        current_line_blame = true, -- 默认启用当前行 blame
        signs = use_ascii_icons and {} or nerd_signs,
    }

    require('gitsigns').setup(opts)

    map('n', ']g', ':Gitsigns next_hunk<CR>', { desc = "next git changes", noremap = true, silent = true })
    map('n', '[g', ':Gitsigns prev_hunk<CR>', { desc = "prev git changes", noremap = true, silent = true })
    map('n', '<leader>gp', ':Gitsigns preview_hunk<CR>', { desc = "preview git change", noremap = true, silent = true })
end

return M

