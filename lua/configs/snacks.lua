local M = {}

local db_path = os.getenv('HOME') .. '/.local/share/nvim/databases'

local picker_exclude = {
    "*.d", "*.o", "*.zip", "*.tar", "*.tar.gz",
    "*.tgz", "*.tar.bz2", "*.tbz2", "*.tar.xz",
    "*.txz", "*.gz", "*.bz2", "*.xz", "*.zst",
    "*.7z", "*.rar", "*.a1", "*.s1", "*.snalyzerinfo", "tags", "cscope.out",
}

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
    { "<leader>gb", function() Snacks.git.blame_line() end,     desc = "View Git blame" },
    { "<leader>gl", function() Snacks.lazygit.log_file() end,   desc = "View Git log(current)" },
    { "<leader>gg", function() open_lazygit_with_refresh() end, desc = "Lazygit" },
    { "<leader>gL", function() Snacks.lazygit.log() end,        desc = "View Git log" },
    { "<leader>un", function() Snacks.notifier.hide() end,      desc = "Dismiss All Notifications" },
    { "]]", function() Snacks.words.jump(vim.v.count1) end,  desc = "Next Reference", mode = { "n", "t" } },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
    { "<leader>.",   function() Snacks.scratch() end,          desc = "Open Scratch Buffer" },
    { "<leader>S",   function() Snacks.scratch.select() end,   desc = "Select Scratch Buffer" },
    { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Buffer" },
    { "<leader>fu",  function() Snacks.picker.undo() end,      desc = "Find undo history" },
    { "<leader>fc",  function() Snacks.picker.grep_word() end, desc = "Search cur word", mode = { "n", "x" } },
    { "<leader>fl",  function() Snacks.picker.lines() end,     desc = "Search Buffer linse" },
}

function M.snacksInit()
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
            Snacks.toggle.inlay_hints():map("<leader>uh")
        end,
    })
end

local function smart_layout()
    if vim.o.columns >= 180 then
        return "wide_85"
    else
        return "vertical_85"
    end
end

local picker_layouts = {
    wide_85 = {
        layout = {
            box = "horizontal", -- 左右布局
            width = 0.85,       -- 整体宽度 85%
            height = 0.74,      -- 整体高度
            min_width = 120,
            {
                box = "vertical",
                border = "rounded",
                title = "{title} {live} {flags}",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
            },
            { win = "preview", title = "{preview}", border = "rounded", width = 0.57 },
        },
    },
    vertical_85 = {
        layout = {
            box = "vertical",
            width = 0.85,      -- 整体宽度 85%
            height = 0.74,     -- 整体高度
            min_height = 30,
            border = "rounded",
            title = "{title} {live} {flags}",
            title_pos = "center",
            { win = "input", height = 1, border = "bottom" },
            { win = "list", border = "none" },
            { win = "preview", title = "{preview}", height = 0.68, border = "top"},
        },
    }
}

local snacksKeys = {
    input = {
        keys = {
            ["<Down>"] = { "history_forward", mode = { "i", "n" } },
            ["<Up>"] = { "history_back", mode = { "i", "n" } },
            ["<C-c>"] = { "close", mode = { "i", "n" } },
            ["<C-x>"] = { "edit_split", mode = { "i", "n" } },
            ["<C-j>"] = { "list_cycle_down", mode = { "i", "n" } },
            ["<C-k>"] = { "list_cycle_up", mode = { "i", "n" } },
        }
    },
    list = {
        keys = {
            ["<C-c>"] = { "close", mode = { "i", "n" } },
            ["<C-x>"] = { "edit_split", mode = { "i", "n" } },
            ["<c-j>"] = "list_cycle_down",
            ["<c-k>"] = "list_cycle_up",
        }
    },
    preview = {
        keys = {
            ["<C-c>"] = { "close", mode = { "i", "n" } },
            ["<C-x>"] = { "edit_split", mode = { "i", "n" } },
        }
    },
}

function M.snacksConfig()
    local icons = require('configs.icons').snacksIcons()
    require('snacks').setup({
        indent    = { enabled = false },
        bigfile   = { enabled = true },
        image     = { enabled = false },
        words     = { enabled = true },
        scope     = { enabled = false },
        quickfile = { enabled = true },
        statuscolumn = { enabled = true },
        picker    = {
            enabled = true,
            layout  = smart_layout,
            layouts = picker_layouts,
            prompt  = icons.prompt,
            ui_select = false,
            formatters = { file = { filename_first = true, truncate = 40 } },
            sources = {
                files = { exclude = picker_exclude },
                grep = { exclude = picker_exclude },
                grep_word = { exclude = picker_exclude },
            },
            win = snacksKeys,
            db  = { sqlite3_path = db_path .. '/snacks_history.sqlite3', }
        },
        scroll = {
            enabled = true,
            animate = {
                duration = { step = 15, total = 150 },
                easing = "outSine",
            },
            animate_repeat = {
                delay = 100,
                duration = { step = 5, total = 50 },
                easing = "outSine",
            },
            -- what buffers to animate
            filter = function(buf)
                return vim.g.snacks_scroll ~= false and vim.b[buf].snacks_scroll ~= false and vim.bo[buf].buftype ~= "terminal"
            end,
        },
        notifier  = {
            enabled = true,
            timeout = 4000,
            width = { min = 40, max = 0.7 },
        },
        dashboard = {
            enabled = true,
            width = 50,
            row = nil, -- dashboard position. nil for center
            col = nil, -- dashboard position. nil for center
            -- pane_gap = 4, -- empty columns between vertical panes
            autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
            sections = {
                { section = "header" },
                { icon = icons.keymaps, title = "Keymaps", section = "keys", indent = 2, padding = 1 },
                { icon = icons.recent_files, title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
                { icon = icons.projects, title = "Projects", section = "projects", indent = 2, padding = 1 },
                { section = "startup" },
            },
            preset = {
                keys = {
                    { icon = icons.find_file  , key = "f", desc = "Find File",       action = ":lua Snacks.dashboard.pick('files')" },
                    { icon = icons.new_file   , key = "n", desc = "New File",        action = ":ene | startinsert" },
                    { icon = icons.find_text  , key = "w", desc = "Find Text",       action = ":lua Snacks.dashboard.pick('live_grep')" },
                    { icon = icons.recent     , key = "r", desc = "Recent Files",    action = ":lua Snacks.dashboard.pick('oldfiles')" },
                    { icon = icons.config     , key = "c", desc = "Config",          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                    { icon = icons.all_session, key = "p", desc = "Projects",        action = ":Telescope persisted" },
                    { icon = icons.restore    , key = "s", desc = "Restore Session", action = ":SessionLoadLast" },
                    { icon = icons.extras     , key = "x", desc = "Lazy Extras",     action = ":LazyExtras" },
                    { icon = icons.lazy       , key = "l", desc = "Lazy",            action = ":Lazy" },
                    { icon = icons.quit       , key = "q", desc = "Quit",            action = ":qa" },
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

    Snacks.picker.actions.list_cycle_down = function(picker)
        -- local row = picker.list.cursor or 0
        -- vim.print(string.format("%d/%d", row, picker.list:count()))
        if picker.list.cursor == picker.list:count() then
            picker.list:move(1, true)
        else
            picker.list:move(vim.v.count1)
        end
    end
    Snacks.picker.actions.list_cycle_up = function(picker)
        if picker.list.cursor == 1 then
            picker.list:move(picker.list:count(), true)
        else
            picker.list:move(-vim.v.count1)
        end
    end

    -- In lazygit terminal, remap <C-j>/<C-k> to j / k
    vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*lazygit*",
        callback = function(args)
            local buf = args.buf
            vim.keymap.set("t", "<C-j>", "j", { buffer = buf, noremap = true, silent = true })
            vim.keymap.set("t", "<C-k>", "k", { buffer = buf, noremap = true, silent = true })
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopeFindPre",
        callback = function()
            Snacks.scroll.enable()
        end,
    })
    vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function(args)
            local buf = args.buf
            if vim.bo[buf].filetype:match("^snacks_picker_preview") then
                Snacks.scroll.enable()
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "BufWinLeave", "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
                    if ft:match("^Telescope") or ft:match("^snacks_picker_preview") then
                        return -- 仍有 telescope/snacks picker 窗口，跳出
                    end
                end
                Snacks.scroll.disable()
            end)
        end,
    })
end

return M
