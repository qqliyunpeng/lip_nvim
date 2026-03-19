local M = {}
local use_ascii_icons = require("configs.icons").use_ascii_icons()

local indentscopeDisableFileType = {
    "Trouble",
    "alpha",
    "Avante",
    "AvanteInput",
    "dashboard",
    "fzf",
    "help",
    "lazy",
    "mason",
    "neo-tree",
    "NvimTree",
    "cmp_menu",
    "noice",
    "notify",
    "snacks_dashboard",
    "snacks_notif",
    "snacks_terminal",
    "snacks_win",
    "*snacks_picker_preview",
    "toggleterm",
    "trouble",
}

local function disable_miniindentscope_for_buf(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local ft = vim.bo[buf].filetype
    if ft ~= nil and ft ~= "" and vim.tbl_contains(indentscopeDisableFileType, ft) then
        vim.b[buf].miniindentscope_disable = true
    end
end

function M.miniIndentInit()
    require('mini.indentscope').setup({
        symbol = use_ascii_icons and "▎" or "▏",
        options = { try_as_border = true },
        draw = {
            delay = 50,
            animation = require("mini.indentscope").gen_animation.none()
        },
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = indentscopeDisableFileType,
        callback = function()
            vim.b.miniindentscope_disable = true
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "SnacksDashboardOpened",
        callback = function(data)
            vim.b[data.buf].miniindentscope_disable = true
        end,
    })

    disable_miniindentscope_for_buf(vim.api.nvim_get_current_buf())
end

function M.blanklineConfig()
    Snacks.toggle({
        -- name = "Indention Guides",
        name = "|",
        get = function()
            return require("ibl.config").get_config(0).enabled
        end,
        set = function(state)
            require("ibl").setup_buffer(0, { enabled = state })
        end,
    }):map("<leader>ub")

    return {
        indent = {
            char = use_ascii_icons and "▎" or"▏",
            tab_char = use_ascii_icons and "▎" or"▏",
        },
        scope = { enabled = false, show_start = false, show_end = false },
    }
end

return M

