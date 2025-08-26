local M = {}
local use_ascii_icons = require("configs.icons").use_ascii_icons()

local map = vim.keymap.set

M.componentsConfig = function()
    return {icons = require("configs.icons").componentsIcons() }
end

M.noiceConfig = function()
    local enable_conceal = false          -- Hide command text if true
    require('noice').setup({
        presets = {
            bottom_search = false, -- The kind of popup used for /
            command_palette = true, -- position the cmdline and popupmenu together
            long_message_to_split = true,
        },
        cmdline = {
            view = "cmdline_popup",                 -- The kind of popup used for :
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
        views = {
            cmdline_popup = {
                position = {
                    row = "60%",
                    col = "50%", -- 屏幕水平方向居中
                },
                size = {
                    width = 60,      -- 宽度
                    height = "auto", -- 高度根据内容自动调整
                },
                border = {
                    style = "rounded",  -- 边框样式，可选："none", "single", "double", "rounded"
                    padding = { 0, 0 }, -- 内边距 {上下: 左右}
                },
                win_options = {
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                },
            },
        },

        -- false 打开下边的messages 多一行，如果是 true，则 messages 会 notify
        messages = { enabled = true },
        lsp = {
            hover = { enabled = false },
            signature = { enabled = false },
            progress = { enabled = true },
            message = { enabled = true },
            smart_move = { enabled = false },
            view_error = "messages",
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
            'blink-cmp-menu',
            'blink-cmp-documentation',
        },
        ignore_terimal = true,
        return_cursor = true,
    })
    vim.keymap.set('n', '<leader><Space>', require('whitespace-nvim').trim)
end

M.lspsagaConfig = function()
    require('lspsaga').setup({
        ui = {
            code_action = use_ascii_icons and " A" or '󱠀',
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
    map("n", "<F3>", "<cmd>Lspsaga outline<CR>", { desc ='Show outline'} )
end

local open_lazygit_with_refresh = function ()
    Snacks.lazygit()
    local exclude_filetypes = {
        "noice",
        "NvimTree",
        "snacks_notif",
        "snacks_terminal",
    }
    vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*lazygit*", -- 匹配 lazygit 终端
        once = true,
        callback = function ()
            vim.defer_fn(function()
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    local name = vim.api.nvim_buf_get_name(buf)

                    if name ~= "" then
                        local filetype = vim.fn.getbufvar(buf, "&filetype")

                        if not vim.tbl_contains(exclude_filetypes, filetype) then
                            require('gitsigns').detach(buf)
                            require('gitsigns').attach(buf)
                        end
                    end
                end
            end, 100) -- 延迟 100ms 防止懵逼的界面冲突
            vim.notify("ALL files refreshed.")
        end,
    })
end

M.snacksKeys = {
    -- { "<leader>z",  function() Snacks.zen() end, desc = "Toggle Zen Mode" },
    -- { "<leader>Z",  function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },
    -- { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    -- { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    -- { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
    -- { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    -- { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
    -- { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
    { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
    { "<leader>gg", function() open_lazygit_with_refresh() end, desc = "Lazygit" },
    { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    { "]]",         function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
    { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
    { "<leader>.",  function() Snacks.scratch() end, desc = "Open Scratch Buffer" },
    { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Buffer" },
}

M.snacksInit = function ()
    -- print("123")
    vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
            -- Setup some globals for debugging (lazy-loaded)
            _G.dd = function(...)
                Snacks.debug.inspect(...)
            end
            _G.bt = function()
                Snacks.debug.backtrace()
            end
            vim.print = _G.dd -- Override print to use snacks for `:=` command

            -- Create some toggle mappings
            Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
            Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
            Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
            Snacks.toggle.diagnostics():map("<leader>ud")
            Snacks.toggle.line_number():map("<leader>ul")
            Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
            Snacks.toggle.inlay_hints():map("<leader>uh")
        end,
    })
end

M.snacksConfig = function()
    local icons = require('configs.icons').snacksIcons()
    require('snacks').setup({
        indent = { enabled = false },
        picker = { enabled = false },
        bigfile = { enabled = true },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
        scope = { enabled = false },
        dashboard = {
            enabled = true,
            width = 50,
            row = nil, -- dashboard position. nil for center
            col = nil, -- dashboard position. nil for center
            -- pane_gap = 4, -- empty columns between vertical panes
            autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
            sections = {
                { section = "header" },
                { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
                { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
                { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                { section = "startup" },
            },
            preset = {
                keys = {
                    { icon = icons.find_file  , key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                    { icon = icons.new_file   , key = "n", desc = "New File", action = ":ene | startinsert" },
                    { icon = icons.find_text  , key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                    { icon = icons.recent     , key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                    { icon = icons.config     , key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                    { icon = icons.all_session, key = "w", desc = "All Session", action = ":Telescope persisted" },
                    { icon = icons.restore    , key = "s", desc = "Restore Session", action = ":SessionLoadLast" },
                    { icon = icons.extras     , key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
                    { icon = icons.lazy       , key = "l", desc = "Lazy", action = ":Lazy" },
                    { icon = icons.quit       , key = "q", desc = "Quit", action = ":qa" },
                },
                header = [[
██╗     ██╗██████╗ ██╗   ██╗██╗███╗   ███╗               
██║     ██║██╔══██╗██║   ██║██║████╗ ████║   /\_/\       
██║     ██║██████╔╝██║   ██║██║██╔████╔██║  ( o.o )      
██║     ██║██╔═══╝ ╚██╗ ██╔╝██║██║╚██╔╝██║  (  -  )っ    
███████╗██║██║      ╚████╔╝ ██║██║ ╚═╝ ██║   > ^ <   ~~~~
╚══════╝╚═╝╚═╝       ╚═══╝  ╚═╝╚═╝     ╚═╝               
                ]],
            },
        },
    })
end

M.visualWhitespaceConfig = function()
    local opts = {
        enabled = true,
        nl_char = '',
        cr_char = '←',
        tab_char = '→',
        space_char = '·',
        highlight = { link = "Visual" },
    }
    require('visual-whitespace').setup(opts)
end

M.whichKeyConfig = function()
    local wk = require('which-key')
    local opts = {
        preset = "helix",
        defaults = {},
        spec = {
            {
                mode = { "n", "v" },
                {"<leader>f", group = "Telescope" },
                {"<leader>b", group = "Buffer" },
                {"<leader>g", desc = "Git" },
                {"<leader>m", desc = "Marks" },
                {"<leader>w", desc = "LSP Workspace" },
                {"<leader>u", desc = "Disable/Dismiss/Toggle" },
                {"<leader><Space>", desc = "Remove the space ends" },
                {"<leader>K", hidden = true },
                {"<leader>ma", desc = "Bookmark picker" },
                {"<leader>mm", desc = "Bookmark Toggle" },
                {"<leader>mc", desc = "Bookmark Delete" },
                {"<leader>fc", desc = "Search with parameter" },
                {"<leader>fm", desc = "Mark list" },
                {"<leader>fe", desc = "Harpoon list" },
                {"<leader>a" , desc = "Harpoon add current file" },
                {"<leader>t" , desc = "Table and todo" },
                {"<leader>tm", desc = "Table mode toggle" },
                {"<leader>s" , desc = "Surround, search, replace" },
                {"<leader>c" , desc = "Code action, rename, comment" },
            }
        },
    }
    wk.setup(opts)
end

M.todoConfig = function()
    local todo = require('todo-comments')

    todo.setup()

    map("n", "]t", function()
        todo.jump_next({keywords = { "TODO", "NOTE", "FIX", "FIXME" }})
    end, { desc = "Next TODO/NOTE comment" })

    map("n", "[t", function()
        todo.jump_prev({keywords = { "TODO", "NOTE", "FIX", "FIXME" }})
    end, { desc = "Previous TODO/NOTE comment" })

    map("n", "<leader>to", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME,NOTE,PERF<CR>",
        { desc = "Open todo/fixed/note list" })
end

-- TODO: need relize session open with fold
M.ufoConfig = function()
    -- vim.o.foldcolumn = '1' -- '0' is not bad
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = false

    -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
    vim.keymap.set('n', 'zr', require('ufo').openAllFolds)
    vim.keymap.set('n', 'zm', require('ufo').closeAllFolds)

    local handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (' 󰁂 %d '):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if targetWidth > curWidth + chunkWidth then
                table.insert(newVirtText, chunk)
            else
                chunkText = truncate(chunkText, targetWidth - curWidth)
                local hlGroup = chunk[2]
                table.insert(newVirtText, {chunkText, hlGroup})
                chunkWidth = vim.fn.strdisplaywidth(chunkText)
                -- str width returned from truncate() may less than 2nd argument, need padding
                if curWidth + chunkWidth < targetWidth then
                    suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                end
                break
            end
            curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, {suffix, 'MoreMsg'})
        return newVirtText
    end
    require('ufo').setup({
        fold_virt_text_handler = handler,
        provider_selector = function(bufnr, filetype, buftype)
            return {'treesitter', 'indent'}
        end
    })
end

M.colorizerConfig = function ()
    local colorizer = require("colorizer")
    -- Exclude some filetypes from highlighting by using `!`
    colorizer.setup {
        'lua'; -- Highlight lua files, but customize some others.
    }

    Snacks.toggle({
        name = "colorizer",
        get = function()
            return colorizer.is_buffer_attached(0)
        end,
        set = function(_)
            vim.cmd("ColorizerToggle")
        end,
    }):map("<leader>uo")
end

local ascii_icons = {
    checkbox = {
        unchecked = { icon = '✘ ' },
        checked = { icon = '✔ ' },
        custom = {
            todo = { rendered = '◯ ' },
            important = {
                raw = '[~]',
                rendered = '* ',
                highlight = 'DiagnosticWarn',
            },
        },
    },
    heading  = {
        icons = { "", "", "", "", "", "" },
        signs = { '>' }
    },
    code = {
        render_modes = false,
        language = false,
        language_icon = false,
        language_name = false,
    },
    callout = {
        note      = { raw = '[!NOTE]',      rendered = '[Note]',      highlight = 'RenderMarkdownInfo',    category = 'github'   },
        tip       = { raw = '[!TIP]',       rendered = '[Tip]',       highlight = 'RenderMarkdownSuccess', category = 'github'   },
        important = { raw = '[!IMPORTANT]', rendered = '[Important]', highlight = 'RenderMarkdownHint',    category = 'github'   },
        warning   = { raw = '[!WARNING]',   rendered = '[Warning]',   highlight = 'RenderMarkdownWarn',    category = 'github'   },
        caution   = { raw = '[!CAUTION]',   rendered = '[Caution]',   highlight = 'RenderMarkdownError',   category = 'github'   },
        abstract  = { raw = '[!ABSTRACT]',  rendered = '[Abstract]',  highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        summary   = { raw = '[!SUMMARY]',   rendered = '[Summary]',   highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        tldr      = { raw = '[!TLDR]',      rendered = '[Tldr]',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        info      = { raw = '[!INFO]',      rendered = '[Info]',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        todo      = { raw = '[!TODO]',      rendered = '[Todo]',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        hint      = { raw = '[!HINT]',      rendered = '[Hint]',      highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
        success   = { raw = '[!SUCCESS]',   rendered = '[Success]',   highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
        check     = { raw = '[!CHECK]',     rendered = '[Check]',     highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
        done      = { raw = '[!DONE]',      rendered = '[Done]',      highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
        question  = { raw = '[!QUESTION]',  rendered = '[Question]',  highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
        help      = { raw = '[!HELP]',      rendered = '[Help]',      highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
        faq       = { raw = '[!FAQ]',       rendered = '[Faq]',       highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
        attention = { raw = '[!ATTENTION]', rendered = '[Attention]', highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
        failure   = { raw = '[!FAILURE]',   rendered = '[Failure]',   highlight = 'RenderMarkdownError',   category = 'obsidian' },
        fail      = { raw = '[!FAIL]',      rendered = '[Fail]',      highlight = 'RenderMarkdownError',   category = 'obsidian' },
        missing   = { raw = '[!MISSING]',   rendered = '[Missing]',   highlight = 'RenderMarkdownError',   category = 'obsidian' },
        danger    = { raw = '[!DANGER]',    rendered = '[Danger]',    highlight = 'RenderMarkdownError',   category = 'obsidian' },
        error     = { raw = '[!ERROR]',     rendered = '[Error]',     highlight = 'RenderMarkdownError',   category = 'obsidian' },
        bug       = { raw = '[!BUG]',       rendered = '[Bug]',       highlight = 'RenderMarkdownError',   category = 'obsidian' },
        example   = { raw = '[!EXAMPLE]',   rendered = '[Example]',   highlight = 'RenderMarkdownHint' ,   category = 'obsidian' },
        quote     = { raw = '[!QUOTE]',     rendered = '[Quote]',     highlight = 'RenderMarkdownQuote',   category = 'obsidian' },
        cite      = { raw = '[!CITE]',      rendered = '[Cite]',      highlight = 'RenderMarkdownQuote',   category = 'obsidian' },
    }
}

M.markdownConfig = function ()
    local mk = require('render-markdown')

    local opts = {
        file_types = { 'markdown', 'vimwiki' },
        heading = {
            position = 'inline',
            sign = false,
            width = 'block',
            min_width = 0,
            border_virtual = true,
        },
        code = {
            sign = false,
            width = 'block',
            min_width = 45,
            -- left_pad = 0,
            -- right_pad = 2,
            style = 'normal',
        },
        dash = { width = 79, },
        checkbox = {
            custom = {
                important = {
                    raw = '[~]',
                    rendered = '󰓎 ',
                    highlight = 'DiagnosticWarn',
                },
            },
        },
        quote = { repeat_linebreak = false },
    }

    if use_ascii_icons then
        opts = vim.tbl_deep_extend("force", opts, ascii_icons)
    end

    mk.setup(opts)
end

return M

