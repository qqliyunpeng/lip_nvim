-- Run: nvim --headless -u NONE -l lua/tests/quit_sidebars_spec.lua
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

local close_count = 0
local explorer_open = false
package.preload["configs.explorer"] = function()
    return {
        is_open = function()
            return explorer_open
        end,
        close = function()
            close_count = close_count + 1
            explorer_open = false
        end,
    }
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

explorer_open = true
eq(quit_pre(), 1, "last named file closes explorer")

vim.api.nvim_buf_set_name(file_buf, "")
eq(ai._test.count_file_windows(), 1, "unnamed normal buffer counts as an editing window")
explorer_open = true
eq(quit_pre(), 1, "last unnamed buffer closes explorer")
vim.api.nvim_buf_set_name(file_buf, "/tmp/quit-sidebars-file")

vim.cmd("tabnew /tmp/quit-sidebars-other-tab")
local other_tab = vim.api.nvim_get_current_tabpage()
vim.cmd("tabfirst")
eq(ai._test.count_file_windows(), 1, "other-tab file does not count")
explorer_open = true
eq(quit_pre(), 1, "other-tab file does not prevent closing current explorer")

vim.cmd("vsplit")
local split_win = vim.api.nvim_get_current_win()
eq(ai._test.count_file_windows(), 2, "splits of the same buffer count separately")
explorer_open = true
eq(quit_pre(), 0, "multiple editing windows preserve explorer")
vim.api.nvim_win_close(split_win, true)
vim.api.nvim_set_current_win(file_win)

local float_buf = vim.api.nvim_create_buf(false, true)
vim.bo[float_buf].buftype = ""
local float_win = vim.api.nvim_open_win(float_buf, false, {
    relative = "editor", row = 1, col = 1, width = 10, height = 2,
})
eq(ai._test.count_file_windows(), 1, "normal buffers in floating windows do not count")
explorer_open = true
eq(quit_pre(), 1, "floating window does not prevent closing explorer")
vim.api.nvim_win_close(float_win, true)

vim.bo[file_buf].modified = true
eq(quit_pre(), 0, "unsaved changes preserve explorer")
vim.bo[file_buf].modified = false

vim.cmd("split")
local terminal_win = vim.api.nvim_get_current_win()
local terminal_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_win_set_buf(terminal_win, terminal_buf)
vim.bo[terminal_buf].filetype = "snacks_terminal"
vim.fn.termopen({ "sh", "-c", "exec sleep 60" })
vim.api.nvim_set_current_win(file_win)
vim.bo[file_buf].modified = true
quit_pre()
assert(vim.api.nvim_win_is_valid(terminal_win), "unsaved file preserves terminal")
vim.bo[file_buf].modified = false
quit_pre()
assert(not vim.api.nvim_win_is_valid(terminal_win), "last file closes snacks terminal window")
vim.api.nvim_buf_delete(terminal_buf, { force = true })

explorer_open = false
eq(quit_pre(), 0, "nothing to close when explorer is closed")

print("quit_sidebars_spec: ok")
vim.cmd("qa!")
