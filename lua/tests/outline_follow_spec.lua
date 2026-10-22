-- Run: nvim --headless -u NONE -l lua/tests/outline_follow_spec.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/lazy/lspsaga.nvim"))
local api = vim.api
require("lspsaga").setup({
    lightbulb = { enable = false },
    symbol_in_winbar = { enable = false },
    beacon = { enable = false },
    outline = { auto_preview = false },
})
require("configs.outline_follow").setup()
local source, editor = api.nvim_get_current_buf(), api.nvim_get_current_win()
local original_highlights = "CursorLine:CursorLine,NormalNC:NormalNC"
vim.wo[editor].winhighlight = original_highlights
api.nvim_buf_set_lines(source, 0, -1, false, vim.fn["repeat"]({ "    code" }, 40))
local function symbol(name, first, last)
    return { name = name, kind = 12,
        range = { start = { line = first, character = 0 }, ["end"] = { line = last, character = 8 } },
        selectionRange = { start = { line = first, character = 0 }, ["end"] = { line = first, character = #name } },
    }
end
local symbols = { symbol("first", 0, 10), symbol("second", 20, 30) }
require("lspsaga.symbol.head")[source] = { symbols = symbols }
local outline = require("lspsaga.symbol.outline")
outline:outline()
vim.wait(20)
api.nvim_set_current_win(editor)
local function check(row, expected)
    api.nvim_win_set_cursor(editor, { row, 0 })
    api.nvim_exec_autocmds("CursorMoved", { buffer = source })
    assert(api.nvim_win_get_cursor(outline.winid)[1] == expected,
        "outline did not follow source row " .. row .. ": " .. vim.inspect(api.nvim_win_get_cursor(outline.winid)))
    assert(api.nvim_get_current_win() == editor, "focus stolen")
end
check(5, 1)
check(25, 2)
-- Moving up into the gap must not leave the outline on the second function.
check(16, 1)
-- The plugin appends refreshed nodes to its existing linked list.
api.nvim_exec_autocmds("User", { pattern = "SagaSymbolUpdate", data = { bufnr = source, symbols = symbols } })
vim.wait(20)
check(5, 1)
check(25, 2)
vim.api.nvim_set_hl(0, "Normal", { bg = 0 })
vim.api.nvim_set_hl(0, "NormalNC", { bg = 0x222222 })
api.nvim_exec_autocmds("WinEnter", {})
vim.wait(20)
local mappings = vim.wo[outline.winid].winhighlight
assert(mappings:find("Normal:SagaOutlineNormal", 1, true), "outline must use its black background: " .. mappings)
assert(mappings:find("NormalNC:SagaOutlineNormal", 1, true), "inactive outline must use its black background: " .. mappings)
assert(api.nvim_get_hl(0, {}).SagaOutlineNormal.bg == 0, "outline background must be black")
api.nvim_set_current_win(outline.winid)
vim.wait(20)
assert(vim.wo[editor].winhighlight:find("NormalNC:SagaOutlineNormal", 1, true),
    "source editor must remain black while outline has focus")
assert(vim.wo[editor].winhighlight:find("CursorLine:CursorLine", 1, true),
    "unrelated source highlight mappings must survive: " .. vim.wo[editor].winhighlight)
vim.cmd("vnew")
local unrelated = api.nvim_get_current_win()
vim.bo.buftype = "nofile"
vim.wait(20)
assert(vim.wo[editor].winhighlight == original_highlights, "leaving the group must restore source highlights")
local function assert_inactive_outline(label)
    local winhl = vim.wo[outline.winid].winhighlight
    assert(winhl:find("Normal:NormalNC", 1, true), label .. ": outline Normal must use the inactive background: " .. winhl)
    assert(winhl:find("NormalNC:NormalNC", 1, true), label .. ": outline NormalNC must use the inactive background: " .. winhl)
    assert(vim.wo[editor].winhighlight == original_highlights, label .. ": editor must also be inactive")
end
assert_inactive_outline("unrelated window")
api.nvim_win_close(unrelated, true)
vim.fn.setqflist({ { bufnr = source, lnum = 1, text = "outline highlight test" } })
vim.cmd("copen")
vim.wait(20)
assert_inactive_outline("Quickfix")
vim.cmd("cclose")
-- Real Snacks Explorer uses a root split plus floating picker windows.
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/snacks.nvim")
vim.o.columns = 120
vim.o.lines = 40
require("snacks").setup({ explorer = { enabled = true }, picker = { enabled = true } })
Snacks.explorer({ cwd = vim.fn.getcwd() })
assert(vim.wait(2000, function()
    local pickers = require("snacks.picker").get({ source = "explorer" })
    return pickers[1] and pickers[1].list.win:valid()
end), "Explorer must open")
local picker = require("snacks.picker").get({ source = "explorer" })[1]
picker:focus("list")
vim.wait(100)
assert_inactive_outline("Explorer list")
picker:focus("input")
vim.wait(100)
assert_inactive_outline("Explorer input")
require("configs.explorer").close({ wait = true })
api.nvim_set_current_win(editor)
vim.wait(20)
assert(vim.wo[outline.winid].winhighlight:find("NormalNC:SagaOutlineNormal", 1, true),
    "returning to editor must reactivate outline background")
assert(vim.wo[outline.winid].cursorline, "current symbol stripe must remain visible")
api.nvim_set_hl(0, "SagaOutlineNormal", { bg = 0xffffff })
api.nvim_exec_autocmds("ColorScheme", {})
assert(api.nvim_get_hl(0, {}).SagaOutlineNormal.bg == 0, "theme changes must restore black")
check(25, 2)
api.nvim_win_close(outline.winid, true)
vim.wait(20)
assert(vim.wo[editor].winhighlight == original_highlights, "closing outline must restore source highlights")
api.nvim_exec_autocmds("CursorMoved", { buffer = source })
assert(not outline.preview_winid, "preview must stay disabled")
print("PASS: real Lspsaga outline follows across functions and refreshes, keeps focus and black background")
vim.cmd("qa!")
