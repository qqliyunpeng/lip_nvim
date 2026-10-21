-- Snacks Explorer（picker 侧栏）的唯一控制入口：
-- F2 切换 / quit-sidebars 关闭 / avante 刷新判断都走这里，
-- 保证「explorer 是否打开、如何打开关闭」只有一个实现。
local M = {}

local function get_explorer_pickers()
    local ok, Picker = pcall(require, "snacks.picker")
    if not ok then
        return {}
    end
    local ok_get, pickers = pcall(Picker.get, { source = "explorer" })
    if not ok_get then
        return {}
    end
    return pickers or {}
end

-- 仅在窗口导航从外部返回 Explorer 时聚焦列表；主动进入搜索框不受影响。
function M.focus_list_on_return(previous_win)
    local current_win = vim.api.nvim_get_current_win()
    if current_win == previous_win then
        return
    end
    for _, picker in ipairs(get_explorer_pickers()) do
        local function contains(win)
            if picker.layout.root.win == win then
                return true
            end
            for _, picker_win in pairs(picker.layout.wins) do
                if picker_win.win == win then
                    return true
                end
            end
            return false
        end
        if contains(current_win) and not contains(previous_win) then
            picker:focus("list")
            return
        end
    end
end

function M.is_open()
    return #get_explorer_pickers() > 0
end

function M.close()
    for _, picker in ipairs(get_explorer_pickers()) do
        pcall(function()
            picker:close()
        end)
    end
end

function M.open()
    local ok, snacks = pcall(require, "snacks")
    if ok then
        pcall(function()
            snacks.explorer()
        end)
    end
end

function M.toggle()
    if M.is_open() then
        M.close()
    else
        M.open()
    end
end

return M
