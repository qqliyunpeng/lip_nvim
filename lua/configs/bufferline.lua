
local M = {}

-- Avante 相关的临时 buffer 不显示在 bufferline 中。
local avante_filetypes = {
    Avante = true,
    AvanteInput = true,
    AvantePromptInput = true,
    AvanteSelectedFiles = true,
    AvanteTodos = true,
}

function M.keep_current_buffer_in_avante()
    local Buffer = require("bufferline.models").Buffer
    -- 防止配置重复加载时重复包装 Buffer:current。
    if Buffer._lip_original_current then
        return
    end

    -- 记录进入 Avante 前最后一个普通文件 buffer。
    local last_file_buffer
    local current_buffer = vim.api.nvim_get_current_buf()
    if not avante_filetypes[vim.bo[current_buffer].filetype] then
        last_file_buffer = current_buffer
    end

    vim.api.nvim_create_autocmd("BufLeave", {
        group = vim.api.nvim_create_augroup("lip_bufferline_avante", { clear = true }),
        callback = function(args)
            -- 离开普通文件时更新记录，Avante buffer 不参与记录。
            if not avante_filetypes[vim.bo[args.buf].filetype] then
                last_file_buffer = args.buf
            end
        end,
    })

    Buffer._lip_original_current = Buffer.current
    function Buffer:current()
        -- 当前位于 Avante 时，让 bufferline 继续使用之前的普通文件作为当前元素，
        -- 从而保持原有高亮和左右折叠位置。
        if avante_filetypes[vim.bo.filetype] and last_file_buffer then
            return self.id == last_file_buffer
        end
        return Buffer._lip_original_current(self)
    end
end

M.options = {
    themable = false, -- allows highlight groups to be overriden i.e. sets highlights as default
    -- numbers = "ordinal",
    close_command = "bdelete! %d",       -- can be a string | function, | false see "Mouse actions"
    right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
    left_mouse_command = "buffer %d",    -- can be a string | function, | false see "Mouse actions"
    middle_mouse_command = nil,          -- can be a string | function, | false see "Mouse actions"
    show_buffer_icons = false,
    tab_size = 1,
    custom_filter = function(bufnr)
        return not avante_filetypes[vim.bo[bufnr].filetype]
    end,
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
    buffer_visible = {
        fg = '#1e1e2e',
        bg = '#89B4FA',
        bold = true,
        italic = false,
    },
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
    numbers_visible = {
        fg = '#1e1e2e',
        bg = '#89B4FA',
        bold = true,
        italic = false,
    },
    close_button_visible = { fg = '#1e1e2e', bg = '#89B4FA' },
    close_button_selected = { fg = '#1e1e2e', bg = '#89B4FA' },
    indicator_visible = { fg = '#1e1e2e', bg = '#89B4FA' },
    indicator_selected = { fg = '#89B4FA', bg = '#89B4FA' },
    modified_visible = { fg = '#1e1e2e', bg = '#89B4FA' },
    modified_selected = { fg = '#1e1e2e', bg = '#89B4FA' },
    separator_visible = { fg = '#89B4FA', bg = '#89B4FA' },
    separator_selected = { fg = '#89B4FA', bg = '#89B4FA' },
}

return M
