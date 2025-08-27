local M = {}
local map = vim.keymap.set

M.overseerConfig = function()
    local overseer = require("overseer")
    overseer.setup({
        cmd = {
            "OverseerOpen",
            "OverseerClose",
            "OverseerToggle",
            "OverseerSaveBundle",
            "OverseerLoadBundle",
            "OverseerDeleteBundle",
            "OverseerRunCmd",
            "OverseerRun",
            "OverseerInfo",
            "OverseerBuild",
            "OverseerQuickAction",
            "OverseerTaskAction",
            "OverseerClearCache",
        },
        opts = {
            dap = false,
            templates = { "make", "cargo", "shell", "user.run_python", "user.run_script" },
            task_list = {
                direction = "left",
                bindings = {
                    ["<C-u>"] = false,
                    ["<C-d>"] = false,
                    ["<C-h>"] = false,
                    ["<C-j>"] = false,
                    ["<C-k>"] = false,
                    ["<C-l>"] = false,
                },
            },
            -- form = {
            --     win_opts = {
            --         winblend = 0,
            --     },
            -- },
            -- confirm = {
            --     win_opts = {
            --         winblend = 0,
            --     },
            -- },
            -- task_win = {
            --     win_opts = {
            --         winblend = 0,
            --     },
            -- },
        },
    })

    overseer.add_template_hook({
        module = "^make$",
    }, function (task_defn, util)
        util.add_component(task_defn, { "on_output_quickfix", open_on_exit = "failure" })
        util.add_component(task_defn, "on_complete_notify")
        util.add_component(task_defn, { "display_duration", detail_level = 1 })
    end)

    map("n", "<leader>ow", "<cmd>OverseerToggle<cr>",      {desc = "Task list" })
    map("n", "<leader>oo", "<cmd>OverseerRun<cr>",         {desc = "Run task" })
    map("n", "<leader>oq", "<cmd>OverseerQuickAction<cr>", {desc = "Action recent task" })
    map("n", "<leader>oi", "<cmd>OverseerInfo<cr>",        {desc = "Overseer Info" })
    map("n", "<leader>ob", "<cmd>OverseerBuild<cr>",       {desc = "Task builder" })
    map("n", "<leader>ot", "<cmd>OverseerTaskAction<cr>",  {desc = "Task action" })
    map("n", "<leader>oc", "<cmd>OverseerClearCache<cr>",  {desc = "Clear cache" })
end

return M

