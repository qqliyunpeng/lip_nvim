local M = {}

M.opts = {
    -- 输入框前缀图标，与 snacks picker 保持一致（./icons.lua 中按终端自动 nerd/ascii）
    prompt = require('configs.icons').snacksIcons().prompt,
    wrap_around = true,
    layout = {
        width = 0.85,
        height = 0.74,
        prompt_position = 'top',
        preview_position = 'right',
        preview_size = 0.57,
        border = 'rounded',
    },
    keymaps = {
        -- <C-c> 关闭 picker：插入模式、普通模式（含 list/preview 窗口）都生效
        close = { '<Esc>', '<C-c>' },
        select_split = '<C-x>',
        move_up = { '<Up>', '<C-k>' },
        move_down = { '<Down>', '<C-j>' },
    },
    -- 沿用 snacks picker 的配色（见 init.lua 中 SnacksPicker* 的链接）
    hl = {
        normal = 'SnacksPicker',
        border = 'SnacksPickerBorder',
        title = 'FFFPicerTitle',
        matched = 'SnacksPickerMatch',
        cursor = 'SnacksPickerListCursorLine',
        directory_path = 'SnacksPickerDir',
        frecency = 'SnacksPickerTotals',
        scrollbar = 'SnacksPickerDir',
    },
}

M.keys = {
    -- <leader>fz 与 <leader>ff/fw/fc 一样在 mappings.lua 中按 configs/picker.lua 的后端开关分发，这里不再注册
}

return M
