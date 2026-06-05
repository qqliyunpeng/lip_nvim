local M = {}

local function has_nvim_tree_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)

        if vim.bo[buf].filetype == "NvimTree" then
            return true
        end
    end

    return false
end

local function find_target_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        local listed = vim.api.nvim_get_option_value("buflisted", { buf = buf })

        if listed and vim.bo[buf].filetype ~= "NvimTree" and vim.bo[buf].buftype ~= "terminal" then
            return win
        end
    end
end

function M.refresh(opts)
    opts = opts or {}

    vim.defer_fn(function()
        if opts.require_tree_closed and has_nvim_tree_win() then
            return
        end

        local current_win = vim.api.nvim_get_current_win()
        local target_win = find_target_win()

        if not target_win then
            return
        end

        pcall(vim.api.nvim_set_current_win, target_win)

        local ok, avante_api = pcall(require, "avante.api")
        if ok then
            pcall(avante_api.refresh)
        end

        if vim.api.nvim_win_is_valid(current_win) then
            pcall(vim.api.nvim_set_current_win, current_win)
        end
    end, opts.delay or 80)
end

return M
