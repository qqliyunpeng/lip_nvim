local M = {}

local db_path = vim.fn.stdpath('data') .. '/databases'

local picker_exclude = {
    "*.d", "*.o", "*.zip", "*.tar", "*.tar.gz",
    "*.tgz", "*.tar.bz2", "*.tbz2", "*.tar.xz",
    "*.txz", "*.gz", "*.bz2", "*.xz", "*.zst",
    "*.7z", "*.rar", "*.a1", "*.s1", "*.snalyzerinfo", "tags", "cscope.out",
}

function M.preferDevicons()
    local snacks_icon = Snacks.util.icon
    local devicons = require('nvim-web-devicons')

    Snacks.util.icon = function(name, category, opts)
        local icon, hl
        if category == "filetype" then
            icon, hl = devicons.get_icon_by_filetype(name, { default = false })
        elseif category == "file" or category == "extension" then
            local extension = category == "extension" and name or name:match("%.(%w+)$")
            icon, hl = devicons.get_icon(name, extension, { default = false })
        end

        if icon then
            return icon, hl
        end
        return snacks_icon(name, category, opts)
    end
end

local open_lazygit_with_refresh = function ()
    Snacks.lazygit()
    local exclude_filetypes = {
        "noice",
        "snacks_picker_list",
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


M.keys = {
    { "<leader>gb", function() Snacks.git.blame_line() end,     desc = "View Git blame" },
    { "<leader>gl", function() Snacks.lazygit.log_file() end,   desc = "View Git log(current)" },
    { "<leader>gg", function() open_lazygit_with_refresh() end, desc = "Lazygit" },
    { "<leader>gL", function() Snacks.lazygit.log() end,        desc = "View Git log" },
    { "<leader>un", function() Snacks.notifier.hide() end,      desc = "Dismiss All Notifications" },
    { "<leader>.",   function() Snacks.scratch() end,          desc = "Open Scratch Buffer" },
    { "<leader>S",   function() Snacks.scratch.select() end,   desc = "Select Scratch Buffer" },
    { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Buffer" },
    { "<leader>fu",  function() Snacks.picker.undo() end,      desc = "Find undo history" },
    -- { "<leader>fc",  function() Snacks.picker.grep_word() end, desc = "Search cur word", mode = { "n", "x" } },
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

-- :q 关闭最后一个普通文件窗口时，不能只留下 snacks.terminal 窗口/后台 job。
-- 平时切换终端仍保留它，只有编辑窗口即将全部退出时才清理。
local function close_orphaned_snacks_terminals()
    local current_win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(current_win).relative ~= ""
        or vim.bo[vim.api.nvim_win_get_buf(current_win)].buftype ~= ""
    then
        return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
            return
        end
    end
    local normal_windows = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local config = vim.api.nvim_win_get_config(win)
        local buf = vim.api.nvim_win_get_buf(win)
        if config.relative == "" and vim.bo[buf].buftype == "" then
            normal_windows = normal_windows + 1
        end
    end

    if normal_windows ~= 1 then
        return
    end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" and vim.bo[buf].filetype == "snacks_terminal" then
            pcall(vim.api.nvim_win_close, win, true)
        end
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
                title = { { "{title} {live} {flags}", "SnacksPickerBoxTitle" } },
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
            title = { { "{title} {live} {flags}", "SnacksPickerBoxTitle" } },
            title_pos = "center",
            { win = "input", height = 1, border = "bottom" },
            { win = "list", border = "none" },
            { win = "preview", title = "{preview}", height = 0.68, border = "top"},
        },
    }
}

-- 按 picker 窗口的视觉位置切换焦点：从左到右，同列再从上到下。
-- 这样宽屏布局会按“输入 -> 列表 -> 预览”切换，竖屏布局会按
-- “输入 -> 列表 -> 预览”的上到下顺序切换，而不是使用 Snacks 默认的
-- input -> preview -> list 顺序。
local function cycle_picker_window(picker)
    local windows = {}
    for _, pane in ipairs({ picker.input, picker.list, picker.preview }) do
        local win = pane.win.win
        if win and vim.api.nvim_win_is_valid(win) then
            table.insert(windows, win)
        end
    end
    if #windows == 0 then
        return
    end

    table.sort(windows, function(a, b)
        local a_row, a_col = unpack(vim.api.nvim_win_get_position(a))
        local b_row, b_col = unpack(vim.api.nvim_win_get_position(b))
        if a_col == b_col then
            return a_row < b_row
        end
        return a_col < b_col
    end)

    local current = vim.api.nvim_get_current_win()
    for index, win in ipairs(windows) do
        if win == current then
            vim.api.nvim_set_current_win(windows[index % #windows + 1])
            return
        end
    end
    vim.api.nvim_set_current_win(windows[1])
end

local picker_win = {
    input = {
        keys = {
            ["<Down>"] = { "history_forward", mode = { "i", "n" } },
            ["<Up>"] = { "history_back", mode = { "i", "n" } },
            ["<C-c>"] = { "cancel", mode = { "i", "n" } },
            ["<C-x>"] = { "edit_split", mode = { "i", "n" } },
            ["<C-j>"] = { "list_cycle_down", mode = { "i", "n" } },
            ["<C-k>"] = { "list_cycle_up", mode = { "i", "n" } },
            ["<a-w>"] = { "cycle_picker_window", mode = { "i", "n" } },
        }
    },
    list = {
        keys = {
            ["<C-c>"] = { "cancel", mode = { "i", "n" } },
            ["<C-x>"] = { "edit_split", mode = { "i", "n" } },
            ["<c-j>"] = "list_cycle_down",
            ["<c-k>"] = "list_cycle_up",
            ["<a-w>"] = "cycle_picker_window",
        }
    },
    preview = {
        keys = {
            ["<C-c>"] = { "cancel", mode = { "i", "n" } },
            ["<C-x>"] = { "edit_split", mode = { "i", "n" } },
            ["<a-w>"] = "cycle_picker_window",
        }
    },
}

-- picker:find() 默认会 trim 输入框首尾空格，这里还原成输入框原文，
-- 让空格按普通字符参与匹配（<leader>fw / <leader>fc 共用）
local function keep_search_spaces(picker, filter)
    filter.search = picker.input.filter.search
end

-- grep 类 picker 标题栏上的 rg 参数提示（<leader>fw / <leader>fc 共用）
local grep_hint = "-- 后接 rg 参数：-s 区分大小写 · -w 全词"

function M.snacksConfig()
    local icons = require('configs.icons').snacksIcons()
    require('snacks').setup({
        indent    = { enabled = false },
        bigfile   = { enabled = true },
        image     = { enabled = false },
        -- 关闭：引用高亮统一由 vim-illuminate 负责（IlluminatedWord* 组 + 光标在关键字上才亮）。
        -- 原来 snacks.words 会在 CursorMoved 后调 document_highlight()，与 illuminate 重复请求、
        -- 双重高亮，且它自己不判断光标是否在标识符上（clangd 会回退到前一个表达式）。
        words     = { enabled = false },
        scope     = { enabled = false },
        quickfile = { enabled = true },
        statuscolumn = { enabled = true },
        picker    = {
            enabled = true,
            layout  = smart_layout,
            layouts = picker_layouts,
            actions = { cycle_picker_window = cycle_picker_window },
            prompt  = icons.prompt,
            ui_select = false,
            formatters = { file = { filename_first = true, truncate = 40 } },
            sources = {
                files = { exclude = picker_exclude },
                grep = {
                    exclude = picker_exclude,
                    -- 默认按字面搜索（snacks 会据此给 rg 传 --fixed-strings），
                    -- 需要正则时在 picker 里按 <a-r> 切回 regex 模式
                    regex = false,
                    filter = { transform = keep_search_spaces },
                    title = "Grep · " .. grep_hint,
                },
                grep_word = {
                    exclude = picker_exclude,
                    args = {},
                    filter = { transform = keep_search_spaces },
                    title = "Grep Word · " .. grep_hint,
                },
                -- 替代原 nvim-tree：dotfiles 可见(hidden)、git ignored 可见(ignored)，
                -- 仍过滤 .git/.vscode/build 等目录；宽度和 configs/edgy.lua 的
                -- explorer_width 一致，edgy 捕获后由 edgebar 接管尺寸。
                explorer = {
                    hidden = true,
                    ignored = true,
                    exclude = { ".git", ".vscode", "build", ".gitignore", "*.out", "tags" },
                    layout = { preset = "sidebar", preview = false, layout = { width = 30 } },
                    -- Esc 不关闭 explorer（默认绑在 cancel 上会直接关掉侧栏）：
                    -- 禁用后输入框里 Esc 回到 Normal 模式，关闭仍用 q / <C-c> / F2
                    win = {
                        input = { keys = { ["<esc>"] = false } },
                        list = { keys = { ["<esc>"] = false } },
                    },
                    on_show = function(picker)
                        require("configs.explorer").setup_highlights()
                        require("configs.explorer").sync_highlights()
                        -- 等挂载/布局的延迟回调结束后再同步一次，首次打开无需额外切焦点。
                        vim.schedule(require("configs.explorer").sync_highlights)
                    end,
                    -- 原 nvim-tree TreeClose 事件触发的 avante 刷新，改挂在 picker 的 on_close
                    on_close = function()
                        require("configs.avante_refresh").refresh({ require_explorer_closed = true })
                    end,
                },
            },
            win = picker_win,
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
            -- Snacks 默认会在通知左右各增加一个真实的窗口单元格；
            -- 右侧单元格会显示成“不是空格的灰色背景”。
            padding = false,
        },
        dashboard = {
            enabled = true,
            width = 64,
            formats = { header = { "%s", align = "left" } },
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

    -- In lazygit terminal, pass <C-h>/<C-j>/<C-k>/<C-l> to lazygit
    vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*lazygit*",
        callback = function(args)
            local buf = args.buf
            vim.keymap.set("t", "<C-j>", "<C-j>", { buffer = buf, noremap = true, silent = true })
            vim.keymap.set("t", "<C-k>", "<C-k>", { buffer = buf, noremap = true, silent = true })
            vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = buf, noremap = true, silent = true })
            vim.keymap.set("t", "<C-h>", "<C-h>", { buffer = buf, noremap = true, silent = true })
        end,
    })

    vim.api.nvim_create_autocmd("QuitPre", {
        group = vim.api.nvim_create_augroup("LipSnacksTerminalCleanup", { clear = true }),
        callback = close_orphaned_snacks_terminals,
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

    -- 原 configs/nvimtree.lua 加载时的副作用：注册 QuitPre 关侧栏逻辑。
    -- snacks 是 lazy=false 常驻插件，放这里比原来（首次打开树才注册）更早生效。
    require("configs.ai").setup_quit_sidebars()
end

return M
