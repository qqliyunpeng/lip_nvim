return {
    {
        "https://gitee.com/yunduozhai/nvim-web-devicons.git",
        config = true,
    },
    {
        "https://gitee.com/nvim_lip/heirline-components.nvim.git",
        opts = {
            icons = {
                ActiveLSP = "",
                ActiveTS = "",
                ArrowLeft = "",
                ArrowRight = "",
                Bookmarks = "",
                BufferClose = "󰅖",
                DapBreakpoint = "",
                DapBreakpointCondition = "",
                DapBreakpointRejected = "",
                DapLogPoint = ".>",
                DapStopped = "󰁕",
                Debugger = "",
                DefaultFile = "󰈙",
                Diagnostic = "󰒡",
                DiagnosticError = "",
                DiagnosticHint = "󰌵",
                DiagnosticInfo = "󰋼",
                DiagnosticWarn = "",
                Ellipsis = "…",
                Environment = "",
                FileNew = "",
                FileModified = "",
                FileReadOnly = "",
                FoldClosed = "",
                FoldOpened = "",
                FoldSeparator = " ",
                FolderClosed = "",
                FolderEmpty = "",
                FolderOpen = "",
                Git = "󰊢",
                GitAdd = "",
                GitBranch = "",
                GitChange = "",
                GitConflict = "",
                GitDelete = "",
                GitIgnored = "◌",
                GitRenamed = "➜",
                GitSign = "▎",
                GitStaged = "✓",
                GitUnstaged = "✗",
                GitUntracked = "★",
                LSPLoaded = "",
                LSPLoading1 = "",
                LSPLoading2 = "󰀚",
                LSPLoading3 = "",
                MacroRecording = "",
                Package = "󰏖",
                Paste = "󰅌",
                Refresh = "",
                Run = "󰑮",
                Search = "",
                Selected = "❯",
                Session = "󱂬",
                Sort = "󰒺",
                Spellcheck = "󰓆",
                Tab = "󰓩",
                TabClose = "󰅙",
                Terminal = "",
                Window = "",
                WordFile = "󰈭",
                Test = "󰙨",
                Docs = "",
            }
        }
    },
    {
        "https://gitee.com/yunduozhai/heirline.nvim.git",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "heirline-components.nvim"
        },
        config = function()
            return require("configs.heirline").config()
        end
    },
    {
        'https://gitee.com/yunduozhai/bufferline.nvim.git',
        version = "*",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = 'nvim-web-devicons',
        config = function()
            local opts = require('configs.bufferline')
            require('bufferline').setup(opts)
        end
    },
    {
        --  [better ui elements]
        "https://gitee.com/yunduozhai/dressing.nvim.git",
        event = "VeryLazy",
        opts = {
            input = { default_prompt = "➤ " },
            select = { backend = { "telescope", "builtin" } },
        }
    },
    {
        "https://gitee.com/yunduozhai/noice.nvim.git",
        config = function()
            return require("configs.ui_all").noiceConfig()
        end
    },
    {
        -- indent 的动画效果
        -- text object ii ai [i ]i
        "https://gitee.com/yunduozhai/mini.indentscope.git",
        version = false,
        init = function()
            return require("configs.indent").miniIndentInit()
        end,
    },
    {
        "https://gitee.com/sunn4mirror/snacks.nvim.git",
        priority = 1000,
        lazy = false,
        config = function()
            return require("configs.ui_all").snacksConfig()
        end
    },
    {
        -- 函数缩进前的条
        "https://gitee.com/yunduozhai/indent-blankline.nvim.git",
        event = "VeryLazy",
        main = "ibl",
        opts = function()
            return require("configs.indent").blanklineConfig()
        end,
    },
    {
        -- 显示并去掉空格
        "https://gitee.com/nvim_lip/whitespace.nvim.git",
        event = "VeryLazy",
        config = function()
            require('configs.ui_all').whitespaceConfig()
        end
    },
    {
        -- function tree in top
        "https://gitee.com/yunduozhai/lspsaga.nvim.git",
        event = "VeryLazy",
        config = function()
            require('configs.ui_all').lspsagaConfig()
        end
    },
    {
        -- 选中行后，在选中的里边显示空格和Tab
        "https://gitee.com/nvim_lip/visual-whitespace.nvim.git",
        branch = 'main',
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require('configs.ui_all').visualWhitespaceConfig()
        end
    },
    {
        -- 在最上边显示当前函数的函数名字
        "https://gitee.com/yunduozhai/nvim-treesitter-context.git",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            max_lines = 5,
        }
    },
    {
        "https://gitee.com/yunduozhai/which-key.nvim.git", branch = "main",
        event = "VeryLazy",
        opts_extend = { "spec" },
        keys = {
            {
                "<leader>?",
                function()
                    require('which-key').show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
        config = function ()
            require('configs.ui_all').whichKeyConfig()
        end
    },
}

