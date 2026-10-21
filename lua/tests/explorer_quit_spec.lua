-- Run: nvim --headless -u NONE -l lua/tests/explorer_quit_spec.lua
-- Integration test: real Snacks windows and a real :q in a child Neovim.
local scenario = vim.env.LIP_EXPLORER_QUIT_SCENARIO
local script = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
local root = vim.fn.fnamemodify(script, ":h:h:h")

if not scenario then
    for _, name in ipairs({ "last_file", "split", "other_tab", "modified", "modified_hidden", "quickfix" }) do
        local result = vim.system({
            vim.v.progpath, "--headless", "-u", "NONE", "-i", "NONE",
            "-c", "lua dofile(" .. vim.fn.string(script) .. ")",
        }, { text = true, env = { LIP_EXPLORER_QUIT_SCENARIO = name } }):wait(10000)
        assert(result.code == 0, name .. " failed:\n" .. (result.stderr or "") .. (result.stdout or ""))
        assert((result.stderr .. result.stdout):find("READY " .. name, 1, true), "child never reached :q: " .. name)
    end
    print("explorer_quit_spec: ok")
    vim.cmd("qa!")
    return
end

vim.opt.rtp:prepend(root)
local snacks_path = vim.env.SNACKS_NVIM_PATH or (vim.fn.stdpath("data") .. "/lazy/snacks.nvim")
assert(vim.fn.isdirectory(snacks_path) == 1, "real snacks.nvim required; set SNACKS_NVIM_PATH")
vim.opt.rtp:prepend(snacks_path)
vim.opt.swapfile = false
vim.o.columns = 120
vim.o.lines = 40
require("snacks").setup({ explorer = { enabled = true }, picker = { enabled = true } })
require("configs.ai").setup_quit_sidebars()
vim.cmd.edit(root .. "/init.lua")
local file_win = vim.api.nvim_get_current_win()
local file_buf = vim.api.nvim_get_current_buf()
if scenario == "split" then
    vim.cmd("vsplit")
elseif scenario == "other_tab" then
    vim.cmd.tabnew(root .. "/README.md")
    vim.cmd("tabfirst")
elseif scenario == "modified" or scenario == "modified_hidden" then
    vim.o.hidden = scenario == "modified_hidden"
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { "unsaved regression test change" })
end
Snacks.explorer({ cwd = root })

vim.defer_fn(function()
    local ok, err = pcall(function()
        local explorer = require("configs.explorer")
        assert(explorer.is_open(), "Explorer must be open before :q")
        vim.api.nvim_set_current_win(file_win)
        local quickfix_win
        if scenario == "quickfix" then
            vim.fn.setqflist({ { filename = root .. "/init.lua", lnum = 1, text = "TODO regression" } })
            vim.cmd("copen")
            quickfix_win = vim.api.nvim_get_current_win()
            assert(vim.bo.buftype == "quickfix", "quit must originate in Quickfix")
        end
        print("READY " .. scenario)
        local quit_ok, quit_err = pcall(vim.cmd, "quit")
        assert(scenario ~= "last_file", ":q returned without exiting the last file")
        if scenario == "quickfix" then
            assert(quit_ok, tostring(quit_err))
            assert(not vim.api.nvim_win_is_valid(quickfix_win), "Quickfix must close")
            assert(vim.api.nvim_win_is_valid(file_win), "closing Quickfix must preserve the file window")
            assert(explorer.is_open(), "closing Quickfix must preserve Explorer")
        elseif scenario == "modified" then
            assert(not quit_ok and tostring(quit_err):find("E37", 1, true), "modified file must reject :q: " .. tostring(quit_ok) .. " / " .. tostring(quit_err))
            assert(explorer.is_open(), "modified file must preserve Explorer")
            assert(vim.api.nvim_win_is_valid(file_win), "modified file must remain open")
        else
            assert(quit_ok, tostring(quit_err))
            assert(not vim.api.nvim_win_is_valid(file_win), ":q must close the targeted file window")
            if scenario == "modified_hidden" then
                assert(explorer.is_open(), "hidden modified file must preserve Explorer")
                assert(vim.api.nvim_buf_is_valid(file_buf) and vim.bo[file_buf].modified,
                    "hidden modified buffer must retain unsaved changes")
            elseif scenario == "split" then
                assert(explorer.is_open(), "another editing split must preserve Explorer")
            else
                assert(#vim.api.nvim_list_tabpages() == 1, "other tab must survive :q")
                assert(not explorer.is_open(), "Explorer in the closed tab must be closed")
                assert(vim.api.nvim_buf_get_name(0) == root .. "/README.md", "other tab file must remain")
            end
        end
    end)
    if not ok then
        vim.api.nvim_err_writeln(tostring(err))
        vim.cmd("cquit 1")
    else
        vim.cmd("qa!")
    end
end, 500)
