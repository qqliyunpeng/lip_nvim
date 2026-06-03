local map = vim.keymap.set
local persisted = require("persisted")
local utils = require("persisted.utils")

local M = {}

local default_allowed_dirs = {
    "~/.config/nvim",
}

local function load_allowed_dirs()
    local config_path = vim.fn.stdpath("data") .. "/.session_allowed_dirs.lua"
    local ok, dirs = pcall(dofile, config_path)

    if not ok or type(dirs) ~= "table" then
        dirs = default_allowed_dirs
    end

    return vim.tbl_map(vim.fn.expand, dirs)
end

local allowed_dirs = load_allowed_dirs()

function M.setDefault()
    persisted.branch = function()
        local branch = vim.fn.systemlist("git branch --show-current")[1]
        return vim.v.shell_error == 0 and branch
    end
    persisted.setup({
        save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"),
        autoload = true,
        use_git_branch = true,
        should_save = function ()
            return utils.dirs_match(vim.fn.getcwd(), allowed_dirs)
        end,
    })

    map({ "n", "t" }, "<leader>wn", "<cmd>SessionSave<CR>", { noremap = true, silent = true,  desc = "session workspace add" })
    map({ "n", "t" }, "<leader>ww", "<cmd>Telescope persisted<CR>", { noremap = true, silent = true,  desc = "session workspace select" })
end

return M

