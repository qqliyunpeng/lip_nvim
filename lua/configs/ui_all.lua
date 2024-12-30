local M = {}

local map = vim.keymap.set

M.noiceConfig = function()
    local enable_conceal = false          -- Hide command text if true
    require('noice').setup({
        presets = { bottom_search = true }, -- The kind of popup used for /
        cmdline = {
            view = "cmdline",                 -- The kind of popup used for :
            format = {
                cmdline = { conceal = enable_conceal },
                search_down = { conceal = enable_conceal },
                search_up = { conceal = enable_conceal },
                filter = { conceal = enable_conceal },
                lua = { conceal = enable_conceal },
                help = { conceal = enable_conceal },
                input = { conceal = enable_conceal },
            }
        },

        -- false 打开下边的messages 多一行，如果是 true，则 messages 会 notify
        messages = { enabled = true },
        lsp = {
            hover = { enabled = false },
            signature = { enabled = false },
            progress = { enabled = true },
            message = { enabled = true },
            smart_move = { enabled = false },
        },
    })
end

M.whitespaceConfig = function()
    require("whitespace-nvim").setup({
        highlight = 'DiffDelete',
        ignored_filetypes = {
            'lazy',
            'help',
            'mason',
            'noice',
            'notify',
            'Trouble',
            'cmp_menu',
            'markdown',
            'NvimTree',
            'dashboard',
            'snacks_win',
            'snacks_notif',
            'snacks_terminal',
            'snacks_dashboard',
            'TelescopePrompt',
        },
        ignore_terimal = true,
        return_cursor = true,
    })
    vim.keymap.set('n', '<leader><Space>', require('whitespace-nvim').trim)
end

M.lspsagaConfig = function()
    require('lspsaga').setup({
        ui = {
            code_action = '󱠀',
        },
        finder = {
            max_height = 0.6,
            keys = {
                split  = "<C-x>",
                vsplit = "<C-v>",
                shuttle = "<leader>w", -- switch windows in opened windows
                toggle_or_open = "<CR>",
            }
        },
        outline = {
            keys = {
                toggle_or_jump = "<CR>",
            }
        },
        rename = {
            keys = {
                quit = "<C-c>"
            }
        },
    })

    map("n", "gf"        , "<cmd>Lspsaga finder def+ref+imp<CR>", { desc = "Show LSP methods search result"} )
    map("n", "<A-h>"     , "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover Documentation"} )
    map("n", "<A-l>"     , "<cmd>Lspsaga peek_definition<CR>", { desc = "Hover definition in hover"} )
    map("n", "<leader>cn", "<cmd>Lspsaga rename ++project<cr>", { desc = '[R]e[n]ame'} )
    map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc ='[C]ode [A]ction'} )
    map("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc ='goto [N]ext diagnostic'} )
    map("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { desc ='goto [P]rev diagnostic'} )
    map("n", "<F2>", "<cmd>Lspsaga outline<CR>", { desc ='Show outline'} )
end

M.snacksConfig = function()
    require('snacks').setup({
        indent = { enabled = false },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
        scope = { enabled = false },
        dashboard = {
            preset = {
                header = [[
██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z    
██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z       
██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z         
███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║           
╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝           
]],
                keys = {
                    { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                    { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                    { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                    { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                    { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                    { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                    { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
                    { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
                    { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                },
            },
        },
    })
end

return M

