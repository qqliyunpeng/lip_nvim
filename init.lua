
local map = vim.keymap.set
vim.g.mapleader = ","

-- system
map("n", " ", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>q", "<cmd>q<CR>", { desc = "CMD quit" })

require 'options'

vim.env.TREE_SITTER_BOOTSTRAP_URL = "https://gitcode.net/CAPYIN/nvim-treesitter"

vim.api.nvim_create_augroup('MyVimEnterGroup', { clear = true })

-- 监听 VimEnter 事件
-- 解决在nvim命令开启界面的时候，snacks_dashboard 中开始的时候没有filetype
vim.api.nvim_create_autocmd('VimEnter', {
    group = 'MyVimEnterGroup',
    callback = function()
        -- 在 VimEnter 事件触发时执行的操作
        -- 例如，检查是否是 snacks_dashboard 界面，并设置 filetype
        if vim.bo.filetype == "" then
            vim.bo.filetype = 'snacks_dashboard'
        end
    end,
})


-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    local repo = "https://gitee.com/dinary/lazy.nvim.git"
    local out = vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
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

require 'mappings'


-- ui or color
vim.cmd("colorscheme onedark")

-- IlluminatedWordText have problem
vim.cmd([[
hi! link IlluminatedWordText Search
hi! link IlluminatedWordRead HlSearchLens
hi! link IlluminatedWordWrite  HlSearchLens
hi Normal guibg=NONE ctermbg=NONE
" 当前行
hi CursorLine guibg=#3e4451 ctermbg=235
" 当前行号
hi CursorLineNr cterm = bold gui = bold guifg=#ff966c
" 搜索的结果中当前的块的背景颜色
hi CurSearch guibg=#ff966c
" 弹出的窗口右侧的下拉框的颜色
hi PmenuThumb guibg=#c678dd ctermbg=127
hi MiniIndentscopeSymbol guifg=#589ed7 guibg=NONE
]])

-- 复制之后高亮显示一下复制的内容
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('highlight_yank', {}),
    desc = 'Highlight selection on yank',
    pattern = '*',
    callback = function()
        vim.highlight.on_yank { higroup = 'CurSearch', timeout = 400 }
    end,
})


-- 打开文件后光标回到关闭的时候的位置
require'nvim-lastplace'.setup{}
require('neoscroll')


-- local ssh_connection = vim.fn.getenv("SSH_CONNECTION")

-- if ssh_connection ~= vim.NIL then
--     vim.g.clipboard = {
--         name = 'OSC 52',
--         copy = {
--             ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
--             ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
--         },
--         paste = {
--             ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
--             ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
--         },
--     }
-- end


-- Project,nvim
vim.api.nvim_create_user_command('Root', 'ProjectRoot', {})  -- 将 :Root 映射到 :ProjectRoot

-- gitsigns
require('gitsigns').setup()

require'heirline'
require 'bufferline'
require 'interestingwords'
require 'colorizer'
require 'nvim-autopairs'.setup{}
require 'noice'
require 'dressing'.setup{}

require 'mason'.setup({
    registry = "https://gitcode.com/gh_mirrors/mason-registry",
})
require 'mason-lspconfig'.setup()

require('lsp_signature')

-- indent-blankline
require('ibl')
require('snacks')
require('mini.indentscope')

require('whitespace-nvim')
require('lspsaga')

require 'neogen'.setup({ snippet_engine = "luasnip" })


