
local map = vim.keymap.set
vim.g.mapleader = ","

-- system
map("n", " ", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>q", "<cmd>q<CR>", { desc = "CMD quit" })


vim.env.TREE_SITTER_BOOTSTRAP_URL = "https://gitcode.net/CAPYIN/nvim-treesitter"

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


-- ui
vim.cmd("colorscheme onedark")
-- 背景设置成透明
-- vim.opt.background = 'dark' -- 或使用 'light'
vim.cmd[[highlight Normal guibg=NONE ctermbg=NONE]]
-- 当前行高亮
vim.opt.cursorline = true
vim.cmd[[highlight CursorLine guibg=#3e4451 ctermbg=235]]
vim.cmd[[highlight PmenuThumb guibg=#c678dd ctermbg=127]]

-- IlluminatedWordText have problem
vim.cmd([[
highlight! link IlluminatedWordText Search
highlight! link IlluminatedWordRead HlSearchLens
highlight! link IlluminatedWordWrite  HlSearchLens
]])


-- 打开文件后光标回到关闭的时候的位置
require'nvim-lastplace'.setup{}
require('neoscroll').setup()


local ssh_connection = vim.fn.getenv("SSH_CONNECTION")

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

require'heirline'.setup{}
require 'bufferline'.setup{}
require 'interestingwords'.setup{}
require 'colorizer'.setup{}
require 'nvim-autopairs'.setup{}
require 'noice'.setup{}
require 'dressing'.setup{}

require 'mason'.setup({
    registry = "https://gitcode.com/gh_mirrors/mason-registry",
})
require 'mason-lspconfig'.setup()

-- indent-blankline
require 'ibl'.setup()
-- require('ibl').update { enabled = false }
require 'neogen'.setup({ snippet_engine = "luasnip" })

-- local status, null_ls = pcall(require, 'null-ls')
-- if not status then
--   vim.notify '没有找到 null-ls'
--   return
-- end
--
-- local formatting = null_ls.builtins.formatting
--
-- null_ls.setup {
--   debug = true,
--   sources = {
--     null_ls.builtins.code_actions.gitsigns,
--     -- Formatting ---------------------
--     --  brew install shfmt
--     formatting.shfmt,
--     -- StyLua
--     formatting.stylua,
--     -- frontend
--     formatting.prettier.with {
--       -- 只比默认配置少了 markdown
--       filetypes = {
--         'javascript',
--         'javascriptreact',
--         'typescript',
--         'typescriptreact',
--         'vue',
--         'css',
--         'scss',
--         'less',
--         'html',
--         'json',
--         'yaml',
--         'graphql',
--         'c',
--         'cpp',
--       },
--       prefer_local = 'node_modules/.bin',
--       args = { '--tab-width', '4' },
--     },
--
--     null_ls.builtins.diagnostics.eslint,
--     null_ls.builtins.completion.spell,
--     -- formatting.fixjson,
--     -- formatting.black.with({ extra_args = { "--fast" } }),
--   },
-- }

-- local notify = require('notify')
-- notify("hello lip!")
-- vim.notify = require("notify")


require 'options'
require 'mappings'

