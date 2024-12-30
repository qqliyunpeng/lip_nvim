return {
    {
        "olimorris/onedarkpro.nvim",
        priority = 1000, -- Ensure it loads first
    },
    {
        "https://gitee.com/yunduozhai/nvim-notify.git",
        config = function()
            local function calculate_half_width()
                return math.floor(vim.o.columns * 0.4)
            end
            require('notify').setup({
                background_colour = "#000000",
                stages = "slide",
                render = "wrapped-compact",
                timeout = 3000,
                top_down = true,
                max_width = calculate_half_width(),
            })
        end,
    },
    {
        "https://gitee.com/yunduozhai/neoscroll.nvim.git",
        config = function ()
            require('neoscroll').setup({
                mappings = {                 -- Keys to be mapped to their corresponding default scrolling animation
                    '<C-u>', '<C-d>',
                    '<C-b>', '<C-f>',
                    '<C-y>', '<C-e>',
                    'zt', 'zz', 'zb',
                },
                hide_cursor = false,          -- Hide cursor while scrolling
                stop_eof = true,             -- Stop at <EOF> when scrolling downwards
                respect_scrolloff = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
                cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
                easing = 'quadratic',        -- Default easing function
                pre_hook = nil,              -- Function to run before the scrolling animation starts
                post_hook = nil,             -- Function to run after the scrolling animation ends
                performance_mode = false,    -- Disable "Performance Mode" on all buffers.
                ignored_events = {           -- Events ignored while scrolling
                    'WinScrolled', 'CursorMoved'
                },
            })
        end
    },
    {
        "https://gitee.com/huangshaoqi/flash.nvim.git",
        event = "VeryLazy",
        -- type Flash.Config
        opts = {},
        -- stylua: ignore
        keys = {
            { "m", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
            -- { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
            -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
            -- { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            -- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
    },
    {
        -- need `sudo apt-get install sqlite3 libsqlite3-dev`
        "kkharji/sqlite.lua",
    },
    {
        "https://gitee.com/yunduozhai/project.nvim.git",
        config = function()
            require("project_nvim").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
                manual_mode = true,
                patterns = {
                    -- use
                    ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json",
                    -- ignore
                    "!.git/worktrees", "!=extras", "!^fixtures", "!build/env.sh",
                },
            }
        end
    },
    {
        "https://gitee.com/zhengqijun/nvim-lastplace.git",
        config = function()
            require('nvim-lastplace').setup()
        end
    },
    {
        "https://gitee.com/hello-luiswu/accelerated-jk.git",
        keys = {
            {"j", "<Plug>(accelerated_jk_gj)" },
            {"k", "<Plug>(accelerated_jk_gk)" },
        },
    },
    {
        "https://gitee.com/yunduozhai/vim-illuminate.git",
        event = "VeryLazy",
        config = function()
            require('illuminate').configure({
                providers = {
                    -- 'lsp',
                    'treesitter',
                    -- 'regex',
                },
                delay = 800,
                -- disable in below
                filetypes_denylist = {
                    'dirbuf',
                    'dirvish',
                    'fugitive',
                    'NvimTree',
                },
                filetypes_allowlist = {'python', 'lua', 'c', 'cpp'},
            })
        end
    },
    {
        "https://gitee.com/rulei_mirror/vim-oscyank.git",
        config = true,
    },
    {
        -- 优化弹出结果中的排序
        "https://gitee.com/nvim_lip/telescope-zf-native.nvim.git",
        -- config = true,
    },
    {
        "nvim-telescope/telescope-smart-history.nvim",
    },
    {
        -- 语法高亮
        "https://gitee.com/zgpio/nvim-treesitter.git",
        event = { "BufReadPost", "BufNewFile" },
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        build = ":TSUpdate",
        opts = function()
            return require "configs.treesitter"
        end,
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end,
    },
    {
        "https://gitee.com/yunduozhai/nvim-treesitter-textobjects.git",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "nvim-treesitter",
        },
    },
    {
        -- 在最上边显示当前函数的函数名字
        "nvim-treesitter/nvim-treesitter-context",
        event = { "BufReadPost", "BufNewFile" },
        opts = {}
    },
    {
        'https://gitee.com/nvim_lip/telescope.nvim.git', --tag = '0.1.8',
        -- dependencies = { "nvim-treesitter/nvim-treesitter" },
        cmd = "Telescope",
        opts = function()
            return require('configs/telescope')
        end,
    },
    {
        "https://gitee.com/nvim_lip/gitsigns.nvim.git", tag = 'v0.9.0',
        event = "User FilePost",
        opts = function()
            return require("configs.gitsigns")
        end,
    },
    {
        -- file managing , picker etc
        "https://gitee.com/oyaay/nvim-tree.lua.git",
        cmd = { "NvimTreeToggle", "NvimTreeFocus" },
        opts = function()
            return require "configs.nvimtree"
        end,
    },
    {
        'Mr-LLLLL/interestingwords.nvim',
        config = function()
            require('interestingwords').setup{
                colors = { '#8CCBEA', '#A4E57E', '#FFDB72', '#FF7272', '#FFB3FF', '#9999FF' },
                search_count = true,
                navigation = true,
                scroll_center = true,
                -- search_key = "n",
                -- cancel_search_key = "<leader>N",
                color_key = "<leader>e",
                cancel_color_key = "<leader>K",
                select_mode = "loop",  -- random or loop
            }
        end,
    },
    {
        'https://gitee.com/dragon-teng140806/nvim-colorizer.lua.git',
        config = function()
            -- Exclude some filetypes from highlighting by using `!`
            require ('colorizer').setup {
                'lua'; -- Highlight lua files, but customize some others.
            }
            vim.cmd('ColorizerAttachToBuffer')
        end
    },
    {
        "windwp/nvim-autopairs",
        opts = {
            fast_wrap = {},
            disable_filetype = { "TelescopePrompt", "vim"  },
        },
        config = function(_, opts)
            require("nvim-autopairs").setup(opts)

            -- setup cmp for autopairs
            local cmp_autopairs = require "nvim-autopairs.completion.cmp"
            require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
    },
    {
        -- Automatically install LSPs to stdpath for neovim
        'https://gitee.com/suyelu/mason.nvim',
        cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate" },
        opts = function()
            return require "configs.mason"
        end,
    },
    {
        'https://gitee.com/suyelu/mason-lspconfig.nvim',
        -- config = true,
        config = function()
            return require("configs.lspconfig").defaults()
        end
    },
    -- below from https://gitee.com/suyelu/nvim/blob/master/init.lua
    {
        -- LSP Configuration & Plugins
        'https://gitee.com/suyelu/nvim-lspconfig',
        dependencies = {
            'https://gitee.com/suyelu/mason-lspconfig.nvim',

            -- Useful status updates for LSP
            -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
            -- notify and right-bottom info
            -- { 'https://gitee.com/suyelu/fidget.nvim', tag = 'legacy', opts = {} },
            -- Additional lua configuration, makes nvim stuff amazing!
            -- used to dismiss vim warning
            -- 'https://gitee.com/suyelu/neodev.nvim',
        },
        -- event = "User FilePost",
    },
    {
        "https://gitee.com/nvim_lip/lspkind.nvim.git",
        lazy = true,
        -- enabled = vim.g.icons_enabled ~= false,
        enabled = true,
        -- mode = 'symbol_text',
        mode = 'symbol_text',
        ellipsis_char = '...',
        show_labelDetails = true,
        preset = 'codicons',
        opts = {
            mode = "symbol",
            symbol_map = {
                Array = "󰅪",
                Boolean = "⊨",
                Class = "󰌗",
                Constructor = "",
                Key = "󰌆",
                Namespace = "󰅪",
                Null = "NULL",
                Number = "#",
                Object = "󰀚",
                Package = "󰏗",
                Property = "",
                Reference = "",
                Snippet = "",
                String = "󰀬",
                TypeParameter = "󰊄",
                Unit = "",
            },
            menu = {},
        },
        config = function(_, opts)
            require('lspkind').init({
                opts,
            })
        end,
    },
    {
        -- lsp 输入的同时提示参数
        "https://gitee.com/yunduozhai/lsp_signature.nvim.git",
        config = function()
            return require("configs.lspconfig").lspSignatureDefaults()
        end
    },
    {
            "https://gitee.com/yunduozhai/friendly-snippets.git",
            branch = 'main',
    },
    {
        "https://gitee.com/zhengqijun/cmp-emoji.git",
        config = function()
            require'cmp'.setup {
                sources = {
                    { name = 'emoji' }
                }
            }
        end
    },
    {
        string.format('%s/LuaSnip', 'https://gitee.com/suyelu'),
        build = 'make install_jsregexp',
        dependencies = {
            "https://gitee.com/yunduozhai/friendly-snippets.git",
        },

        config = function(_, opts)
            require "configs.luasnip"
        end,
    },
    {
        -- Autocompletion
        'https://gitee.com/suyelu/nvim-cmp',
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-emoji",
            string.format('%s/cmp-nvim-lsp', 'https://gitee.com/suyelu'),
            string.format('%s/cmp_luasnip', 'https://gitee.com/suyelu'),
            string.format('%s/cmp-buffer' , 'https://gitee.com/suyelu'),
            string.format('%s/cmp-path'   , 'https://gitee.com/suyelu'),
            string.format('%s/cmp-cmdline', 'https://gitee.com/suyelu'),
        },

        opts = function()
            return require "configs.cmp"
        end,
    },
    {
        string.format('%s/null-ls.nvim.git', 'https://gitee.com/suyelu'),
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            string.format('%s/plenary.nvim', 'https://gitee.com/suyelu'),
            { "https://gitee.com/yunduozhai/mason-null-ls.nvim.git", branch = 'main' },
        },
        config = function()
            local tools = {
                -- "black",
            }

            require("mason-null-ls").setup({
                ensure_installed = tools,
                handlers = {},
            })

            require("null-ls").setup({
                sources = {},
            })
        end
    },
    {
        "https://gitee.com/yunduozhai/neogen",
        branch = 'main',
        config = true,
    },

    --  nvim-neoclip [nvim clipboard]
    --  https://github.com/AckslD/nvim-neoclip.lua
    --  Read their docs to enable cross-session history.
    {
        "AckslD/nvim-neoclip.lua",
        requires = 'nvim-telescope/telescope.nvim',
        event = "User BaseFile",
        opts = {}
    },

}


