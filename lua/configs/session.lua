local map = vim.keymap.set
local persisted = require("persisted")
local utils = require("persisted.utils")

local M = {}

local allowed_dirs = {
    "~/.config/nvim",
    "~/wor_/test/aq300/r5/app_r5_0/src",
    "~/wor_/test/lvgl/lvgl_aq300/AQ300_lvgl_demo/lvgl_aq300",
    "~/wor_/test/aq160/lvgl",
    "~/wor_/test/aq160/or160_ui",
    "/home/lip/wor_/test/aq160/others_or160/libIPCProtocol",
}

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

