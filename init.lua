
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
    vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
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
-- vim.cmd[[highlight NonText guibg=NONE ctermbg=NONE]]
-- vim.cmd[[highlight LineNr guibg=NONE ctermbg=NONE]]
-- vim.cmd[[highlight SignColumn guibg=NONE ctermbg=NONE]]
-- 当前行高亮
vim.opt.cursorline = true
vim.cmd[[highlight CursorLine guibg=#3e4451 ctermbg=235]]


-- 打开文件后光标回到关闭的时候的位置
require'nvim-lastplace'.setup{}

require("telescope").load_extension("zf-native")


-- neoscroll 滚动顺滑
local neoscroll = require('neoscroll')
neoscroll.setup({
    -- Default easing function used in any animation where
    -- the `easing` argument has not been explicitly supplied
    easing = "quadratic"
})
local keymap = {
    -- Use the "sine" easing function
    ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 200; easing = 'sine' }) end;
    ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 200; easing = 'sine' }) end;
    -- Use the "circular" easing function
    ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 450; easing = 'circular' }) end;
    ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 450; easing = 'circular' }) end;
    -- When no value is passed the `easing` option supplied in `setup()` is used
    ["<A-y>"] = function() neoscroll.scroll(-0.1, { move_cursor=false; duration = 100 }) end;
    ["<A-w>"] = function() neoscroll.scroll(-0.1, { move_cursor=false; duration = 100 }) end;
    ["<A-3>"] = function() neoscroll.scroll(-0.1, { move_cursor=false; duration = 100 }) end;
    ["<A-e>"] = function() neoscroll.scroll(0.1, { move_cursor=false; duration = 100 }) end;
}
local modes = { 'n', 'v', 'x' }
for key, func in pairs(keymap) do
    vim.keymap.set(modes, key, func)
end



-- Project,nvim
vim.api.nvim_create_user_command('Root', 'ProjectRoot', {})  -- 将 :Root 映射到 :ProjectRoot

-- gitsigns
require('gitsigns').setup()

require'heirline'.setup{}
require 'bufferline'.setup{}
require 'interestingwords'.setup{}
require 'colorizer'.setup{}
--require 'notify'.setup{}
require 'nvim-autopairs'.setup{}
require 'noice'.setup{}
require 'dressing'.setup{}
require 'neodev'.setup()
require 'mason'.setup({
    registry = "https://gitcode.com/gh_mirrors/mason-registry",
})
require 'mason-lspconfig'.setup()
-- indent-blankline
require 'ibl'.setup()
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

