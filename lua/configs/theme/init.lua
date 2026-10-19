-- 主题调度器：颜色方案本身由 :colorscheme 负责，这里只负责
--   1) 记录上次用的主题（stdpath("state")/colorscheme）
--   2) 每次主题变化后，套用该主题专属的 hi 覆盖（configs.theme.<name>）
local M = {}

---兜底默认主题。实际以 init.lua 传进来的 default 为准，一般不用改这里
M.default = "onedark"

---是否记住 :colorscheme 的切换结果并盖过 default（默认关：以 init.lua 为准）
M.remember = false

---记录文件
M.state_file = vim.fn.stdpath("state") .. "/colorscheme"

---主题名前缀 -> 覆盖模块
---前缀匹配：onedarkpro 提供的 onedark / onedark_dark / onedark_vivid 都会命中 onedark
---长前缀优先，所以 catppuccin / catppuccin-mocha 也能各自挂模块
---@type table<string, string>
M.overrides = {
    onedark = "configs.theme.onedark",
    catppuccin = "configs.theme.catppuccin",
}

---当前主题名（:colorscheme 设置后由 nvim 写入 g:colors_name）
---@return string
function M.current()
    return vim.g.colors_name or ""
end

---@param name string
---@return string? mod
local function pick_override(name)
    local best, mod
    for prefix, path in pairs(M.overrides) do
        if name:sub(1, #prefix) == prefix and (not best or #prefix > #best) then
            best, mod = prefix, path
        end
    end
    return mod
end

---套用当前主题的专属高亮覆盖（幂等，可反复调用）
function M.apply()
    local name = M.current()
    if name == "" then
        return
    end

    local mod = pick_override(name)
    if not mod then
        return
    end

    local ok, theme = pcall(require, mod)
    if not ok then
        vim.notify(("lip: 主题覆盖模块加载失败 %s: %s"):format(mod, theme), vim.log.levels.WARN)
        return
    end
    if type(theme) ~= "table" or type(theme.apply) ~= "function" then
        vim.notify(("lip: %s 缺少 apply()"):format(mod), vim.log.levels.WARN)
        return
    end

    local applied, err = pcall(theme.apply)
    if not applied then
        vim.notify(("lip: %s 高亮覆盖出错: %s"):format(mod, err), vim.log.levels.ERROR)
    end
end

---snacks 的 colorschemes picker 预览时会不停 :colorscheme，
---此时不记录，避免把「只是看了一眼」的主题写进状态文件
---@return boolean
local function previewing()
    local ok, picker = pcall(require, "snacks.picker.core.picker")
    if not ok then
        return false
    end
    local ok2, pickers = pcall(picker.get, { tab = false })
    if not ok2 then
        return false
    end
    for _, p in ipairs(pickers) do
        if p.opts.preview == "colorscheme" or p.opts.source == "colorschemes" then
            return true
        end
    end
    return false
end

function M.save()
    local name = M.current()
    if not M.remember or name == "" or previewing() then
        return
    end
    local ok, err = pcall(vim.fn.writefile, { name }, M.state_file)
    if not ok then
        vim.notify(("lip: 记录主题失败 %s: %s"):format(M.state_file, err), vim.log.levels.WARN)
    end
end

---@return string
function M.load()
    if not M.remember then
        return M.default
    end
    local ok, lines = pcall(vim.fn.readfile, M.state_file)
    if ok and type(lines) == "table" then
        local name = vim.trim(lines[1] or "")
        if name ~= "" then
            return name
        end
    end
    return M.default
end

---@param opts? {default?: string, remember?: boolean, overrides?: table<string, string>}
---@return string name
function M.setup(opts)
    opts = opts or {}
    M.default = opts.default or M.default
    M.remember = opts.remember == true
    for prefix, path in pairs(opts.overrides or {}) do
        M.overrides[prefix] = path
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("LipThemeOverrides", { clear = true }),
        callback = function()
            M.apply()
            M.save()
        end,
    })

    -- 启动：默认由 init.lua 指定（remember=true 时才优先用上次记录的主题）
    local name = M.load()
    local ok, err = pcall(vim.cmd.colorscheme, name)
    if not ok then
        vim.notify(("lip: 主题 %s 加载失败(%s)，回退到 %s"):format(name, err, M.default), vim.log.levels.WARN)
        vim.cmd.colorscheme(M.default)
    end
    return M.current()
end

return M
