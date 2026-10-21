-- Run: nvim --headless -u NONE -l lua/tests/catppuccin_highlight_spec.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local normal = { fg = 0xcdd6f4, bg = 0x1e1e2e }
local inactive = { fg = 0xcdd6f4, bg = 0x1e1e2e }
vim.api.nvim_set_hl(0, "Normal", normal)
vim.api.nvim_set_hl(0, "NormalNC", inactive)

local theme = require("configs.theme.catppuccin")
for _ = 1, 2 do
    theme.apply()
    local active = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    assert(active.bg == 0, "the active window must have a black background")
    assert(active.fg == normal.fg, "the theme foreground must be preserved")
    assert(vim.deep_equal(vim.api.nvim_get_hl(0, { name = "NormalNC", link = false }), inactive),
        "inactive windows must keep the theme background")
end

print("catppuccin_highlight_spec: ok")
