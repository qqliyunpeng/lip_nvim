-- Run: nvim --headless -u NONE -l lua/tests/explorer_focus_spec.lua
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

local file_win = vim.api.nvim_get_current_win()
local function float()
    return vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
        relative = "editor", row = 1, col = 1, width = 20, height = 2,
    })
end
local root_win, input_win, list_win, other_win = float(), float(), float(), float()
local focus_count = 0
local picker = {
    layout = {
        root = { win = root_win },
        wins = { input = { win = input_win }, list = { win = list_win } },
    },
    focus = function(_, name)
        assert(name == "list", "return must focus the list")
        focus_count = focus_count + 1
        vim.api.nvim_set_current_win(list_win)
    end,
}
local pickers = { picker }
package.preload["snacks.picker"] = function()
    return { get = function(opts)
        assert(opts.source == "explorer", "must only inspect explorers")
        return pickers
    end }
end

local target = input_win
package.preload["smart-splits"] = function()
    return { move_cursor_left = function()
        vim.api.nvim_set_current_win(target)
    end }
end
package.preload["configs.picker"] = function()
    local noop = function() end
    return { fuzzy_grep = noop, find_files = noop, live_grep = noop, grep_word = noop }
end
require("mappings")
local explorer = require("configs.explorer")
local function eq(actual, expected, message)
    assert(actual == expected, message)
end
local function navigate(mode, from, to)
    vim.api.nvim_set_current_win(from)
    target = to
    local mapping = vim.fn.maparg("<C-h>", mode, false, true)
    assert(type(mapping.callback) == "function", "Ctrl-h must have a callback")
    mapping.callback()
end

for _, mode in ipairs({ "n", "t" }) do
    for _, destination in ipairs({ input_win, root_win, list_win }) do
        navigate(mode, file_win, destination)
        eq(vim.api.nvim_get_current_win(), list_win, "external return must land on list")
    end
end

navigate("n", list_win, input_win)
eq(vim.api.nvim_get_current_win(), input_win, "internal navigation must preserve search focus")
navigate("n", file_win, other_win)
eq(vim.api.nvim_get_current_win(), other_win, "unrelated windows must be unaffected")

local before = focus_count
navigate("n", input_win, input_win)
eq(focus_count, before, "failed navigation must not steal focus")
vim.api.nvim_set_current_win(input_win)
eq(vim.api.nvim_get_current_win(), input_win, "direct search entry must remain available")

pickers = {}
explorer.focus_list_on_return(file_win)
eq(focus_count, before, "closed explorer must be a no-op")
package.loaded["snacks.picker"] = nil
package.preload["snacks.picker"] = function() error("plugin unavailable") end
explorer.focus_list_on_return(file_win)
eq(focus_count, before, "unavailable plugin must be a no-op")

print("explorer_focus_spec: ok")
vim.cmd("qa!")
