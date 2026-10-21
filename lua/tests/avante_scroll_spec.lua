-- Run: nvim --headless -u NONE -l lua/tests/avante_scroll_spec.lua
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

local follow_history = require("configs.ai")._test.follow_avante_history
assert(type(follow_history) == "function", "history-open scrolling helper is missing")

local function fixture()
    vim.cmd("enew")
    local buf = vim.api.nvim_get_current_buf()
    local lines = {}
    for i = 1, 300 do
        lines[i] = "History message " .. i
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local result_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(result_win, { 1, 0 })
    vim.cmd("vnew")
    local input_win = vim.api.nvim_get_current_win()
    local sidebar = { containers = { result = { winid = result_win, bufnr = buf } }, scroll = false }
    function sidebar:is_open()
        return vim.api.nvim_win_is_valid(result_win)
    end
    return sidebar, result_win, input_win, buf
end

local sidebar, result_win, input_win = fixture()
follow_history(sidebar)
assert(vim.api.nvim_win_get_cursor(result_win)[1] == 1, "scroll must wait for layout")
assert(vim.wait(1000, function()
    return vim.api.nvim_win_get_cursor(result_win)[1] == 300
end), "opening history must scroll to its last line")
assert(sidebar.scroll, "opening history must restore automatic following")
assert(vim.api.nvim_get_current_win() == input_win, "scrolling must not steal input focus")
local bottom = vim.api.nvim_win_call(result_win, function()
    return vim.fn.line("w$")
end)
assert(bottom == 300, "latest message must be visible")

-- The deferred callback must not touch a closed/replaced result window.
sidebar, result_win, input_win = fixture()
follow_history(sidebar)
vim.api.nvim_win_close(result_win, true)
vim.wait(50, function() return false end)
assert(not sidebar.scroll, "closing before layout finishes must cancel following")

local buf
sidebar, result_win, input_win, buf = fixture()
follow_history(sidebar)
local replacement = vim.api.nvim_create_buf(false, true)
vim.api.nvim_win_set_buf(result_win, replacement)
vim.wait(50, function() return false end)
assert(not sidebar.scroll, "replacing the result buffer must cancel following")
assert(vim.api.nvim_buf_line_count(buf) == 300, "history contents must stay unchanged")

print("avante_scroll_spec: ok")
