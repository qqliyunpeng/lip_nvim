local map = vim.keymap.set
local opt = vim.opt

opt.clipboard = "unnamedplus"
opt.cursorline = true


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

-- Resize splits with arrow keys
map("n", "<C-S-up>", "<cmd>res +5<CR>", { desc = "Increase upwards" })
map("n", "<C-S-down>", "<cmd>res -5<CR>", { desc ="Increase downwards" })
map("n", "<C-S-left>", "<cmd>vertical resize-5<CR>", { desc = "Increase leftwards" })
map("n", "<C-S-right>", "<cmd>vertical resize+5<CR>", { desc = "Increase rightwards" })


-- nvim中在ssh的终端中C-h表示backspace
map("n", "<BS>", "<C-w>h", { desc = "switch window left" })
map("n", "J", "5j", { desc = "line down 5" })
map("n", "K", "5k", { desc = "line up 5" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

-- telescope
map("n", "<leader>r", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>p", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map("n", "<leader>fp", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map("n", "<leader><tab>", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })

map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)

-- Comment 注释
map("n", "<leader>cc", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>cc", "gc", { desc = "toggle comment", remap = true })

-- nvimtree
map("n", "<F2>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "z<CR>", "zt", { desc = "Cursor to top", remap = true })

-- clipboard
-- from normalnvim
map("n", "z<CR>", "zt", { desc = "Cursor to top", remap = true })
map("n", "<C-y>", '"+y<esc>', { desc = "Copy to cliboard" })
map("n", "<C-y>", '"+y<esc>', { desc = "Copy to cliboard" })
map("n", "<C-d>", '"+y<esc>dd', { desc = "Copy to clipboard and delete line" })
map("n", "<C-d>", '"+y<esc>dd', { desc = "Copy to clipboard and delete line" })
map("n", "<C-p>", '"+p<esc>', { desc = "Paste from clipboard" })


-- Make 'c' key not copy to clipboard when changing a character.
map("n", "c", '"_c', { desc = "Change without yanking" })
map("n", "C", '"_C', { desc = "Change without yanking" })
map("n", "c", '"_c', { desc = "Change without yanking" })
map("n", "C", '"_C', { desc = "Change without yanking" })

map("x", "x", '"_x', { desc = "Delete all characters in line" })
map("x", "X", '"_X', { desc = "Delete all characters in line" })


map("n", "<leader>n", "<cmd> Telescope notify<CR>", { desc = "Notification History" })

-- snacks
-- map("n", "<leader>n", function() Snacks.notifier.show_history() end, { desc = "Notification History" })
map("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss All Notifications" })
map("n", "<leader>x", function() Snacks.bufdelete() end, { desc = "Delete Buffers" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })
map("n", "<A-n>", function() Snacks.terminal() end, { desc = "Terminal Open" })
map("t", "<A-n>", "<cmd>close<CR>", { desc = "Terminal Hide" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc =  "Go to Upper Window" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc =  "Go to Lower Window" })
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc =  "Go to Left Window"  })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc =  "Go to Right Window" })


