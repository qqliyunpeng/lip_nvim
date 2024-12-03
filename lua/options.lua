local opt = vim.opt
local o = vim.o
local g = vim.g

-------------------------------------- options ------------------------------------------
-- base config
o.shiftwidth = 4
o.ruler = true
-- 用空格代替Tab
o.expandtab = true
 -- 滚动屏幕时上下至少5行
o.scrolloff = 5
-- o.background = dark
o.rnu = true
o.wrap = false
-- code indent and typesetting config
o.autoindent = true
o.smartindent = true
o.tabstop = 4
o.softtabstop = 4
o.sidescroll = 0
o.sidescrolloff = 4

o.termguicolors = true

-- 背景设置成透明
-- vim.opt.background = 'dark' -- 或使用 'light'
vim.cmd[[highlight Normal guibg=NONE ctermbg=NONE]]
-- vim.cmd[[highlight NonText guibg=NONE ctermbg=NONE]]
-- vim.cmd[[highlight LineNr guibg=NONE ctermbg=NONE]]
-- vim.cmd[[highlight SignColumn guibg=NONE ctermbg=NONE]]

-- TODO: 还没有实现光标所在行背景带颜色
opt.cursorline = true
vim.cmd[[highlight CursorLine guibg=#3e4451 ctermbg=235]]


-- disable nvim intro
opt.shortmess:append "sI"

o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.timeoutlen = 400
o.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250

-- disable some default providers
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

