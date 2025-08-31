
local map = vim.keymap.set
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- system
map("n", " ", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")
map("v", "q", "<Esc>")
map("n", "<a-q>", "<Esc><cmd>noh<CR>")
map("x", "<a-q>", "<Esc>")
map("n", "<leader>q", "<cmd>q<CR>", { desc = "CMD quit" })
map("n", "<leader>x", "<cmd>qa<CR>", { desc = "CMD quit all" })

require('options')

vim.env.TREE_SITTER_BOOTSTRAP_URL = "https://gitcode.net/CAPYIN/nvim-treesitter"

vim.api.nvim_create_augroup('MyVimEnterGroup', { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "man", "lspinfo", "checkhealth", "qf" },
    callback = function()
        vim.keymap.set("n", "q", "<cmd>quit<cr>", { buffer = true, silent = true })
    end,
})

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    local repo = "https://gitee.com/yunduozhai/lazy.nvim.git"
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
" set guicursor=n-v-c-sm:block-CursorLineNr,i-ci-ve:ver25,r-cr-o:hor20
hi Search guifg=#c8d3f5 guibg=#3e68d7
" 弹出的窗口右侧的下拉框的颜色
hi PmenuThumb guibg=#c678dd ctermbg=127
hi MiniIndentscopeSymbol guifg=#589ed7 guibg=NONE
hi GrugFarResultsMatch      guifg=#1b1d2b guibg=#ff757f
hi GrugFarResultsMatchAdded guifg=#1b1d2b guibg=#589ed7
hi! link GrugFarResultsMatchRemoved GrugFarResultsMatch
hi GrugFarResultsHeader     guifg=#ff966c guibg=NONE
hi! link VM_Cursor GrugFarResultsMatch
hi! link VM_Extend GrugFarResultsMatchAdded
hi! link VM_Mono   GrugFarResultsMatchAdded
hi! link VM_Insert GrugFarResultsMatch
hi LspReferenceText guifg=NONE guibg=NONE
hi! link IlluminatedWordText  CursorLine
hi! link IlluminatedWordWrite CursorLine
hi! link IlluminatedWordRead  CursorLine
hi! link BlinkCmpMenu       Normal
hi! link BlinkCmpMenuBorder Normal
hi! link BlinkCmpDoc        Normal
hi! link BlinkCmpDocBorder  Normal
hi! link BlinkCmpDocCursorLine  Normal
hi! link BlinkCmpDocSeparator   Normal
hi! link BlinkCmpMenuSelection  CursorLine
hi! link HoverNormal Normal
hi! link HoverBorder Normal
hi! link SagaNormal  Normal
hi! link SagaBorder  Normal
hi! link WhichKeyBorder  Normal
hi! link WhichKeyNormal  Normal
hi FloatBorder guibg=Black
]])

vim.lsp.set_log_level("off")

-- 打开文件后光标回到关闭的时候的位置
require('nvim-lastplace').setup{}

-- Project.nvim
vim.api.nvim_create_user_command('Root', 'ProjectRoot', {})  -- 将 :Root 映射到 :ProjectRoot


require('mason').setup({
    registry = "https://gitcode.com/gh_mirrors/mason-registry",
})

-- indent-blankline

require('noice')

require("configs.num_change").tg_format()
require("configs.num_change").tg_format_array()

