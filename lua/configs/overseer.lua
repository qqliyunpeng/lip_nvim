local M = {}
local map = vim.keymap.set

function M.overseerConfig()
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
        templates = {
            "user.c_build", "user.cpp_build",
            "cargo", "user.run_python", "user.run_script",
            "user.make_clean", "user.make_run", "user.make_or160_pc", "user.make_or160_machine",
        },
        dap = false,
        task_list = {
            bindings = {
                ["<C-u>"] = false,
                ["<C-d>"] = false,
                ["<C-h>"] = false,
                ["<C-j>"] = false,
                ["<C-k>"] = false,
                ["<C-l>"] = false,
            },
        },
    })

    overseer.add_template_hook({
        module = "make",
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

