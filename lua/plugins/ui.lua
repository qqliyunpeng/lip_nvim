return {
    {
        "https://gitee.com/nvim_lip/nvim-web-devicons.git",
        config = function ()
            require("configs.ui_all").deviconsConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/heirline-components.nvim.git",
        opts = require("configs.ui_all").componentsConfig()
    },
    {
        "https://gitee.com/nvim_lip/heirline.nvim.git",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "https://gitee.com/nvim_lip/heirline-components.nvim.git",
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
        "https://gitee.com/nvim_lip/nui.nvim.git",
        branch = 'main',
    },
    {
        "https://gitee.com/yunduozhai/noice.nvim.git",
        branch = 'main',
        tag = 'v4.10.0',
        dependencies = {
            "https://gitee.com/nvim_lip/nui.nvim.git",
        },
        config = function()
            return require("configs.ui_all").noiceConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/snacks.nvim.git",
        branch = 'main',
        priority = 1000,
        lazy = false,
        keys = function ()
            return require("configs.snacks").snacksKeys
        end,
        init = function ()
            return require("configs.snacks").snacksInit()
        end,
        config = function()
            return require("configs.snacks").snacksConfig()
        end,
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
        event = "BufReadPost",
        config = function()
            require('configs.ui_all').whitespaceConfig()
        end
    },
    {
        -- function tree in top
        "https://gitee.com/nvim_lip/lspsaga.nvim.git",
        event = "LspAttach",
        config = function()
            require('configs.ui_all').lspsagaConfig()
        end
    },
    {
        -- 选中行后，在选中的里边显示空格和Tab
        "https://gitee.com/nvim_lip/visual-whitespace.nvim.git",
        branch = 'compat-v10',
        event = 'BufReadPost',
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
    {
        "https://gitee.com/masa-laboratory/todo-comments.nvim.git",
        event = "VeryLazy",
        config = function ()
            require('configs.ui_all').todoConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/rainbow-delimiters.nvim.git",
        event = "BufReadPost",
    },
    {
        "https://gitee.com/nvim_lip/nvim-ufo.git",
        event = "VeryLazy",
        dependencies = {
            "https://gitee.com/yunduozhai/promise-async.git",
        },
        config = function()
            require("configs.ui_all").ufoConfig()
        end
    },
    {
        "https://gitee.com/nvim_lip/twilight.nvim.git",
        branch = 'main',
        event = "VeryLazy",
        opts = {}
    },
    {
        "https://gitee.com/nvim_lip/smear-cursor.nvim.git",
        branch = 'dev',
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            cursor_color = "#ff8800",
            stiffness = 0.8,
            trailing_stiffness = 0.2,
            trailing_exponent = 5,
            gamma = 1,
        },
    },
    {
        "https://gitee.com/nvim_lip/nvim-early-retirement.git",
        event = "VeryLazy",
        config = function ()
            require('early-retirement').setup({
                -- If a buffer has been inactive for this many minutes, close it.
                retirementAgeMins = 1,
                -- Minimum number of open buffers for auto-closing to become active. E.g.,
                -- by setting this to 4, no auto-closing will take place when you have 3
                -- or fewer open buffers. Note that this plugin never closes the currently
                -- active buffer, so a number < 2 will effectively disable this setting.
                minimumBufferNum = 20,
                -- Ignore buffers with unsaved changes. If false, the buffers will
                -- automatically be written and then closed.
                ignoreUnsavedChangesBufs = false,
                -- Show notification on closing. Works with plugins like nvim-notify.
                notificationOnAutoClose = true,

            })
        end
    }
}

