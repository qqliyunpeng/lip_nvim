local M = {}

M.miniIndentInit = function()
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

M.blanklineConfig = function()
    Snacks.toggle({
        name = "Indention Guides",
        get = function()
            return require("ibl.config").get_config(0).enabled
        end,
        set = function(state)
            require("ibl").setup_buffer(0, { enabled = state })
        end,
    }):map("<leader>ug")

    return {
        indent = {
            char = "▎",
            tab_char = "▎",
        },
        scope = { enabled = false, show_start = false, show_end = false },
    }
end

return M

