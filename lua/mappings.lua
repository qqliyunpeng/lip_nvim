local map = vim.keymap.set
local opt = vim.opt

opt.clipboard = "unnamedplus"
opt.cursorline = true

-- 大小的L和H映射
map({ "x", "n", "o" }, "L", "g_",  { noremap = true, silent = true, desc = "To end of line" })
map({ "x", "n", "o" }, "H", "^" ,  { noremap = true, silent = true, desc = "To begin of line" })
map({ "x", "n", "o" }, "J", "<cmd>normal!5j<cr>",  { desc = "line down 5" })
map({ "x", "n", "o" }, "K", "<cmd>normal!5k<cr>",  { desc = "line up 5" })

map("i", "<C-h>", "<Left>",     { desc = "move left" })
map("i", "<C-l>", "<Right>",    { desc = "move right" })
map("i", "<C-j>", "<Down>",     { desc = "move down" })
map("i", "<C-k>", "<Up>",       { desc = "move up" })

map("n", "<C-h>", "<C-w>h",     { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l",     { desc = "switch window right" })
-- map("n", "<C-j>", "<C-w>j",  { desc = "switch window down" })
-- map("n", "<C-k>", "<C-w>k",  { desc = "switch window up" })

map({"n", "i"}, "<C-s>", "<cmd>w<CR>", { desc = "Save current files" })

-- Resize splits with arrow keys
map("n", "<C-S-up>", "<cmd>res +5<CR>",   { desc = "Increase upwards" })
map("n", "<C-S-down>", "<cmd>res -5<CR>", { desc ="Increase downwards" })
map("n", "<C-S-left>", "<cmd>vertical resize-5<CR>",  { desc = "Increase leftwards" })
map("n", "<C-S-right>", "<cmd>vertical resize+5<CR>", { desc = "Increase rightwards" })


-- nvim中在ssh的终端中C-h表示backspace
map("n", "<BS>", "<C-w>h", { desc = "switch window left" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

-- telescope
-- map("n", "<leader>r", "<cmd>Telescope oldfiles<CR>",    { desc = "telescope find oldfiles" })
-- map("n", "<leader>p", "<cmd>Telescope find_files<CR>",  { desc = "telescope find files" })
-- map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "telescope find files" })
-- map("n", "<leader><tab>", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
-- map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>",  { desc = "telescope live grep" })
-- map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",  { desc = "telescope help page" })
-- map("n", "<leader>ma", "<cmd>Telescope marks<CR>",      { desc = "telescope find marks" })
-- map("n", "<leader>gt", "<cmd>Telescope git_status<CR>",  { desc = "Git status" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })

map("n", "<leader>r",  function() Snacks.picker.recent() end,     { desc = "Snacks find oldfiles" })
map("n", "<leader>p",  function() Snacks.picker.files() end,      { desc = "Snacks find files" })
map("n", "<leader>n",  function() Snacks.picker.notifications() end,      { desc = "Notification" })
map("n", "<leader>ff", function() Snacks.picker.files() end,      { desc = "Snacks find files" })
map("n", "<leader><tab>", function() Snacks.picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>fw", function() Snacks.picker.grep() end,       { desc = "Snacks live grep" })
map("n", "<leader>fh", function() Snacks.picker.help() end,  { desc = "telescope help page" })
map("n", "<leader>fm", function() Snacks.picker.marks() end,      { desc = "Snacks find marks" })
map("n", "<leader>gt", function() Snacks.picker.git_status() end, { desc = "Git status" })
map("n", "<leader>fM", function() Snacks.picker.man() end, { desc = "Man Pages" })

map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)

-- buffer
map("n", "[b"       , "<cmd>bprevious<CR>", { desc = "Prev Buffer" })
map("n", "]b"       , "<cmd>bnext<CR>"    , { desc = "Next Buffer" })
map("n", "<leader>`", "<cmd>e #<CR>"      , { desc = "Switch to Other Buffer" })
map("n", "<a-`>"    , "<cmd>e #<CR>"      , { desc = "Switch to Other Buffer" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
-- map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
-- map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
-- map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
-- map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
-- map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
-- map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Comment 注释
map("n", "<leader>cc", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>cc", "gc",  { desc = "toggle comment", remap = true })
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below"})
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above"})

-- nvimtree
map("n", "<F2>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "z<CR>", "zt", { desc = "Cursor to top", remap = true })

-- clipboard
-- from normalnvim
map("n", "z<CR>", "zt", { desc = "Cursor to top", remap = true })

-- c and d 删除操作不复制到剪切板
-- x 在 normal 模式下，不复制内容到剪切板
-- x 在 visual 模式下，复制内容到剪切板，我们可以当他是 + 来记忆
map("n", "c", '"_c', { desc = "Change without yanking" })
map("n", "C", '"_C', { desc = "Change without yanking" })
map("n", "d", '"_d', { desc = "Delete without yanking" })
map("n", "D", '"_D', { desc = "Delete without yanking" })
map("n", "x", '"_x', { desc = "Delete without yanking" })
map("n", "X", '"_X', { desc = "Delete without yanking" })
map("x", "p", [["_c<c-r>"<esc>]], { desc = "Paste without yanking replaced text" })
map("x", "P", [["_C<c-r>"<esc>]], { desc = "Paste without yanking replaced text" })

-- map("n", "<leader>n", "<cmd> Noice<CR>", { desc = "Notification History" })

-- snacks
-- map("n", "<leader>n", function() Snacks.notifier.show_history() end, { desc = "Notification History" })
map("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss All Notifications" })
map("n", "<leader>bd", function() Snacks.bufdelete() end,     { desc = "Delete Buffers" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })
map("n", "<A-b>", function() Snacks.terminal() end, { desc = "Terminal Open" })
map("t", "<A-b>", "<cmd>close<CR>",                 { desc = "Terminal Hide" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc =  "Go to Upper Window" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc =  "Go to Lower Window" })
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc =  "Go to Left Window"  })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc =  "Go to Right Window" })

-- search
map('n', '<A-/>', function()
    vim.cmd('let @/ = expand("<cword>") | set hlsearch')   -- 设置搜索寄存器
end, { desc = '搜索光标下单词' })
map('x', '<A-/>', function()
    vim.cmd('noautocmd normal! "vy')        -- 设置搜索寄存器
    vim.cmd('let @/ = @v | set hlsearch')   -- 设置搜索寄存器
end, { desc = '搜索光标下单词' })

-- 粘贴快捷键 (当粘贴的内容最后是换行符，则需要格式化，如果不是 不格式化)
map("n", "p", function() require("configs.edit").pasteSmart() end, { desc = "Paste smart" })
map("n", "P", function() require("configs.edit").PasteSmart() end, { desc = "Paste smart" })

-- 头文件中生成声明信息
map("n", "<leader>hh", function() require("configs.gendeclare").create_declare() end, { desc = "Create header declare" })

-- 命令个行退出
map("c", "<A-q>", "<C-c>", { desc = "Exit cmdline" })

-- LSP
local function opts(desc)
    return { desc = "LSP " .. desc }
end
map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
-- map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
-- map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts "Show references")
map("n", "gr", function() Snacks.picker.lsp_references() end, opts "Show references")
map("n", "<leader>sh", vim.lsp.buf.signature_help, opts "Show signature help")
map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, opts "List workspace folders")

map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")

