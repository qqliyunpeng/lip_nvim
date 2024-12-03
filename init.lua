local map = vim.keymap.set

-- system
vim.g.mapleader = ","
map("n", " ", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- 大小的L和H映射
map({ "n", "t" }, "L", "End", { noremap = true, silent = true,  desc = "to end of line" })
map({ "n", "t" }, "H", "<ESC>^i", { noremap = true, silent = true,  desc = "to begin of line" })
map({ "n", "t" }, "dL", "d$", { noremap = true, silent = true, desc = "del to end of line" })
map({ "n", "t" }, "dH", "d0", { noremap = true, silent = true, desc = "del to begin of line" })

map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })


-- nvim中在ssh的终端中C-h表示backspac
map("n", "<BS>", "<C-w>h", { desc = "switch window left" })
map("n", "J", "5j", { desc = "line down 5" })
map("n", "K", "5k", { desc = "line up 5" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

require 'options'


-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    local repo = "https://gitee.com/dinary/lazy.nvim.git"
    vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg"  },
            { out, "WarningMsg"  },
            { "\nPress any key to exit..."  },

        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
    { import = "plugins" },
}, lazy_config)

-- 打开文件后光标回到关闭的时候的位置
require'nvim-lastplace'.setup{}

-- telescope
map("n", "<leader>r", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
-- map("n", "<leader>p", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map("n", "<leader>fp", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map("n", "<leader><tab>", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })

map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)


-- neoscroll 滚动顺滑
local neoscroll = require('neoscroll')
neoscroll.setup({
    -- Default easing function used in any animation where
    -- the `easing` argument has not been explicitly supplied
    easing = "quadratic"
})
local keymap = {
    -- Use the "sine" easing function
    ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 200; easing = 'sine' }) end;
    ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 200; easing = 'sine' }) end;
    -- Use the "circular" easing function
    ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 450; easing = 'circular' }) end;
    ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 450; easing = 'circular' }) end;
    -- When no value is passed the `easing` option supplied in `setup()` is used
    ["<A-y>"] = function() neoscroll.scroll(-0.1, { move_cursor=false; duration = 100 }) end;
    ["<A-w>"] = function() neoscroll.scroll(-0.1, { move_cursor=false; duration = 100 }) end;
    ["<A-3>"] = function() neoscroll.scroll(-0.1, { move_cursor=false; duration = 100 }) end;
    ["<A-e>"] = function() neoscroll.scroll(0.1, { move_cursor=false; duration = 100 }) end;
}
local modes = { 'n', 'v', 'x' }
for key, func in pairs(keymap) do
    vim.keymap.set(modes, key, func)
end


-- Comment 注释
map("n", "<leader>cc", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>cc", "gc", { desc = "toggle comment", remap = true })


-- Project,nvim
vim.api.nvim_create_user_command('Root', 'ProjectRoot', {})  -- 将 :Root 映射到 :ProjectRoot

-- gitsigns
require('gitsigns').setup()

require'heirline'.setup{}
require 'bufferline'.setup{}
require 'interestingwords'.setup{}
require 'colorizer'.setup{}

-- nvimtree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })

