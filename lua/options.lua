local opt = vim.opt
local o = vim.o
local g = vim.g

-------------------------------------- options ------------------------------------------
--
-- base config
--
o.shiftwidth = 4
o.ruler = true
 -- 滚动屏幕时上下至少5行
o.scrolloff = 5
-- 显示相对行号和当前行的设置
o.relativenumber = true
o.number = true
o.wrap = false
-- code indent and typesetting config
o.autoindent = true
o.smartindent = true

--
-- code indent and typesetting config
--
o.tabstop = 4
o.shiftwidth  = 4
o.softtabstop = 4
-- 用空格代替Tab
o.expandtab = true
o.sidescroll = 0
o.sidescrolloff = 4

o.termguicolors = true


-- disable nvim intro
opt.shortmess:append "sI"

-- 弹出的条目最多20个
opt.pumheight = 20

opt.ignorecase = true -- case insensitive searching
opt.infercase = true -- infer cases in keyword completion
opt.smartcase = true -- case sensitive searching
opt.writebackup = false -- disable making a backup before overwriting a file
opt.expandtab = true -- enable the use of space in tab

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

