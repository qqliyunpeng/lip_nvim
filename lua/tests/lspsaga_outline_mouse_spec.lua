-- Run: nvim --headless -u NONE -l lua/tests/lspsaga_outline_mouse_spec.lua
local api = vim.api
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/lazy/lspsaga.nvim"))
require("lspsaga").setup({
    lightbulb = { enable = false },
    symbol_in_winbar = { enable = false },
    beacon = { enable = false },
    outline = {
        auto_preview = false,
        keys = { jump = { "e", "<2-LeftMouse>" } },
    },
})

local source = api.nvim_get_current_buf()
local editor = api.nvim_get_current_win()
api.nvim_buf_set_lines(source, 0, -1, false, { "first()", "", "code", "second()" })
require("lspsaga.symbol.head")[source] = {
    symbols = {
        {
            name = "first",
            kind = 12,
            range = { start = { line = 0, character = 0 }, ["end"] = { line = 2, character = 4 } },
            selectionRange = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 5 } },
        },
        {
            name = "second",
            kind = 12,
            range = { start = { line = 3, character = 0 }, ["end"] = { line = 3, character = 7 } },
            selectionRange = { start = { line = 3, character = 0 }, ["end"] = { line = 3, character = 6 } },
        },
    },
}

local outline = require("lspsaga.symbol.outline")
outline:outline()
api.nvim_set_current_win(outline.winid)
api.nvim_win_set_cursor(outline.winid, { 2, 4 })
local double_click = vim.fn.maparg("<2-LeftMouse>", "n", false, true)
assert(type(double_click.callback) == "function", "outline must create a double-click jump mapping")
double_click.callback()
assert(api.nvim_get_current_win() == editor and api.nvim_win_get_cursor(editor)[1] == 4,
    "double-clicking an outline symbol must jump to its source definition")
print("PASS: Lspsaga outline double-click jumps to source")
vim.cmd("qa!")
