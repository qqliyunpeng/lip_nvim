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

    local gs = require("gitsigns")
    gs.setup(opts)

    map('n', ']g', ':Gitsigns next_hunk<CR>',    { desc = "Next Git changes",   noremap = true, silent = true })
    map('n', '[g', ':Gitsigns prev_hunk<CR>',    { desc = "Prev Git changes",   noremap = true, silent = true })
    map('n', 'gp', ':Gitsigns preview_hunk<CR>', { desc = "Preview Git change", noremap = true, silent = true })
    map('n', '<leader>gr', ':Gitsigns reset_hunk<CR>',   { desc = "Reset Git hunk"        , noremap = true, silent = true })
    map('n', '<leader>gR', ':Gitsigns reset_buffer<CR>', { desc = "Reset Git buffer"      , noremap = true, silent = true })
    map('n', '<leader>gs', ':Gitsigns stage_hunk<CR>',   { desc = "Stage/Un Git hunk", noremap = true, silent = true })
    map('n', '<leader>gS', ':Gitsigns stage_buffer<CR>', { desc = "Stage Git buffer"      , noremap = true, silent = true })
    map('n', '<leader>gd', function()
        local found = false

        -- 遍历窗口，检查是否存在 gitsigns:// buffer
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local name = vim.api.nvim_buf_get_name(buf)
            if name:match("^gitsigns://") then
                -- 找到 diff buffer -> 关闭它
                vim.api.nvim_buf_delete(buf, { force = true })
                vim.cmd("diffoff!")  -- 关闭 diff 模式，防止游标乱跑
                found = true
                break
            end
        end
        -- 如果没有 diff buffer -> 打开 diff
        if not found then
            gs.diffthis()
            local line_count = vim.api.nvim_buf_line_count(0)
            if line_count > 2000 then
                vim.cmd("normal! zR")  -- 展开所有折叠
            end

            vim.cmd("wincmd H")
            vim.cmd("wincmd l")
            vim.cmd("wincmd h")
        end
    end, {desc = "Diff Git vsplit" })
end

return M

