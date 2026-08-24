
local M = {}

M.options = {
    themable = false, -- allows highlight groups to be overriden i.e. sets highlights as default
    -- numbers = "ordinal",
    close_command = "bdelete! %d",       -- can be a string | function, | false see "Mouse actions"
    right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
    left_mouse_command = "buffer %d",    -- can be a string | function, | false see "Mouse actions"
    middle_mouse_command = nil,          -- can be a string | function, | false see "Mouse actions"
    show_buffer_icons = false,
    tab_size = 1,
    offsets = {
        {
            filetype = "NvimTree",
            text = "File Explorer",
            text_align = "center",
            separator = true,
        }
    },
    color_icons = true, -- whether or not to add the filetype icon highlights
}

M.highlights = {
    buffer_selected = {
        fg = '#1e1e2e',
        bg = '#89B4FA',
        bold = true,
        italic = false,
    },
    numbers_selected = {
        fg = '#1e1e2e',
        bg = '#89B4FA',
        bold = true,
        italic = false,
    },
    close_button_selected = { fg = '#1e1e2e', bg = '#89B4FA' },
    indicator_selected = { fg = '#1e1e2e', bg = '#89B4FA' },
    modified_selected = { fg = '#1e1e2e', bg = '#89B4FA' },
    separator_selected = { fg = '#89B4FA', bg = '#89B4FA' },
}

return M
