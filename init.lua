
vim.g.mapleader = ","


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
-- require 'mason'.setup{}
require 'mason'.setup({
    registry = "https://gitcode.com/gh_mirrors/mason-registry",
})
-- require 'mason-lspconfig'.setup{}
-- indent-blankline
require 'ibl'.setup()

local status, null_ls = pcall(require, 'null-ls')
if not status then
  vim.notify '没有找到 null-ls'
  return
end

local formatting = null_ls.builtins.formatting

null_ls.setup {
  debug = true,
  sources = {
    null_ls.builtins.code_actions.gitsigns,
    -- Formatting ---------------------
    --  brew install shfmt
    formatting.shfmt,
    -- StyLua
    formatting.stylua,
    -- frontend
    formatting.prettier.with {
      -- 只比默认配置少了 markdown
      filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'vue',
        'css',
        'scss',
        'less',
        'html',
        'json',
        'yaml',
        'graphql',
        'c',
        'cpp',
      },
      prefer_local = 'node_modules/.bin',
      args = { '--tab-width', '4' },
    },

    null_ls.builtins.diagnostics.eslint,
    null_ls.builtins.completion.spell,
    -- formatting.fixjson,
    -- formatting.black.with({ extra_args = { "--fast" } }),
  },
  -- 保存自动格式化
  on_attach = function(client)
        print("lip4: on_attach")
    --client.offset_encoding = 'utf-16' -- 可能没有用
    if client.server_capabilities.documentFormattingProvider then
      local pos = vim.fn.getpos '.'
      --vim.cmd 'autocmd BufWritePre <buffer> lua vim.lsp.buf.format(format_opts)'
      vim.fn.setpos('.', pos)
    end
  end,
}

local mason_lspconfig = require 'mason-lspconfig'

local servers = {
    clangd = {},
    pyright = {},
    lua_ls = {
        Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
        },
    },
}

-- mason_lspconfig.setup {
--     ensure_installed = vim.tbl_keys(servers),
--     print("lip: ", vim.tbl_keys(servers))
-- }

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)


-- mason_lspconfig.setup_handlers {
local handlers = {
    function(server_name)
        -- local server_config = {
        --     on_attach = on_attach,
        --     capabilities = capabilities,
        --     settings = servers[server_name],
        -- }
        -- 如果server_name为clangd,设置--offset-encoding=utf-16
        -- if server_name == 'clangd' then
        --     server_config.cmd = {
        --         'clangd',
        --         '--offset-encoding=utf-16',
        --     }
        --     server_config.init_options = {
        --         filetypes = { 'c', 'cpp' },
        --         clangdFileStatus = true,
        --         usePlaceholders = true,
        --         completeUnimported = true,
        --         semanticHighlighting = true,
        --         --root_dir = mason_lspconfig.util.root_pattern('compile_commands.json', 'compile_flags.txt', '.git'),
        --     }
        -- end
        require('lspconfig')[server_name].setup{}
    end,
    ["lua_ls"] = function ()
        local lspconfig = require("lspconfig")
        lspconfig.lua_ls.setup {
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim" }
                    }
                }
            }
        }
    end,
}

mason_lspconfig.setup({
    ensure_installed = vim.tbl_keys(servers),
    handlers = handlers,
})
mason_lspconfig.setup_handlers(handlers)

-- local notify = require('notify')
-- notify("hello lip!")
-- vim.notify = require("notify")

-- nvim-cmp setup
local cmp = require 'cmp'
local luasnip = require 'luasnip'

luasnip.config.setup {}


local status, null_ls = pcall(require, 'null-ls')
if not status then
    vim.notify '没有找到 null-ls'
    return
end

null_ls.setup {
  debug = true,
  sources = {
    null_ls.builtins.code_actions.gitsigns,

    null_ls.builtins.diagnostics.eslint,
    null_ls.builtins.completion.spell,
    -- formatting.fixjson,
    -- formatting.black.with({ extra_args = { "--fast" } }),
  },
}

require 'options'
require 'mappings'

