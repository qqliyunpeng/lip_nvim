-- Run: nvim --headless -u NONE -l lua/tests/quickfix_highlight_spec.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local lazy = vim.fn.stdpath("data") .. "/lazy/"
vim.opt.runtimepath:prepend(lazy .. "edgy.nvim")
vim.opt.runtimepath:prepend(lazy .. "catppuccin")
vim.o.columns = 160
vim.o.lines = 50
vim.o.laststatus = 3

require("catppuccin").setup({ flavour = "mocha" })
require("configs.theme").setup({ default = "catppuccin" })
require("edgy").setup(require("configs.edgy").opts())
local editor = vim.api.nvim_get_current_win()
vim.fn.setqflist({ { filename = "/tmp/quickfix-highlight", lnum = 1, text = "test" } })
vim.cmd("copen")
local quickfix = vim.api.nvim_get_current_win()
require("edgy.layout").update()
vim.wait(100)

local function background(win, source)
    local target = source
    for mapping in vim.wo[win].winhighlight:gmatch("[^,]+") do
        local from, to = mapping:match("^([^:]+):(.+)$")
        if from == source then target = to end
    end
    return vim.api.nvim_get_hl(0, { name = target, link = false }).bg
end

assert(vim.api.nvim_get_current_win() == quickfix, "quickfix must have focus")
assert(background(quickfix, "Normal") == 0, "focused quickfix must have a black background")
vim.api.nvim_set_current_win(editor)
vim.wait(100)
assert(background(quickfix, "NormalNC") == 0x1e1e2e, "inactive quickfix must keep the theme background")
vim.api.nvim_set_current_win(quickfix)
vim.wait(100)
assert(background(quickfix, "Normal") == 0, "quickfix must turn black again on re-entry")
print("quickfix_highlight_spec: ok")
