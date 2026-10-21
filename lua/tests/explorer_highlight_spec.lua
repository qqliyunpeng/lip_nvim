-- Run: nvim --headless -u NONE -l lua/tests/explorer_highlight_spec.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local lazy = vim.fn.stdpath("data") .. "/lazy/"
for _, plugin in ipairs({ "snacks.nvim", "catppuccin", "edgy.nvim" }) do
    vim.opt.runtimepath:prepend(lazy .. plugin)
end
vim.o.columns = 160
vim.o.lines = 50
vim.o.laststatus = 3
require("catppuccin").setup({ flavour = "mocha", integrations = { snacks = true } })
require("configs.theme").setup({ default = "catppuccin" })
require("configs.snacks").snacksConfig()
require("edgy").setup(require("configs.edgy").opts())
local editor = vim.api.nvim_get_current_win()
require("configs.explorer").open()
assert(vim.wait(3000, function()
    local pickers = require("snacks.picker").get({ source = "explorer" })
    return #pickers > 0 and pickers[1].list.win:valid()
end), "explorer must open")
local picker = require("snacks.picker").get({ source = "explorer" })[1]
local function background(win, source)
    local target = source
    for mapping in vim.wo[win].winhighlight:gmatch("[^,]+") do
        local from, to = mapping:match("^([^:]+):(.+)$")
        if from == source then target = to end
    end
    return vim.api.nvim_get_hl(0, { name = target, link = false }).bg
end
-- 模拟首次显示后由 UI/Edgy 触发的二次布局；不能还原旧的背景映射。
picker.layout:update()
vim.wait(100)
-- 不主动 focus，先验证首次打开后自然获得焦点的状态。
assert(vim.api.nvim_get_current_win() == picker.list.win.win, "opening must focus the list")
for _, source in ipairs({ "Normal", "NormalFloat", "NormalNC" }) do
    assert(background(picker.list.win.win, source) == 0, "first open must be black via " .. source)
end

for _, name in ipairs({ "list", "input", "list" }) do
    picker:focus(name)
    vim.wait(100)
    local win = picker[name].win.win
    assert(vim.api.nvim_get_current_win() == win, name .. " must have focus")
    for _, source in ipairs({ "Normal", "NormalFloat", "NormalNC" }) do
        assert(background(win, source) == 0,
            "focused explorer " .. name .. " must be black via " .. source .. ": " .. vim.wo[win].winhighlight)
    end
end
vim.api.nvim_set_current_win(editor)
vim.wait(100)
picker.layout:update()
assert(background(picker.list.win.win, "NormalNC") == 0x1e1e2e,
    "inactive explorer list must keep the theme background")
for _ = 1, 3 do
    picker:focus("list")
    vim.wait(100)
    picker.layout:update()
    assert(vim.api.nvim_get_hl(0, {}).LipExplorerActive.bg == 0,
        "returning to Explorer must not copy its inactive mapping into the active color")
    for _, source in ipairs({ "Normal", "NormalFloat", "NormalNC" }) do
        assert(background(picker.list.win.win, source) == 0, "returning to Explorer must restore black")
    end
    vim.api.nvim_set_current_win(editor)
    vim.wait(100)
    assert(background(picker.list.win.win, "NormalNC") == 0x1e1e2e,
        "leaving Explorer must restore the inactive background")
end
picker:close()
print("explorer_highlight_spec: ok")
