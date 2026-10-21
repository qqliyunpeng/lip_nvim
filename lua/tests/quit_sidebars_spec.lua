-- Run: nvim --headless -u NONE -l lua/tests/quit_sidebars_spec.lua
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

local close_count = 0
package.preload["nvim-tree.api"] = function()
    return { tree = { close = function() close_count = close_count + 1 end } }
end

local ai = require("configs.ai")
ai.setup_quit_sidebars()
ai.setup_quit_sidebars()
assert(#vim.api.nvim_get_autocmds({ event = "QuitPre" }) == 1, "QuitPre registration must be idempotent")

local function eq(actual, expected, label)
    assert(actual == expected, string.format("%s: expected %s, got %s", label, expected, actual))
end

local function quit_pre()
    close_count = 0
    vim.api.nvim_exec_autocmds("QuitPre", {})
    return close_count
end

local file_win = vim.api.nvim_get_current_win()
local file_buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(file_buf, "/tmp/quit-sidebars-file")
vim.cmd("vsplit")
vim.cmd("enew")
local tree_win = vim.api.nvim_get_current_win()
vim.bo.buftype = "nofile"
vim.bo.filetype = "NvimTree"
vim.api.nvim_set_current_win(file_win)
eq(quit_pre(), 1, "last named file closes tree")

vim.api.nvim_buf_set_name(file_buf, "")
eq(ai._test.count_file_windows(), 1, "unnamed normal buffer counts as an editing window")
eq(quit_pre(), 1, "last unnamed buffer closes tree")

vim.cmd("tabnew /tmp/quit-sidebars-other-tab")
local other_tab = vim.api.nvim_get_current_tabpage()
vim.cmd("tabfirst")
eq(ai._test.count_file_windows(), 1, "other-tab file does not count")
eq(quit_pre(), 1, "other-tab file does not prevent closing current tree")

vim.cmd("vsplit")
local split_win = vim.api.nvim_get_current_win()
eq(ai._test.count_file_windows(), 2, "splits of the same buffer count separately")
eq(quit_pre(), 0, "multiple editing windows preserve tree")
vim.api.nvim_win_close(split_win, true)
vim.api.nvim_set_current_win(file_win)

local float_buf = vim.api.nvim_create_buf(false, true)
vim.bo[float_buf].buftype = ""
local float_win = vim.api.nvim_open_win(float_buf, false, {
    relative = "editor", row = 1, col = 1, width = 10, height = 2,
})
eq(ai._test.count_file_windows(), 1, "normal buffers in floating windows do not count")
eq(quit_pre(), 1, "floating window does not prevent closing tree")
vim.api.nvim_win_close(float_win, true)

vim.bo[file_buf].modified = true
eq(quit_pre(), 0, "unsaved changes preserve tree")
vim.bo[file_buf].modified = false

vim.api.nvim_win_close(tree_win, true)
vim.api.nvim_set_current_tabpage(other_tab)
vim.cmd("vsplit")
vim.cmd("enew")
vim.bo.buftype = "nofile"
vim.bo.filetype = "NvimTree"
vim.cmd("tabfirst")
eq(quit_pre(), 0, "tree in another tab must not trigger current-tab cleanup")

print("quit_sidebars_spec: ok")
vim.cmd("qa!")
