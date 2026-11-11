return {
    {
        require("lip.utils").ge("nvim_lip/diffview.nvim"),
        cmd = {
            "DiffviewOpen",
            "DiffviewClose",
            "DiffviewFileHistory",
            "DiffviewToggleFiles",
            "DiffviewFocusFiles",
            "DiffviewRefresh",
        },
        keys = {
            -- <leader>gd 留给现有的 Gitsigns 单文件 diff。
            { "<leader>gD", "<cmd>DiffviewOpen<cr>", desc = "Diffview: working tree changes" },
            { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: current file history" },
            { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: repository history" },
            { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
        },
        opts = {
            enhanced_diff_hl = true,
            view = {
                default = {
                    layout = "diff2_horizontal",
                    disable_diagnostics = true,
                },
                file_history = {
                    layout = "diff2_horizontal",
                    disable_diagnostics = true,
                },
            },
            file_panel = {
                listing_style = "tree",
                win_config = { position = "left", width = 35 },
            },
            keymaps = {
                view = {
                    { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
                    -- 不覆盖全局的 LSP code action 键位；冲突选择仍可用其他默认键。
                    { "n", "<leader>ca", false },
                },
                file_panel = {
                    { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
                },
                file_history_panel = {
                    { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
                },
            },
        },
    },
}

