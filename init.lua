
local map = vim.keymap.set
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- system
map("n", " ", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>q", "<cmd>q<CR>", { desc = "CMD quit" })

require('options')

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

require('mappings')


-- ui or color
vim.cmd.colorscheme "onedark"

-- IlluminatedWordText have problem
vim.cmd([[
hi! link IlluminatedWordText Search
hi! link IlluminatedWordRead HlSearchLens
hi! link IlluminatedWordWrite  HlSearchLens
"hi Normal guibg=NONE ctermbg=NONE
hi Normal guibg=black ctermbg=black
"hi NormalNC guibg=black ctermbg=black
hi TelescopeNormal guibg=black ctermbg=black
hi! link TelescopeTitle  TelescopeNormal
hi! link TelescopeBorder TelescopeNormal
hi! link TelescopeResultsNumber TelescopeNormal
hi! link TelescopePreviewTile TelescopeNormal
"hi TelescopeNormal guibg=NONE ctermbg=NONE
hi LineNr guibg=NONE ctermbg=NONE
" 当前行
hi CursorLine guibg=#3e4451 ctermbg=235
" 当前行号
hi CursorLineNr cterm = bold gui = bold guifg=#ff966c
" 搜索的结果中当前的块的背景颜色
hi CurSearch guibg=#ff966c
hi Search guifg=#c8d3f5 guibg=#3e68d7
" 弹出的窗口右侧的下拉框的颜色
hi PmenuThumb guibg=#c678dd ctermbg=127
hi MiniIndentscopeSymbol guifg=#589ed7 guibg=NONE
hi GrugFarResultsMatch      guifg=#1b1d2b guibg=#ff757f
hi GrugFarResultsMatchAdded guifg=#1b1d2b guibg=#589ed7
hi! link GrugFarResultsMatchRemoved GrugFarResultsMatch
hi GrugFarResultsHeader     guifg=#ff966c guibg=NONE
]])


-- 打开文件后光标回到关闭的时候的位置
require('nvim-lastplace').setup{}


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


-- Project.nvim
vim.api.nvim_create_user_command('Root', 'ProjectRoot', {})  -- 将 :Root 映射到 :ProjectRoot


require('mason').setup({
    registry = "https://gitcode.com/gh_mirrors/mason-registry",
})
require('mason-lspconfig').setup()

-- indent-blankline
require('snacks')
require('mini.indentscope')

require('noice')

