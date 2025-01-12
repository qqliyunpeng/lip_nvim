local opt = vim.opt
local o = vim.o
local g = vim.g

-------------------------------------- options ------------------------------------------
--
-- base config
--
o.shiftwidth = 4
o.ruler = false -- 不显示光标的位置
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
vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = "make",
    command = "setlocal noexpandtab",
})

o.termguicolors = true

o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.timeoutlen = 400
o.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250

o.sessionoptions = "buffers,curdir,folds,globals,tabpages,winpos,winsize"

-- o.exrc = true -- open .nvim.lua, .nvimrc and .exrc support

-- disable nvim intro
opt.shortmess:append "sI"

-- 弹出的条目最多20个
opt.pumheight = 20

opt.ignorecase  = true -- case insensitive searching
opt.infercase   = true -- infer cases in keyword completion
opt.smartcase   = true -- case sensitive searching
opt.writebackup = false -- disable making a backup before overwriting a file
opt.expandtab   = true -- enable the use of space in tab
-- 允许这些切换行的行为，例如，光标在开头，然后 h 键后到上一行
opt.whichwrap:append "<>[]hl"

opt.colorcolumn = "80"
-- 欢迎界面中禁用
vim.api.nvim_create_autocmd("FileType", {
    pattern = "snacks_dashboard",
    callback = function ()
        vim.opt_local.colorcolumn = ''
    end,
})

-- 当前行高亮
opt.cursorline = true

-- vim.cmd [[highlight ColorColumn ctermbg=darkgrey guibg=darkgrey]]


-- disable some default providers
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

