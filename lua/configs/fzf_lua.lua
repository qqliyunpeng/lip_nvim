-- 参考 LazyVim 的 fzf-lua 外观；颜色由当前 colorscheme 提供。
local profile = vim.deepcopy(require('fzf-lua.profiles.default-title'))

local function picker_windows()
    local picker = require('fzf-lua.utils').fzf_winobj()
    if not picker then
        return {}
    end

    local windows = {}
    for _, win in ipairs({ picker.fzf_winid, picker.preview_winid }) do
        if win and vim.api.nvim_win_is_valid(win) then
            table.insert(windows, win)
        end
    end
    return windows
end

local function cycle_picker_window()
    local current = vim.api.nvim_get_current_win()
    local windows = picker_windows()
    if #windows < 2 then
        return
    end

    local target_index = 1
    for index, win in ipairs(windows) do
        if win == current then
            target_index = (index % #windows) + 1
            break
        end
    end

    vim.api.nvim_set_current_win(windows[target_index])
end

local function close_picker()
    local picker = require('fzf-lua.utils').fzf_winobj()
    if picker then
        picker:close()
    end
end

local function setup_picker_switch(bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    for _, mode in ipairs({ 'n', 't' }) do
        vim.keymap.set(mode, '<A-w>', cycle_picker_window, {
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
            desc = 'Cycle fzf-lua windows',
        })
    end
end

local function setup_normal_exit(bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    for _, key in ipairs({ 'q', '<C-c>' }) do
        vim.keymap.set('n', key, close_picker, {
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
            desc = 'Close fzf-lua',
        })
    end
end

local function move_fzf_selection(bufnr, key)
    local job = vim.b[bufnr].terminal_job_id
    if job then
        vim.fn.chansend(job, vim.api.nvim_replace_termcodes(key, true, false, true))
    end
end

local function setup_normal_list_navigation(bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    setup_picker_switch(bufnr)
    vim.keymap.set('n', 'j', function()
        move_fzf_selection(bufnr, '<C-j>')
    end, { buffer = bufnr, noremap = true, silent = true, nowait = true })
    vim.keymap.set('n', 'k', function()
        move_fzf_selection(bufnr, '<C-k>')
    end, { buffer = bufnr, noremap = true, silent = true, nowait = true })
end

local navigation_group = vim.api.nvim_create_augroup('LipFzfLuaNavigation', { clear = true })
vim.api.nvim_create_autocmd('WinEnter', {
    group = navigation_group,
    callback = function()
        local win = vim.api.nvim_get_current_win()
        if vim.w[win].fzf_lua_preview then
            local bufnr = vim.api.nvim_win_get_buf(win)
            setup_picker_switch(bufnr)
            setup_normal_exit(bufnr)
        end
    end,
})

-- LazyVim 为 default-title 的各个 picker 使用统一的提示符。
local function fix_prompt(opts)
    if opts.prompt ~= nil then
        opts.prompt = ' '
    end
    for _, value in pairs(opts) do
        if type(value) == 'table' then
            fix_prompt(value)
        end
    end
    return opts
end

return vim.tbl_deep_extend('force', fix_prompt(profile), {
    prompt = ' ',
    fzf_colors = true,
    fzf_opts = { ['--no-scrollbar'] = true },
    keymap = {
        fzf = {
            ['ctrl-h'] = 'backward-char',
            ['ctrl-l'] = 'forward-char',
            ['ctrl-j'] = 'down',
            ['ctrl-k'] = 'up',
        },
    },
    defaults = { formatter = 'path.dirname_first' },
    winopts = {
        width = 0.8,
        height = 0.8,
        row = 0.5,
        col = 0.5,
        -- fzf-lua 的主窗口是 terminal buffer。某些情况下回车打开文件后，
        -- Neovim 会把 terminal mode 状态带到新文件窗口；此时仅 redrawstatus
        -- 不够，必须先退出 terminal mode。
        on_close = function()
            vim.schedule(function()
                if vim.bo.buftype == 'terminal' or vim.fn.mode() ~= 't' then
                    vim.cmd('redrawstatus')
                    return
                end
                vim.api.nvim_feedkeys(
                    vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true),
                    'nx',
                    false
                )
                vim.cmd('redrawstatus')
            end)
        end,
        -- mappings.lua 为普通 terminal 设置了全局 C-j/C-k 分屏快捷键。
        -- fzf 的主窗口也是 terminal，必须在它自己的 buffer 中覆盖这两个键，
        -- 否则按键会被 Neovim 吃掉，无法到达 fzf 的 down/up action。
        on_create = function(event)
            if not event.bufnr then
                return
            end
            vim.keymap.set('t', '<C-j>', '<C-j>', {
                buffer = event.bufnr,
                noremap = true,
                silent = true,
                nowait = true,
            })
            vim.keymap.set('t', '<C-k>', '<C-k>', {
                buffer = event.bufnr,
                noremap = true,
                silent = true,
                nowait = true,
            })
            vim.keymap.set('t', '<C-h>', '<C-h>', {
                buffer = event.bufnr,
                noremap = true,
                silent = true,
                nowait = true,
            })
            vim.keymap.set('t', '<C-l>', '<C-l>', {
                buffer = event.bufnr,
                noremap = true,
                silent = true,
                nowait = true,
            })
            setup_normal_list_navigation(event.bufnr)
            setup_normal_exit(event.bufnr)
        end,
        preview = { scrollchars = { '┃', '' } },
    },
    files = { cwd_prompt = false },
})

