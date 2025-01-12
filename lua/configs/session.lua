local map = vim.keymap.set
local persisted = require("persisted")
local utils = require("persisted.utils")

local M = {}

local allowed_dirs = {
    "~/.config/nvim",
}

M.setDefault = function ()
    persisted.setup({
        save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"),
        autoload = true,
        should_save = function ()
            return utils.dirs_match(vim.fn.getcwd(), allowed_dirs)
        end,
    })

    map({ "n", "t" }, "<leader>wn", "<cmd>SessionSave<CR>", { noremap = true, silent = true,  desc = "session workspace add" })
    map({ "n", "t" }, "<leader>ww", "<cmd>Telescope persisted<CR>", { noremap = true, silent = true,  desc = "session workspace select" })
end

return M

