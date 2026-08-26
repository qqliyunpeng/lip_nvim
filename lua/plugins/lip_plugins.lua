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
        "https://gitee.com/nvim_lip/vim-autoread.git",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            vim.opt.autoread = true
            vim.o.updatetime = 500

            local function can_restore_external_change(buf)
                return vim.api.nvim_buf_is_valid(buf)
                    and vim.bo[buf].buftype == ""
                    and not vim.bo[buf].modified
            end

            local group = vim.api.nvim_create_augroup("lip_checktime", { clear = true })
            local saved_views = {}

            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "TermLeave" }, {
                group = group,
                pattern = "*",
                callback = function()
                    if vim.fn.mode() ~= "c" then
                        local buf = vim.api.nvim_get_current_buf()
                        if can_restore_external_change(buf) then
                            saved_views[buf] = {}
                            for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                                if vim.api.nvim_win_is_valid(win) then
                                    saved_views[buf][win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
                                end
                            end
                        end

                        vim.cmd("checktime")
                    end
                end,
            })

            vim.api.nvim_create_autocmd("FileChangedShellPost", {
                group = group,
                pattern = "*",
                callback = function(args)
                    local views = saved_views[args.buf]
                    saved_views[args.buf] = nil
                    if not views then
                        return
                    end

                    vim.schedule(function()
                        if not vim.api.nvim_buf_is_valid(args.buf) then
                            return
                        end

                        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
                            local view = views[win]
                            if view and vim.api.nvim_win_is_valid(win) then
                                pcall(vim.api.nvim_win_call, win, function()
                                    local line_count = vim.api.nvim_buf_line_count(args.buf)
                                    view.lnum = math.min(view.lnum, line_count)
                                    pcall(vim.fn.winrestview, view)
                                    vim.cmd("normal! zv")
                                end)
                            end
                        end
                    end)
                end,
            })
        end,
    },
    {
        "https://gitee.com/hello-luiswu/accelerated-jk.git",
        event = "VeryLazy",
        config = function ()
            return require("configs.ui_all").accjkConfig()
        end
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

            -- vim.keymap.set('n', '<a-j>', require('illuminate').goto_next_reference, { desc = "Move to next reference" })
            -- vim.keymap.set('n', '<a-k>', require('illuminate').goto_prev_reference, { desc = "Move to previous reference" })
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
        "https://gitee.com/nvim_lip/nvim-treesitter.git",
        branch = "main",
        lazy = false,
        dependencies = { { "https://gitee.com/yunduozhai/nvim-treesitter-textobjects.git", branch = "main" } },
        build = ":TSUpdate",
        config = function()
            require("configs.treesitter").treesitterConfig()
        end,
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
        "https://gitee.com/nvim_lip/gitsigns.nvim.git", tag = 'v1.0.2',
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
            require("configs.ui_all").interestingwordsConfig()
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
            disable_filetype = { "TelescopePrompt", "vim", "bitbake" },
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
        -- config = function()
        --     require('mason').setup({
        --         registries = {
        --             "https://gitee.com/nvim_lip/mason-registry.git",
        --         },
        --     })
        -- end
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
        "https://github.com/mfussenegger/nvim-lint.git",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("configs.lint").setup()
        end,
    },
    {
        "https://gitee.com/nvim_lip/conform.git",
        cmd = { "ConformInfo" },
        keys = require("configs.conform").keys,
        opts = require("configs.conform").opts,
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
        ft = { "markdown", "vimwiki", "Avante" },
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
            vim.keymap.set("n", "<leader>gv", function()
                vim.system({ "git", "remote", "-v" }, { text = true }, function(result)
                    vim.schedule(function()
                        vim.notify(
                            result.stdout ~= "" and result.stdout or result.stderr or "",
                            nil,
                            { title = "Git remotes" }
                        )
                    end)
                end)
            end, { desc = "Git remotes" })
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
            vim.keymap.set("n", "<leader>ha", function() harpoon:list():add()
                                    vim.notify("Harpoon add: " .. vim.fn.expand('%:.')) end)
            -- Toggle previous & next buffers stored within Harpoon list
            vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
            vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)

            vim.keymap.set("n", "<leader>fe", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
            vim.keymap.set("n", "<a-1>", function() harpoon:list():select(1) end)
            vim.keymap.set("n", "<a-2>", function() harpoon:list():select(2) end)
            vim.keymap.set("n", "<a-3>", function() harpoon:list():select(3) end)
            vim.keymap.set("n", "<a-4>", function() harpoon:list():select(4) end)
            vim.keymap.set("n", "<a-5>", function() harpoon:list():select(5) end)

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
            -- require('configs.ui_all').miniAnimate()
            require('configs.ui_all').miniIconsConfig()
            require('configs.edit').miniFileConfig()
            require("configs.edit").operatorsConfig()
            require("configs.indent").miniIndentInit()
            require('configs.edit').miniSurroundConfig()
            require('configs.edit').miniMoveConfig()
            require('configs.edit').miniKeymapConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/lspkind.nvim.git",
        opts = {},
    },
    {
        "https://gitee.com/nvim_lip/blink.cmp.git",
        dependencies = {
            { "https://gitee.com/nvim_lip/blink-cmp-yanky.git", },
            { "https://gitee.com/nvim_lip/blink-cmp-copilot.git", },
            { "https://gitee.com/nvim_lip/blink-ripgrep.nvim", version = "*", },
        },
        branch = "v1",
        -- event = "VeryLazy",
        event = { "BufReadPost", "BufNewFile" },
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
    },
    {
        "https://gitee.com/nvim_lip/other.nvim.git",
        branch = "main",
        cmd = { "Other", "OtherSplit", "OtherVSplit", "OtherTabNew" }, -- 懒加载：只在调用这些命令时加载
        config = function ()
            require('other-nvim').setup({
                mappings = {
                    "c", "python",
                }
            })
        end
    },
    {
        "https://gitee.com/nvim_lip/copilot.lua.git", -- 用于 providers='copilot'
        dependencies = {
            "https://gitee.com/nvim_lip/copilot-lsp.nvim.git", -- (optional) for NES functionality
        },
        enabled = function ()
            local v = vim.version()
            return (v.major == 0 and v.minor >= 11)
        end,
        config = function()
            require("configs.ai").copileConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/avante.nvim.git",
        branch = 'main',
        build = vim.fn.has("win32") ~= 0
            and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
            or function(plugin)
                require("configs.avante_build").build(plugin)
            end,
        event = "VeryLazy",
        version = false, -- 永远不要将此值设置为 "*"！永远不要！
        dependencies = {
            "https://gitee.com/suyelu/plenary.nvim",
            "https://gitee.com/nvim_lip/nui.nvim.git",
            "https://gitee.com/nvim_lip/copilot.lua.git", -- 用于 providers='copilot'
        },
        config = function()
            require("configs.ai").avanteConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/llm.nvim.git",
        dependencies = {
            "https://gitee.com/suyelu/plenary.nvim",
            "https://gitee.com/nvim_lip/nui.nvim.git",
        },
        cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
        opts = {
            exit_on_move = true, -- 是否在光标移动时退出会话
            enter_on_insert = false, -- 是否在进入插入模式时进入会话
            enable_cword_context = true, -- 是否将光标下的单词作为上下文的一部分
        },
        config = function()
            require("configs.llm").llmConfig()
        end,
        keys = function()
            return require("configs.llm").llmKeys
        end,
    }
}
