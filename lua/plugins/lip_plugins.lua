return {
    {
        "https://gitee.com/nvim_lip/onedarkpro.nvim.git",
        branch = 'main',
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
        event = "VeryLazy",
        config = function ()
            return require('configs.neoscroll').defaultConfig()
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
            { "gl", mode = { "n", "x", "o" }, function() require("flash").jump({
                search = { mode = "search", max_length = 0 },
                label = { after = { 0, 0 }},
                pattern = "^"
            }) end, desc = "Flash" },
            -- { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
            -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
            -- { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            -- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
    },
    {
        -- need `sudo apt-get install sqlite3 libsqlite3-dev`
        "https://gitee.com/nvim_lip/sqlite.lua.git",
    },
    {
        "https://gitee.com/yunduozhai/project.nvim.git",
        config = function()
            require("project_nvim").setup {
                -- 需不需要手动切换到工程目录下
                manual_mode  = true,
                silent_chdir = false,
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
        "https://gitee.com/nvim_lip/vim-illuminate.git",
        event = "VeryLazy",
        config = function()
            require('illuminate').configure({
                providers = { 'lsp', 'treesitter', 'regex' },
                delay = 100,
                -- disable in below
                filetypes_denylist = { 'dirbuf', 'dirvish', 'fugitive', 'NvimTree' },
                filetypes_allowlist = {'python', 'lua', 'c', 'cpp'},
                large_file_cutoff = 10000,
                disable_keymaps = true,
            })

            vim.keymap.set('n', '<a-j>', require('illuminate').goto_next_reference, { desc = "Move to next reference" })
            vim.keymap.set('n', '<a-k>', require('illuminate').goto_prev_reference, { desc = "Move to previous reference" })
        end
    },
    {
        -- 优化弹出结果中的排序
        "https://gitee.com/nvim_lip/telescope-zf-native.nvim.git",
        -- config = true,
    },
    {
        "https://gitee.com/nvim_lip/telescope-smart-history.nvim.git",
    },
    {
        "https://gitee.com/dragon-teng140806/telescope-live-grep-args.nvim.git",
    },
    {
        -- 语法高亮
        "https://gitee.com/zgpio/nvim-treesitter.git",
        event = { "BufReadPost", "BufNewFile" },
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        build = ":TSUpdate",
        opts = function()
            return require("configs.treesitter").treesitterConfig
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
        config = function()
            return require("configs.treesitter").textobjectsConfig()
        end
    },
    {
        -- vaq/viq 选中单引号或者双引号等各种引号之间的内容
        "https://gitee.com/nvim_lip/vim-textobj-quotes.git",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "https://gitee.com/duyz1218/vim-textobj-user.git",
            -- vaj/vij 向上查找最近的 '{[('
            "https://gitee.com/nvim_lip/vim-textobj-brace.git",
            -- var/vir 相同缩进的一整个认为的段落
            "https://gitee.com/nvim_lip/vim-textobj-indented-paragraph.git",
            -- vau/viu to first , . : ; ! ?
            "https://gitee.com/nvim_lip/vim-textobj-punctuation.git",
            -- val/vil 选中一行
            "https://gitee.com/nvim_lip/vim-textobj-line.git",
            -- va%/vi% match [] () {} or jump ]% [%
            -- "https://gitee.com/zgpio/vim-matchup.git",
            -- vac/vic 选中注释
            "https://gitee.com/nvim_lip/vim-textobj-comment.git",
        },
        config = function()
        end
    },
    {
        'https://gitee.com/nvim_lip/telescope.nvim.git', --tag = '0.1.8',
        -- dependencies = { "nvim-treesitter/nvim-treesitter" },
        cmd = "Telescope",
        opts = function()
            return require('configs.telescope')
        end,
    },
    {
        "https://gitee.com/nvim_lip/gitsigns.nvim.git", tag = 'v0.9.0',
        event = "VeryLazy",
        opts = function()
            require("configs.gitsigns").config()
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
        'https://gitee.com/nvim_lip/interestingwords.nvim.git',
        event = "VeryLazy",
        config = function()
            local m = require('interestingwords')
            require('interestingwords').setup{
                colors = { '#8CCBEA', '#A4E57E', '#FFDB72', '#FF7272', '#FFB3FF', '#9999FF' },
                search_count = true,
                navigation = false,
                scroll_center = true,
                -- search_key = "n",
                -- cancel_search_key = "<leader>N",
                color_key = "<leader>e",
                cancel_color_key = "<leader>K",
                select_mode = "loop",  -- random or loop
            }
            vim.keymap.del({'n', 'x'}, '<leader>m')
            vim.keymap.del('n', '<leader>M')
            vim.keymap.set("n", "<a-n>", function() m.NavigateToWord(true) end,
                { noremap = true, silent = true, desc = "InterestingWord Navigation Forward" })
            vim.keymap.set("n", "<a-N>", m.NavigateToWord,
                { noremap = true, silent = true, desc = "InterestingWord Navigation Backword" })
        end,
    },
    {
        'https://gitee.com/dragon-teng140806/nvim-colorizer.lua.git',
        event = "BufReadPost",
        config = function()
            return require("configs.ui_all").colorizerConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/nvim-autopairs.git",
        event = "InsertEnter",
        opts = {
            map_bs = true,
            fast_wrap = {},
            disable_filetype = { "TelescopePrompt", "vim"  },
        },
        config = function (_, opts)
            require("configs.autopairs").setup(opts)
        end
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
        event = { "BufReadPre", "BufNewFile" },
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
        "https://gitee.com/nvim_lip/LuaSnip",
        version = "v2.*",
        build = 'make install_jsregexp',
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            { "https://gitee.com/yunduozhai/friendly-snippets.git", branch = "main" }
        },

        config = function()
            require "configs.luasnip"
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
        event = "VeryLazy",
        config = function ()
            require 'neogen'.setup({ snippet_engine = "luasnip" })
        end
    },
    {
        'https://gitee.com/nvim_lip/render-markdown.nvim.git',
        branch = "main",
        event = "BufReadPost",
        config = function ()
            require('configs.ui_all').markdownConfig()
        end,
    },
    {
        -- 自动格式化 markdown 里边的表格 <leader>tm
        "https://gitee.com/yaozhijin/vim-table-mode.git",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            vim.cmd[[
                " unmap <leader>tm
                " unmap <leader>tt
                nnoremap <leader>ut :TableModeToggle<CR>
            ]]
        end
    },
    {
        "https://gitee.com/yunduozhai/lazygit.nvim.git",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
        end
    },
    {
        "https://gitee.com/nvim_lip/vim-visual-multi.git",
        event = { "BufReadPost", "BufNewFile" },
        config = function ()
            require('configs.edit').visualMulConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/navimark.nvim.git",
        event = { "BufReadPost", "BufNewFile" },
        config = function ()
            require('navimark').setup({
                keymap = {
                    base = {
                        mark_add = nil,
                        mark_remove = "<leader>mc",
                        open_mark_picker = "<leader>fm",
                    },
                },
                sign = {
                    text = "",
                    color = "#589ed7",
                },
                persist = true,
            })
        end,
    },
    {
        "https://gitee.com/nvim_lip/grug-far.nvim.git", branch = 'main',
        event = { "BufReadPost", "BufNewFile" },
        opts = { headerMaxWidth = 80 },
        cmd = "GrugFar",
        keys = {
            {
                "<leader>sr",
                function()
                    local grug = require('grug-far')
                    local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
                    grug.open({
                        transient = true,
                        prefills = {
                            search = vim.fn.expand("<cword>"),
                            filesFilter = ext and ext ~= "" and "*.*\n!/cscope.out" or nil,
                        },
                    })
                end,
                mode = { "n", "v" },
                desc = "Search and Replace",
            },
        },
        config = function()
            require('grug-far').setup({
                keymaps = {
                    qflist = { n = '=' },
                    close = { n = 'q' },
                },
                rg = {
                    options = {
                        '--no-ignore',
                    },
                },
            })
        end,
    },
    {
        -- session
        "https://gitee.com/nvim_lip/persisted.nvim.git",
        lazy = false,
        config = function ()
            require("configs.session").setDefault()
        end
    },
    {
        "https://gitee.com/yunduozhai/ts-comments.nvim.git",
        event = "VeryLazy",
        opts = {},
        enabled = vim.fn.has("nvim-0.10.0") == 1,
    },
    {
        "https://gitee.com/nvim_lip/yanky.nvim.git",
        event = "VeryLazy",
        keys = function()
            return require("configs.edit").yankKeys
        end,
        config = function ()
            return require("configs.edit").yankConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/nvim-toggler.git",
        event = "VeryLazy",
        config = function ()
            return require("configs.edit").nvimToggleConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/harpoon.git",
        branch = "harpoon2",
        dependencies = { "https://gitee.com/suyelu/plenary.nvim" },
        event = "VeryLazy",
        config = function()
            local harpoon = require("harpoon")
            require('harpoon').setup({
            })
            vim.keymap.set("n", "<leader>a", function() harpoon:list():add()
                                    vim.notify("Harpoon add: " .. vim.fn.expand('%:.')) end)
            -- Toggle previous & next buffers stored within Harpoon list
            vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
            vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)

            vim.keymap.set("n", "<leader>fe", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
            vim.keymap.set("n", "<a-1>", function() harpoon:list():select(1) end)
            vim.keymap.set("n", "<a-2>", function() harpoon:list():select(2) end)
            vim.keymap.set("n", "<a-3>", function() harpoon:list():select(3) end)

            local harpoon_extensions = require("harpoon.extensions")
            harpoon:extend(harpoon_extensions.builtins.highlight_current_file())
        end,
    },
    {
        "https://gitee.com/nvim_lip/mini.nvim.git",
        branch = "stable",
        event = "VeryLazy",
        config = function ()
            require("mini.ai").setup()
            require("mini.align").setup()
            require('configs.ui_all').miniIconsConfig()
            require('configs.edit').miniFileConfig()
            require("configs.edit").operatorsConfig()
            require("configs.indent").miniIndentInit()
            require('configs.edit').miniSurroundConfig()
            require('configs.edit').miniMoveConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/lspkind.nvim.git",
        opts = {},
    },
    {
        "https://gitee.com/nvim_lip/blink.cmp.git",
        branch = "main",
        event = "VeryLazy",
        build = require("configs.blink_cmp").blinkBuild(),
        config = function()
            require("configs.blink_cmp").blinkConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/overseer.nvim.git",
        branch = "master",
        event = "BufReadPost",
        config = function ()
            require('configs.overseer').overseerConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/sniprun.git",
        build = "sh install.sh",
        event = { "BufReadPost", "BufNewFile" },
        config = function ()
            require("sniprun").setup({
                display = {
                    "VirtualTextOk",   -- 在代码行右边显示结果
                    "VirtualTextErr",  -- 错误也显示
                    -- 还可以用 "Classic", "Terminal", "TempFloatingWindow"
                },
                inline_messages = 0,   -- 设置为1时，结果会以内联消息的形式显示
                borders = "rounded",   -- 浮窗边框样式
            })
        end
    }
}


