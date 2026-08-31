local M = {}

function M.overseerConfig()
    local overseer = require("overseer")
    overseer.setup({
        templates = {
            "user.c_build", "user.cpp_build",
            "cargo", "user.run_python", "user.run_script",
            "user.make_clean", "user.make_run",
            "user.make_or160_pc", "user.make_or160_machine",
            "user.make_aq300_pc", "user.make_aq300_machine",
            "user.make_aq300_r5",
        },
        component_aliases = {
            default = {
                { "display_duration", detail_level = 2 },
                "on_output_summarize",
                "on_exit_set_status",
                "on_complete_notify",
                "heirline_status",
                { "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } },
            },
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

end

return M

