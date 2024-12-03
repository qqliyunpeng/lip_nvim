return {
    {
        "karb94/neoscroll.nvim",
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
                easing = 'linear',           -- Default easing function
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
        "folke/flash.nvim",
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
        "ahmedkhalf/project.nvim",
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
        "ethanholz/nvim-lastplace",
        config = function()
            require('nvim-lastplace').setup()
        end
    },
    {
        "rhysd/accelerated-jk",
        keys = {
            {"j", "<Plug>(accelerated_jk_gj)" },
            {"k", "<Plug>(accelerated_jk_gk)" },
        },
    },
    {
        "RRethy/vim-illuminate",
        event = "VeryLazy",
        config = function()
            require('illuminate').configure()
        end
    },
    {
        "ojroques/vim-oscyank",
        config = true,
    },
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.8',
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        cmd = "Telescope",
    },
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPost", "BufNewFile" },
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        build = ":TSUpdate",
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        event = "User FilePost",
        config = true,
    },
    {
        -- file managing , picker etc
        "nvim-tree/nvim-tree.lua",
        cmd = { "NvimTreeToggle", "NvimTreeFocus" },
        opts = function()
            return require "configs.nvimtree"
        end,
    },
    {
        'Mr-LLLLL/interestingwords.nvim',
        config = function()
            require('interestingwords').setup{
                colors = { '#aeee00', '#ff0000', '#0000ff', '#b88823', '#ffa724', '#ff2c4b'  },
                search_count = true,
                navigation = true,
                scroll_center = true,
                search_key = "n",
                --cancel_search_key = "<leader>M",
                color_key = "<leader>e",
                --cancel_color_key = "<leader>K",
                select_mode = "random",  -- random or loop
            }
        end
    },
    {
        'norcalli/nvim-colorizer.lua',
        config = function()
            -- Exclude some filetypes from highlighting by using `!`
            require ('colorizer').setup {
                '*'; -- Highlight all files, but customize some others.
                -- '!vim'; -- Exclude vim from highlighting.
                -- Exclusion Only makes sense if '*' is specified!
            }
            -- vim.cmd('ColorizerAttachToBuffer')
        end
    },
}

