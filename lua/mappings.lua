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


-- nvim中在ssh的终端中C-h表示backspac
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
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })

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
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "z<CR>", "zt", { desc = "Cursor to top", remap = true })

