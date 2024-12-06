return {
    {
        "https://gitee.com/yunduozhai/nvim-notify.git",
        config = function()
            require('notify').setup({
                background_colour = "#000000",
                stages = "slide",
                timeout = 3000,
                top_down = true
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
            require('illuminate').configure()
        end
    },
    {
        "https://gitee.com/rulei_mirror/vim-oscyank.git",
        config = true,
    },
    {
        'https://gitee.com/oyaay/telescope.nvim.git', tag = '0.1.8',
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        cmd = "Telescope",
        config = function()
            require('telescope').setup {
                defaults = {
                    -- layout_strategy = "bottom_pane",
                    path_display = {
                        "absolute",
                        truncate = 3,
                    },
                    prompt_prefix = "   ",
                    selection_caret = " ",
                    entry_prefix = " ",
                    sorting_strategy = "ascending",
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width = 0.55,
                        },
                        width = 0.90,
                        height = 0.40,
                    },
                    mappings = {
                        n = { ["q"] = require("telescope.actions").close },
                    },
                },
                layout_config = {
                    bottom = {
                        height = 0.1,
                    },
                },
            }
        end
    },
    {
        "https://gitee.com/zgpio/nvim-treesitter.git",
        event = { "BufReadPost", "BufNewFile" },
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        build = ":TSUpdate",
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end,
    },
    {
        "https://gitee.com/yunduozhai/gitsigns.nvim.git",
        event = "User FilePost",
        config = true,
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
                colors = { '#aeee00', '#ff0000', '#0000ff', '#b88823', '#ffa724', '#ff2c4b'  },
                search_count = true,
                navigation = true,
                scroll_center = true,
                search_key = "n",
                --cancel_search_key = "<leader>M",
                color_key = "<leader>e",
                --cancel_color_key = "<leader>K",
                select_mode = "loop",  -- random or loop
            }
        end
    },
    {
        'https://gitee.com/dragon-teng140806/nvim-colorizer.lua.git',
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
    { -- override nvim-autopairs plugin
        "windwp/nvim-autopairs",
        -- event = "InsertEnter",
        -- opts = {
            -- fast_wrap = {},
            -- disable_filetype = { "TelescopePrompt", "vim" },
        -- },
        -- config = function(_, opts)
        --config = function()
        config = function(plugin, opts)
            local npairs = require("nvim-autopairs")
            local Rule = require("nvim-autopairs.rule")
            local cond = require("nvim-autopairs.conds")

            npairs.setup({})
            function rule2(a1,ins,a2,lang)
                npairs.add_rule(   
                Rule(ins, ins, lang) 
                :with_pair(function(opts) return a1..a2 == opts.line:sub(opts.col - #a1, opts.col + #a2 - 1) end)
                :with_move(cond.none())
                :with_cr(cond.none())
                :with_del(function(opts)
                    local col = vim.api.nvim_win_get_cursor(0)[2]
                    return a1..ins..ins..a2 == opts.line:sub(col - #a1 - #ins + 1, col + #ins + #a2) -- insert only works for #ins == 1 anyway
                end)
                )
            end
            rule2('(','*',')','ocaml')
            rule2('(*',' ','*)','ocaml')
            rule2('(',' ',')')

            --[[
            npairs.add_rules({
                Rule("(", ")")
                    :with_pair(function() return true end)
                    :with_move(function(options)
                        return options.prev_char:match("%s") ~= nil
                    end),
                Rule("( ", ")")
                    :with_pair(function() return true end)
                    :with_move(function(options)
                        return options.prev_char:match("%s") ~= nil
                    end)
                    :use_key(")"),
            })
            ]]

--[[
            local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
            -- npairs.add_rules ({
            npairs.add_rules {
                -- Rule for a pair with left-side ' ' and right side ' '
                Rule(' ', ' ')
                -- Pair will only occur if the conditional function returns true
                :with_pair(function(opts)
                    -- We are checking if we are inserting a space in (), [], or {}
                    local pair = opts.line:sub(opts.col - 1, opts.col)
                    return vim.tbl_contains({
                        brackets[1][1] .. brackets[1][2],
                        brackets[2][1] .. brackets[2][2],
                        brackets[3][1] .. brackets[3][2]

                    }, pair)
                end)
                :with_move(cond.none())
                :with_cr(cond.none())
                -- We only want to delete the pair of spaces when the cursor is as such: ( |  )
                :with_del(function(opts)
                    local col = vim.api.nvim_win_get_cursor(0)[2]
                    local context = opts.line:sub(col - 1, col + 2)
                    return vim.tbl_contains({
                        brackets[1][1] .. '  ' .. brackets[1][2],
                        brackets[2][1] .. '  ' .. brackets[2][2],
                        brackets[3][1] .. '  ' .. brackets[3][2]
                    }, context)
                end)
            -- })
            }
            -- For each pair of brackets we will add another rule
            for _, bracket in pairs(brackets) do
                npairs.add_rules {
                    -- Each of these rules is for a pair with left-side '( ' and right-side ' )' for each bracket type
                    Rule(bracket[1] .. ' ', ' ' .. bracket[2])
                    :with_pair(cond.none())
                    :with_move(function(opts) return opts.char == bracket[2] end)
                    :with_del(cond.none())
                    :use_key(bracket[2])
                    -- Removes the trailing whitespace that can occur without this
                    :replace_map_cr(function(_) return '<C-c>2xi<CR><C-c>O' end)
                }
            end
]]
        --     npairs.add_rules({
        --         -- {
        --             -- specify a list of rules to add
        --             Rule(" ", " "):with_pair(function(options)
        --                 local pair = options.line:sub(options.col - 1, options.col)
        --                 return vim.tbl_contains({ "()", "[]", "{}" }, pair)
        --             end),
        --             Rule("( ", " )")
        --                 :with_pair(function()
        --                     return false
        --                 end)
        --                 :with_move(function(options)
        --                     return options.prev_char:match(".%)") ~= nil
        --                 end)
        --                 :use_key(")"),
        --             Rule("{ ", " }")
        --                 :with_pair(function()
        --                     return false
        --                 end)
        --                 :with_move(function(options)
        --                     return options.prev_char:match(".%}") ~= nil
        --                 end)
        --                 :use_key("}"),
        --             Rule("[ ", " ]")
        --                 :with_pair(function()
        --                     return false
        --                 end)
        --                 :with_move(function(options)
        --                     return options.prev_char:match(".%]") ~= nil
        --                 end)
        --                 :use_key("]"),
        --         -- },
        -- })
        end,
    },
}


