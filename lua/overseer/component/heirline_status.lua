local flash_id = 0
local animation_timer
local animation_frame = 1
local animation_colors = { "#6F6029", "#8F7A32", "#AF943D", "#CFAD49", "#EEC956", "#FFE786", "#EEC956", "#CFAD49" }

local function update_animation_highlights()
    for index = 1, 8 do
        local color = animation_colors[(index - animation_frame) % #animation_colors + 1]
        vim.api.nvim_set_hl(0, "OverseerBuilding" .. index, { fg = color })
    end
end

local function stop_animation()
    if animation_timer then
        animation_timer:stop()
        animation_timer:close()
        animation_timer = nil
    end
    vim.g.overseer_heirline_frame = nil
end

local function start_animation()
    stop_animation()
    animation_frame = 1
    vim.g.overseer_heirline_frame = animation_frame
    update_animation_highlights()
    animation_timer = vim.uv.new_timer()
    animation_timer:start(80, 80, vim.schedule_wrap(function()
        if vim.g.overseer_heirline_status ~= "running" then
            stop_animation()
            return
        end
        animation_frame = animation_frame % #animation_colors + 1
        vim.g.overseer_heirline_frame = animation_frame
        update_animation_highlights()
        vim.cmd("redrawstatus")
    end))
end

local function set_status(status)
    vim.g.overseer_heirline_status = status
    if status == "running" then
        start_animation()
    else
        stop_animation()
    end
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
