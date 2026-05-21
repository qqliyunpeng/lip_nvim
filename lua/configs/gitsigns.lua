local M = {}
local map = vim.keymap.set
local use_ascii_icons = require("configs.icons").use_ascii_icons()
local overlay_ns = vim.api.nvim_create_namespace("gitsigns_full_overlay")
local overlay_refresh_seq = {}

local nerd_signs = {
    delete       = { text = "󰍵" },
    changedelete = { text = "󱕖" },
}

local function clear_overlay_marks(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, overlay_ns, 0, -1)
end

local function clear_overlay(bufnr)
    overlay_refresh_seq[bufnr] = (overlay_refresh_seq[bufnr] or 0) + 1
    clear_overlay_marks(bufnr)
    vim.b[bufnr].gitsigns_full_overlay = false
end

local function overlay_row(hunk, line_count)
    if hunk.added.start == 0 and hunk.type == "delete" then
        return 0, true
    end

    local row = math.max(hunk.added.start - 1, 0)
    return math.min(row, math.max(line_count - 1, 0)), hunk.type ~= "delete"
end

local function clear_hunk_overlay(bufnr, hunk)
    if not hunk then
        return
    end

    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local start_row
    local end_row

    if hunk.added.count > 0 then
        start_row = hunk.added.start - 1
        end_row = hunk.added.start - 1 + hunk.added.count
    end

    if hunk.removed.count > 0 then
        local row = overlay_row(hunk, line_count)
        start_row = math.min(start_row or row, row)
        end_row = math.max(end_row or (row + 1), row + 1)
    end

    if not start_row or not end_row then
        return
    end

    start_row = math.max(start_row, 0)
    end_row = math.min(math.max(end_row, start_row + 1), line_count)
    vim.api.nvim_buf_clear_namespace(bufnr, overlay_ns, start_row, end_row)
end

local function render_overlay_diff(bufnr, notify_empty, keep_open)
    local hunks = require("gitsigns").get_hunks(bufnr) or {}
    local line_count = vim.api.nvim_buf_line_count(bufnr)

    clear_overlay_marks(bufnr)

    if #hunks == 0 then
        if notify_empty then
            vim.notify("No git changes", vim.log.levels.INFO, { title = "Gitsigns" })
        end
        vim.b[bufnr].gitsigns_full_overlay = keep_open or false
        return
    end

    for _, hunk in ipairs(hunks) do
        for offset = 0, hunk.added.count - 1 do
            local row = hunk.added.start - 1 + offset
            if row >= 0 and row < line_count then
                vim.api.nvim_buf_set_extmark(bufnr, overlay_ns, row, 0, {
                    end_row = row + 1,
                    hl_group = "GitSignsAddPreview",
                    hl_eol = true,
                    priority = 1000,
                })
            end
        end

        if hunk.removed.count > 0 then
            local virt_lines = {}

            for _, line in ipairs(hunk.removed.lines or {}) do
                local padding = string.rep(" ", math.max(300 - #line, 0))
                virt_lines[#virt_lines + 1] = {
                    { line, "GitSignsDeleteVirtLn" },
                    { padding, "GitSignsDeleteVirtLn" },
                }
            end

            local row, above = overlay_row(hunk, line_count)
            vim.api.nvim_buf_set_extmark(bufnr, overlay_ns, row, 0, {
                virt_lines = virt_lines,
                virt_lines_above = above,
                priority = 1000,
            })
        end
    end

    vim.b[bufnr].gitsigns_full_overlay = true
end

local function show_overlay_diff()
    local bufnr = vim.api.nvim_get_current_buf()

    if vim.b[bufnr].gitsigns_full_overlay then
        clear_overlay(bufnr)
        return
    end

    render_overlay_diff(bufnr, true, false)
end

local function refresh_overlay_diff(bufnr, cursor, keep_open)
    if not keep_open or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    overlay_refresh_seq[bufnr] = (overlay_refresh_seq[bufnr] or 0) + 1
    local refresh_seq = overlay_refresh_seq[bufnr]

    vim.b[bufnr].gitsigns_full_overlay = true

    local refreshed = false

    local function redraw()
        if refreshed
            or not vim.api.nvim_buf_is_valid(bufnr)
            or overlay_refresh_seq[bufnr] ~= refresh_seq
        then
            return
        end

        refreshed = true

        if cursor and vim.api.nvim_get_current_buf() == bufnr then
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            pcall(vim.api.nvim_win_set_cursor, 0, { math.min(cursor[1], line_count), cursor[2] })
        end

        vim.api.nvim_buf_call(bufnr, function()
            render_overlay_diff(bufnr, false, true)
        end)
    end

    local autocmd
    autocmd = vim.api.nvim_create_autocmd("User", {
        pattern = "GitSignsUpdate",
        callback = function(args)
            if args.data and args.data.buffer ~= bufnr then
                return
            end

            if autocmd then
                pcall(vim.api.nvim_del_autocmd, autocmd)
            end

            redraw()
        end,
    })

    local ok, gs = pcall(require, "gitsigns")
    if ok then
        pcall(gs.refresh)
    end

    vim.defer_fn(function()
        if autocmd then
            pcall(vim.api.nvim_del_autocmd, autocmd)
            autocmd = nil
        end

        redraw()
    end, 200)
end

local function in_gitsigns_diff()
    if not vim.wo.diff then
        return false
    end

    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match("^gitsigns://") then
            return true
        end
    end

    return false
end

local function hunk_under_cursor(hunks)
    local lnum = vim.api.nvim_win_get_cursor(0)[1]

    for _, hunk in ipairs(hunks or {}) do
        if lnum == 1 and hunk.added.start == 0 and hunk.added.count == 0 then
            return hunk
        end

        local hunk_start = math.max(hunk.added.start, 1)
        local hunk_end = math.max(hunk_start, hunk.added.start + hunk.added.count - 1)

        if lnum >= hunk_start and lnum <= hunk_end then
            return hunk
        end
    end
end

local function do_reset_hunk()
    local bufnr = vim.api.nvim_get_current_buf()
    local overlay_enabled = vim.b[bufnr].gitsigns_full_overlay
    local cursor = vim.api.nvim_win_get_cursor(0)

    if in_gitsigns_diff() then
        local hunk = hunk_under_cursor(require("gitsigns").get_hunks(bufnr))
        if overlay_enabled then
            clear_hunk_overlay(bufnr, hunk)
        end

        require("gitsigns").reset_hunk(nil, { greedy = false })
        vim.b[bufnr].gitsigns_full_overlay = overlay_enabled
        return
    end

    if not overlay_enabled then
        vim.notify("do is only available in diff or git overlay", vim.log.levels.WARN, { title = "Gitsigns" })
        return
    end

    local hunk = hunk_under_cursor(require("gitsigns").get_hunks(bufnr))

    if not hunk then
        vim.notify("No hunk under cursor", vim.log.levels.WARN, { title = "Gitsigns" })
        return
    end

    clear_hunk_overlay(bufnr, hunk)
    vim.api.nvim_win_set_cursor(0, { math.max(hunk.added.start, 1), 0 })
    require("gitsigns").reset_hunk(nil, { greedy = false })

    vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() == bufnr then
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            pcall(vim.api.nvim_win_set_cursor, 0, { math.min(cursor[1], line_count), cursor[2] })
        end
    end, 20)
end

local function undo_with_overlay_refresh()
    local bufnr = vim.api.nvim_get_current_buf()
    local overlay_enabled = vim.b[bufnr].gitsigns_full_overlay

    vim.cmd("normal! " .. vim.v.count1 .. "u")

    refresh_overlay_diff(bufnr, nil, overlay_enabled)
end

local function redo_with_overlay_refresh()
    local bufnr = vim.api.nvim_get_current_buf()
    local overlay_enabled = vim.b[bufnr].gitsigns_full_overlay

    vim.cmd("normal! " .. vim.v.count1 .. "\018")

    refresh_overlay_diff(bufnr, nil, overlay_enabled)
end

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
    map('n', 'do', do_reset_hunk,                { desc = "Reset Git hunk",     noremap = true, silent = true })
    map('n', 'u', undo_with_overlay_refresh,     { desc = "Undo",               noremap = true, silent = true })
    map('n', '<C-r>', redo_with_overlay_refresh, { desc = "Redo",               noremap = true, silent = true })
    map('n', '<leader>gp', show_overlay_diff,            { desc = "Toggle Git diff overlay", noremap = true, silent = true })
    map('n', '<leader>gr', ':Gitsigns reset_hunk<CR>',   { desc = "Reset Git hunk",          noremap = true, silent = true })
    map('n', '<leader>gR', ':Gitsigns reset_buffer<CR>', { desc = "Reset Git buffer",        noremap = true, silent = true })
    map('n', '<leader>gs', ':Gitsigns stage_hunk<CR>',   { desc = "Stage/Un Git hunk",       noremap = true, silent = true })
    map('n', '<leader>gS', ':Gitsigns stage_buffer<CR>', { desc = "Stage Git buffer",        noremap = true, silent = true })
    map('n', '<leader>gd', function()
        local found = false

        -- 遍历窗口，检查是否存在 gitsigns:// buffer
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local name = vim.api.nvim_buf_get_name(buf)
            if name:match("^gitsigns://") then
                -- 找到 diff buffer -> 关闭它
                vim.api.nvim_buf_delete(buf, { force = true })
                vim.cmd("diffoff!") -- 关闭 diff 模式，防止游标乱跑

                -- After leaving diff mode, Neovim may restore fold options in a way that
                -- makes folds appear closed (and ufo can then take over the fold UI).
                -- We explicitly restore the expected "no folding" window state here.
                vim.wo.foldenable = false
                vim.wo.foldlevel = 99

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

