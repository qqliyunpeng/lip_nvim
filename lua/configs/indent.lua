local M = {}

function M.miniIndentInit()
    require('mini.indentscope').setup({
        symbol = '▎',
        -- symbol = "▏",
        options = { try_as_border = true },
        draw = { animation = require("mini.indentscope").gen_animation.none() },
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = {
            "Trouble",
            "alpha",
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
            "toggleterm",
            "trouble",
        },
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
            char = "▎",
            tab_char = "▎",
            -- char = "▏",
            -- tab_char = "▏",
        },
        scope = { enabled = false, show_start = false, show_end = false },
    }
end

return M

