-- Run: nvim --headless -u NONE -l lua/tests/edgy_resize_spec.lua
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/edgy.nvim")
vim.o.columns = 160
vim.o.lines = 50
vim.o.laststatus = 3
vim.o.splitkeep = "screen"
vim.o.winwidth = 1

local cfg = require("configs.edgy")
require("edgy").setup(cfg.opts())
local layout = require("edgy.layout")
local main = vim.api.nvim_get_current_win()

local function eq(actual, expected, label)
    assert(actual == expected, ("%s: expected %s, got %s"):format(label, expected, actual))
end

local function open_avante()
    vim.api.nvim_set_current_win(main)
    vim.cmd("topleft vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.cmd("enew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.filetype = "Avante"
    layout.update()
    vim.wait(100)
    return win
end

local function mapping(key)
    return vim.fn.maparg(key, "n", false, true).callback
end

local win = open_avante()
local default = math.floor(vim.o.columns * cfg.avante_width)
eq(vim.api.nvim_win_get_width(win), default, "default width")
vim.api.nvim_set_current_win(main)
mapping("<C-S-Right>")()
eq(vim.api.nvim_win_get_width(win), default + 2, "keyboard works from editor")
mapping("<C-S-Left>")()
eq(vim.api.nvim_win_get_width(win), default, "keyboard shrinks")

-- Exercise real edgy layout with the same callbacks used by native mouse input.
local getmousepos = vim.fn.getmousepos
vim.fn.getmousepos = function()
    return { screencol = vim.api.nvim_win_get_position(win)[2] + vim.api.nvim_win_get_width(win) + 1 }
end
mapping("<LeftMouse>")()
mapping("<LeftDrag>")()
vim.api.nvim_win_set_width(win, default + 12)
local dragged_width = vim.api.nvim_win_get_width(win)
layout.update()
eq(vim.api.nvim_win_get_width(win), dragged_width, "edgy does not fight dragging")
mapping("<LeftRelease>")()
vim.wait(100)
eq(vim.api.nvim_win_get_width(win), dragged_width, "release retains temporary width")
layout.update()
eq(vim.api.nvim_win_get_width(win), dragged_width, "later layout retains width")
vim.fn.getmousepos = getmousepos

eq(cfg.avante_width, 0.4, "default ratio is unchanged")
vim.api.nvim_win_close(win, true)
eq(vim.t.lip_avante_width, nil, "closing clears temporary width")
win = open_avante()
eq(vim.api.nvim_win_get_width(win), default, "reopening restores default")

-- edgy closes windows with autocommands disabled; stale width must still expire.
mapping("<C-S-Right>")()
vim.cmd("noautocmd call nvim_win_close(" .. win .. ", v:true)")
win = open_avante()
eq(vim.api.nvim_win_get_width(win), default, "edgy noautocmd close also restores default")
assert(type(vim.fn.maparg("<C-S-Right>", "i", false, true).callback) == "function", "insert mapping exists")

vim.cmd("tabnew")
eq(vim.t.lip_avante_width, nil, "tabs do not share temporary width")
mapping("<C-S-Right>")()
eq(vim.t.lip_avante_width, nil, "no Avante means no resize")
vim.cmd("tabclose")

-- Ordinary text clicks must not pause edgy or capture a custom width.
vim.fn.getmousepos = function() return { screencol = 2 } end
mapping("<LeftMouse>")()
mapping("<LeftDrag>")()
assert(not cfg._mouse_resizing, "text selection does not pause edgy")
mapping("<LeftRelease>")()
vim.wait(100)
eq(vim.t.lip_avante_width, nil, "text selection does not change temporary width")
vim.fn.getmousepos = getmousepos
print("edgy_resize_spec: ok")
vim.cmd("qa!")
