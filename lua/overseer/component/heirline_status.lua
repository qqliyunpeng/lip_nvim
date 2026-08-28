local flash_id = 0

local function set_status(status)
    vim.g.overseer_heirline_status = status
    vim.cmd("redrawstatus")
end

local function has_running_task()
    local overseer = require("overseer")
    for _, task in ipairs(overseer.list_tasks()) do
        if task.status == overseer.STATUS.RUNNING then
            return true
        end
    end
    return false
end

return {
    desc = "Change the Heirline background while a task runs and after it completes",
    constructor = function()
        return {
            on_start = function()
                flash_id = flash_id + 1
                set_status("running")
            end,
            on_complete = function(_, _, status)
                local overseer = require("overseer")
                if status ~= overseer.STATUS.SUCCESS and status ~= overseer.STATUS.FAILURE then
                    set_status(has_running_task() and "running" or nil)
                    return
                end
                flash_id = flash_id + 1
                local current_flash = flash_id
                set_status(status == overseer.STATUS.SUCCESS and "success" or "failure")
                vim.defer_fn(function()
                    if current_flash ~= flash_id then
                        return
                    end
                    set_status(has_running_task() and "running" or nil)
                end, 5000)
            end,
        }
    end,
}
