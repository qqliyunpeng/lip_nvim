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

-- Explorer 的根 split、搜索框和列表是一组窗口；浮动列表可能使用
-- NormalNC，即使它已有焦点。整组显式映射，避免只改 NormalFloat 漏掉实际底色。
function M.sync_highlights()
    local current = vim.api.nvim_get_current_win()
    -- 按名称读取单个组会受当前窗口的 winhighlight 影响，返回 Explorer 时
    -- 可能把 inactive 颜色读成 Normal；读取整张全局表避免映射污染。
    local highlights = vim.api.nvim_get_hl(0, {})
    local function resolve(name)
        local seen = {}
        while highlights[name] and highlights[name].link and not seen[name] do
            seen[name] = true
            name = highlights[name].link
        end
        return highlights[name] or {}
    end
    vim.api.nvim_set_hl(0, "LipExplorerActive", resolve("Normal"))
    vim.api.nvim_set_hl(0, "LipExplorerInactive", resolve("NormalNC"))
    for _, picker in ipairs(get_explorer_pickers()) do
        local wins = { picker.layout.root }
        for _, win in pairs(picker.layout.wins) do
            wins[#wins + 1] = win
        end
        local active = false
        for _, win in ipairs(wins) do
            if win.win == current then active = true end
        end
        local target = active and "LipExplorerActive" or "LipExplorerInactive"
        -- Layout 每次 resize 都会从 win_opts 还原子窗口选项。
        for _, saved in pairs(picker.layout.win_opts) do
            saved.wo = saved.wo or {}
            saved.wo.winhighlight = require("snacks").util.winhl(saved.wo.winhighlight, {
                Normal = target, NormalFloat = target, NormalNC = target,
            })
        end
        for _, win in ipairs(wins) do
            if win:valid() then
                local mappings = require("snacks").util.winhl(vim.wo[win.win].winhighlight, {
                    Normal = target,
                    NormalFloat = target,
                    NormalNC = target,
                })
                win.opts.wo.winhighlight = mappings
                require("snacks").util.wo(win.win, { winhighlight = mappings })
            end
        end
    end
end

function M.setup_highlights()
    local group = vim.api.nvim_create_augroup("LipExplorerHighlights", { clear = true })
    vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave", "BufWinEnter", "ColorScheme" }, {
        group = group,
        callback = function() vim.schedule(M.sync_highlights) end,
    })
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
