-- Run: nvim --headless -u NONE -l lua/tests/outline_quit_spec.lua
local scenario = vim.env.LIP_OUTLINE_QUIT_SCENARIO
local script = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
local root = vim.fn.fnamemodify(script, ":h:h:h")
if not scenario then
    for _, name in ipairs({ "last_file", "split", "other_tab", "modified", "quickfix", "outline_only" }) do
        local result = vim.system({ vim.v.progpath, "--headless", "-u", "NONE", "-i", "NONE",
            "-c", "lua dofile(" .. vim.fn.string(script) .. ")",
        }, { text = true, env = { LIP_OUTLINE_QUIT_SCENARIO = name } }):wait(10000)
        assert(result.code == 0, name .. ": " .. (result.stderr or "") .. (result.stdout or ""))
        assert((result.stderr .. result.stdout):find("READY " .. name, 1, true), "scenario never reached :q")
    end
    print("outline_quit_spec: ok")
    vim.cmd("qa!")
    return
end
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/lspsaga.nvim")
vim.opt.swapfile = false
vim.opt.hidden = false
require("lspsaga").setup({ lightbulb = { enable = false }, symbol_in_winbar = { enable = false },
    beacon = { enable = false }, outline = { auto_preview = false } })
require("configs.outline_follow").setup()
local api = vim.api
local editor, buf = api.nvim_get_current_win(), api.nvim_get_current_buf()
api.nvim_buf_set_name(buf, "/tmp/outline-quit-source")
api.nvim_buf_set_lines(buf, 0, -1, false, { "function first()", "end" })
vim.bo[buf].modified = false
local range = { start = { line = 0, character = 0 }, ["end"] = { line = 1, character = 3 } }
require("lspsaga.symbol.head")[buf] = { symbols = {
    { name = "first", kind = 12, range = range, selectionRange = range },
} }
if scenario == "split" then
    vim.cmd("vsplit")
elseif scenario == "other_tab" then
    vim.cmd("tabnew /tmp/outline-quit-other-tab")
    vim.cmd("tabfirst")
end
local outline = require("lspsaga.symbol.outline")
outline:outline()
local outline_win = outline.winid
vim.wait(20)
api.nvim_set_current_win(editor)
if scenario == "modified" then
    vim.bo[buf].modified = true
elseif scenario == "quickfix" then
    vim.fn.setqflist({ { bufnr = buf, lnum = 1, text = "test" } })
    vim.cmd("copen")
elseif scenario == "outline_only" then
    api.nvim_set_current_win(outline_win)
end
print("READY " .. scenario)
local ok, err = pcall(vim.cmd, "quit")
assert(scenario ~= "last_file", "last file quit must exit Neovim, not leave outline")
if scenario == "modified" then
    assert(not ok and tostring(err):find("E37", 1, true), "unsaved file must reject :q")
    assert(api.nvim_win_is_valid(outline_win), "unsaved file must preserve outline")
elseif scenario == "split" or scenario == "quickfix" then
    assert(ok, tostring(err))
    assert(api.nvim_win_is_valid(outline_win), "remaining editor must preserve outline")
elseif scenario == "outline_only" then
    assert(ok, tostring(err))
    assert(api.nvim_win_is_valid(editor), "closing outline must preserve editor")
    assert(not api.nvim_win_is_valid(outline_win), "outline must close")
else
    assert(ok, tostring(err))
    assert(#api.nvim_list_tabpages() == 1, "other tab must survive")
    assert(not api.nvim_win_is_valid(outline_win), "closed tab must not leave outline")
end
vim.cmd("qa!")
