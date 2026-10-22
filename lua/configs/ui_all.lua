local M = {}
local use_ascii_icons = require("configs.icons").use_ascii_icons()

local map = vim.keymap.set

-- 当前光标行下当前行号的颜色设置
function M.modicatorConfig()
    -- 加载 Modicator 以及各模式对应的颜色配置
    local modicator = require("modicator")
    local mode_colors = require("configs.mode_colors")
    -- 在这些文件类型或终端缓冲区中不显示模式行号颜色
    local disabled_filetypes = {
        Avante = true,
        AvanteInput = true,
        AvantePromptInput = true,
        AvanteSelectedFiles = true,
        AvanteTodos = true,
        snacks_terminal = true,
    }
    -- 为不同编辑模式定义高亮颜色
    local mode_highlights = {
        Normal = mode_colors.cursorline_n,
        Insert = mode_colors.i,
        Visual = mode_colors.v,
        Command = mode_colors.c,
        Replace = mode_colors.R,
        Select = mode_colors.s,
        Terminal = mode_colors.t,
        TerminalNormal = mode_colors.n,
    }
    -- 将 Vim 的模式缩写映射为 Modicator 使用的模式名称
    local mode_names = { n = "Normal", i = "Insert", v = "Visual", V = "Visual", ["\22"] = "Visual", c = "Command", R = "Replace", s = "Select", t = "Terminal" }

    -- 根据当前缓冲区判断功能是否启用
    local enabled = not disabled_filetypes[vim.bo.filetype] and vim.bo.buftype ~= "terminal"

    -- 注册各模式高亮，并更新当前行号颜色
    local function set_mode_highlights()
        local cursorline_bg = vim.api.nvim_get_hl(0, { name = "CursorLine" }).bg
        for mode, color in pairs(mode_highlights) do
            local highlight = mode == "Visual"
                and { fg = "#000000", bg = color, bold = true }
                or { fg = color, bg = cursorline_bg, bold = true }
            vim.api.nvim_set_hl(0, mode .. "Mode", highlight)
        end
        if enabled then
            local mode = vim.fn.mode(1):sub(1, 1)
            local color = mode_highlights[mode_names[mode]]
            local highlight = mode_names[mode] == "Visual"
                and { fg = "#000000", bg = color, bold = true }
                or { fg = color or mode_colors.n, bg = cursorline_bg, bold = true }
            vim.api.nvim_set_hl(0, "CursorLineNr", highlight)
        end
    end

    -- 初始化 Modicator；仅 Visual 模式使用模式背景色
    set_mode_highlights()
    modicator.setup({ highlights = { use_cursorline_background = false } })

    -- 按当前编辑模式设置光标行高亮
    local function update_cursorline()
        if enabled then
            modicator.set_cursor_line_highlight(modicator.hl_name_from_mode(vim.fn.mode(1)))
        end
    end

    -- 在切换窗口或文件类型时同步启用状态
    local function sync_modicator()
        local should_enable = not disabled_filetypes[vim.bo.filetype] and vim.bo.buftype ~= "terminal"
        if should_enable == enabled then return end
        enabled = should_enable
        if enabled then modicator.enable(); update_cursorline() else modicator.disable() end
        set_mode_highlights()
    end

    -- 监听缓冲区、窗口和文件类型变化，延迟同步避免事件嵌套
    local group = vim.api.nvim_create_augroup("LipModicator", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType", "WinEnter", "WinLeave" }, {
        group = group, callback = function() vim.schedule(sync_modicator) end,
    })
    vim.api.nvim_create_autocmd({ "Colorscheme", "ModeChanged" }, {
        -- 主题或编辑模式变化后重新应用颜色
        group = group, callback = function() set_mode_highlights(); update_cursorline() end,
    })
    sync_modicator()
end

function M.componentsConfig()
    return {icons = require("configs.icons").componentsIcons() }
end

function M.scrollbarConfig()
    table.insert(require("scrollbar.config").get().excluded_buftypes, "nofile")
    table.insert(require("scrollbar.config").get().excluded_filetypes, "grug-far")
    vim.list_extend(require("scrollbar.config").get().excluded_filetypes, {
        "Avante",
        "AvanteInput",
        "AvantePromptInput",
        "AvanteSelectedFiles",
    })
    require("scrollbar").setup({
        handle = {
            color = "#585b70",
            blend = 15,
        },
        marks = {
            GitAdd = { text = "▐" },
            GitChange = { text = "▐" },
            GitDelete = { text = "▐" },
        },
    })
    require("scrollbar.handlers.gitsigns").setup()
end

function M.noiceConfig()
    local enable_conceal = false          -- Hide command text if true
    require('noice').setup({
        throttle = 100, -- 默认 1000/30（约 30fps）会一直空转唤醒；降到 10fps
        presets = {
            bottom_search = false, -- The kind of popup used for /
            command_palette = true, -- position the cmdline and popupmenu together
            long_message_to_split = true,
            lsp_doc_border = true, -- 给浮窗加边框
        },
        cmdline = {
            view = "cmdline_popup",                 -- The kind of popup used for :
            format = {
                cmdline = { conceal = enable_conceal },
                search_down = { conceal = enable_conceal, title = " Search · 全词 \\<word\\> " },
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
            signature = { enabled = true, auto_open = { enabled = false, } },
            progress = { enabled = true },
            message = { enabled = true },
            smart_move = { enabled = false },
            view_error = "messages",
        },
    })

    map("i", "<A-f>", function() vim.lsp.buf.signature_help() end)
end

function M.windowsConfig()
    vim.o.equalalways = false
    vim.o.winwidth = 10
    vim.o.winminwidth = 10

    package.preload["windows.lib.ffi"] = function()
        return {
            curwin_col_off = function()
                local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
                return wininfo and wininfo.textoff or 0
            end,
        }
    end

    require("windows").setup({
        autowidth = {
            enable = true,
            winwidth = 15,
            filetype = {
                help = 2,
            },
        },
        ignore = {
            buftype = { "quickfix", "terminal" },
            filetype = {
                "sagaoutline",
                "snacks_layout_box",
                "snacks_dashboard",
                "snacks_notif",
                "snacks_picker_list",
                "snacks_picker_preview",
                "snacks_terminal",
                "Avante",
                "AvanteInput",
                "AvanteSelectedCode",
                "AvanteSelectedFiles",
                "AvanteTodos",
                "grug-far",
                -- edgy.nvim 接管的窗口：宽度由 edgebar 统一分配，别让 autowidth 再插手
                "OverseerList",
                "OverseerForm",
                "OverseerTaskAction",
            },
        },
    })
end

function M.whitespaceConfig()
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
            'snacks_picker_list',
            'dashboard',
            'snacks_win',
            'snacks_notif',
            'snacks_terminal',
            'snacks_dashboard',
            'TelescopePrompt',
            'blink-cmp-menu',
            'blink-cmp-documentation',
            'fff_input',
            'fff_list',
            'fff_preview',
            'fff_file_info',
            'Avante',
            'AvanteInput',
            'AvantePromptInput',
            'AvanteSelectedFiles',
            'AvanteTodos',
            'grug-far',
        },
        ignore_terminal = true,
        return_cursor = true,
    })

    vim.keymap.set('n', '<leader><Space>', require('whitespace-nvim').trim)

    Snacks.toggle({
        -- name = "Indention Guides",
        name = "Trim 󱁐 on save",
        get = function()
            return vim.g.trim_whitespace_on_save == true
        end,
        set = function(state)
            vim.g.trim_whitespace_on_save = state
            if state then
                -- 开启自动去除行尾空格
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = vim.api.nvim_create_augroup("TrimWhitespaceOnSave", { clear = true }),
                    callback = function()
                        require("whitespace-nvim").trim()
                    end,
                })
            else
                -- 关闭自动去除
                pcall(vim.api.nvim_del_augroup_by_name, "TrimWhitespaceOnSave")
            end
        end,
    }):map("<leader>u<space>")
end

function M.lspsagaConfig()
    require('lspsaga').setup({
        ui = {
            use_nerd = not use_ascii_icons,
            code_action = use_ascii_icons and " A" or '󱠀',
        },
        lightbulb = {
            sign_priority = 9,
        },
        code_action = {
            keys = {
                quit = { "q", "<C-c>" },
            },
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
            auto_preview = false,
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

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "sagarename",
        callback = function(args)
            vim.keymap.set("n", "<Esc>", "<C-c>", { buffer = args.buf, remap = true })
            vim.schedule(function()
                if vim.api.nvim_get_current_buf() == args.buf then
                    local line = vim.api.nvim_get_current_line()
                    vim.api.nvim_win_set_cursor(0, { 1, #line })
                end
            end)
        end,
    })

    require("configs.lspsaga_outline").setup()

    map("n", "gf"        , "<cmd>Lspsaga finder def+ref+imp<CR>", { desc = "Show LSP methods search result"} )
    map("n", "<A-h>"     , "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover Documentation"} )
    map("n", "<A-l>"     , "<cmd>Lspsaga peek_definition<CR>", { desc = "Hover definition in hover"} )
    map("n", "<leader>cn", "<cmd>Lspsaga rename ++project mode=i<cr>", { desc = '[R]e[n]ame'} )
    map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc ='[C]ode [A]ction'} )
    map("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc ='goto [N]ext diagnostic'} )
    map("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { desc ='goto [P]rev diagnostic'} )
    map("n", "<F3>", "<cmd>Lspsaga outline<CR>", { desc ='Show outline'} )
end

function M.visualWhitespaceConfig()
    local opts = {
        enabled = true,
        nl_char = '',
        cr_char = '←',
        tab_char = '→',
        space_char = '·',
        highlight = { link = "Visual" },
        excluded = {
            filetypes = {
                "Avante", "AvanteInput", "AvantePromptInput",
                "fff_input", "fff_list", "fff_preview", "fff_file_info",
            },
            buftypes = { "nofile", "prompt" },
        },
    }
    require('visual-whitespace').setup(opts)

    -- 进入按行可视模式时，可能会在选区就绪前触发；
    -- 在下一个事件循环周期重绘一次，使标记立即显示。
    local group = vim.api.nvim_create_augroup("lip_visual_whitespace", { clear = true })
    vim.api.nvim_create_autocmd("ModeChanged", {
        group = group,
        pattern = "*:[vV]",
        callback = function()
            vim.schedule(function()
                if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
                    vim.api.nvim_exec_autocmds("CursorMoved", {
                        group = "VisualWhitespaceHL",
                    })
                end
            end)
        end,
    })
end

function M.whichKeyConfig()
    local wk = require('which-key')
    require("which-key.plugins.registers").registers = '0123456789*+"-:.%/#=_abcdef'
    local opts = {
        preset = "helix",
        defaults = {},
        -- 仅对这些前缀显示 which-key，避免普通按键/鼠标事件误触发
        triggers = {
            { "<leader>", mode = { "n", "v" } },
            { "'", mode = { "n", "v" } },
            { '"', mode = { "n", "v" } },
            { "`", mode = { "n", "v" } },
            { "g", mode = { "n", "v" } },
            { "z", mode = { "n", "v" } },
            { "[", mode = { "n", "v" } },
            { "]", mode = { "n", "v" } },
        },
        spec = {
            {
                mode = { "n", "v" },
                {"<leader>a" , desc = "Avante keymap" },
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
                {"<leader>fs", desc = "Search with parameter" },
                {"<leader>fm", desc = "Mark list" },
                {"<leader>fe", desc = "Harpoon list" },
                {"<leader>ha" , desc = "Harpoon add current file" },
                {"<leader>t" , desc = "Table and todo" },
                {"<leader>tm", desc = "Table mode toggle" },
                {"<leader>s" , desc = "Surround, search, replace" },
                {"<leader>c" , desc = "Code action, rename, comment" },
                {"]D", desc = "Last diagnostic" },
            }
        },
        icons = {
            mappings = not use_ascii_icons, -- 在不支持nerd的里边不启用图标
            colors = true,
        }
    }
    wk.setup(opts)
end

function M.miniIconsConfig()
    require("mini.icons").setup({
        style = use_ascii_icons and "ascii" or "nerd",
    })
end

function M.miniAnimate()
    -- 2. 前置准备：定义鼠标滚动标记、映射鼠标滚轮按键、创建自动命令、注册切换快捷键
    local mouse_scrolled = false
    -- 映射鼠标滚轮上下键，标记鼠标滚动状态（普通模式/插入模式均生效）
    for _, scroll in ipairs({ "Up", "Down" }) do
        local key = "<ScrollWheel" .. scroll .. ">"
        vim.keymap.set({ "", "i" }, key, function()
            mouse_scrolled = true
            return key
        end, { expr = true })
    end

    -- 对 grug-far 文件类型，缓冲区级禁用 mini.animate 动画
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "grug-far",
        callback = function()
            vim.b.minianimate_disable = true
        end,
    })

    -- 注册 <leader>ua 快捷键，切换 mini.animate 全局启用/禁用状态（延迟执行覆盖默认映射）
    vim.schedule(function()
        require('snacks').toggle({
            name = "Mini Animate",
            get = function()
                return not vim.g.minianimate_disable
            end,
            set = function(state)
                vim.g.minianimate_disable = not state
            end,
        }):map("<leader>uA")
    end)

    local animate = require('mini.animate')

    require("mini.animate").setup({
        -- 窗口调整动画：线性缓动 + 总时长50ms（原配置resize自定义）
        resize = {
            timing = animate.gen_timing.linear({ duration = 50, unit = "total" }),
        },
        -- 滚动动画：核心自定义（含鼠标滚动禁用逻辑）
        scroll = {
            enable = true,
            timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
            subscroll = animate.gen_subscroll.equal({
                -- 滚动触发条件：鼠标滚动则禁用，仅滚动幅度>1时触发（与原配置predicate完全一致）
                predicate = function(total_scroll)
                    if mouse_scrolled then
                        mouse_scrolled = false
                        return false
                    end
                    return total_scroll > 1
                end,
            }),
        },
        -- 其他动画模块（cursor/open/close）保留 mini.animate 原生默认配置
        -- 若需禁用，可添加：
        cursor = { enable = false }, open = { enable = false }, close = { enable = false }
    })
end

function M.todoConfig()
    local todo = require('todo-comments')

    todo.setup()

    map("n", "]t", function()
        todo.jump_next({keywords = { "TODO", "NOTE", "FIX", "FIXME" }})
    end, { desc = "Next TODO/NOTE comment" })

    map("n", "[t", function()
        todo.jump_prev({keywords = { "TODO", "NOTE", "FIX", "FIXME" }})
    end, { desc = "Previous TODO/NOTE comment" })

    map("n", "<leader>fo", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME,NOTE,PERF<CR>",
        { desc = "Open todo/fixed/note list" })
end

-- TODO: need relize session open with fold
function M.ufoConfig()
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

function M.colorizerConfig()
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
    link = {
        wiki = { icon = '', highlight = 'RenderMarkdownWikiLink', scope_highlight = 'RenderMarkdownWikiLink' },
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

function M.markdownConfig()
    local mk = require('render-markdown')

    local opts = {
        file_types = { 'markdown', 'vimwiki', 'Avante' },
        heading = {
            position = 'inline',
            sign = false,
            width = 'block',
            min_width = 0,
            border = false,
            render_modes = false, -- not keep rendering while inserting
            border_virtual = true,
            icons = { ' 󰼏 ', ' 󰎨 ', ' 󰼑 ', ' 󰎲 ', ' 󰼓 ', ' 󰎴 ' },
            signs = { '>' }
        },
        code = {
            sign = false,
            width = 'block',
            min_width = 45,
            -- left_pad = 0,
            -- right_pad = 2,
            style = 'normal',
            border = 'thick', -- 把后边的 ``` 位置空间保留下来
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
        quote = { repeat_linebreak = true },
        pipe_table = {
            alignment_indicator = '━',
            border = { '╭', '┬', '╮', '├', '┼', '┤', '╰', '┴', '╯', '│', '─' },
        },
        link = {
            wiki = { icon = ' ', highlight = 'RenderMarkdownWikiLink', scope_highlight = 'RenderMarkdownWikiLink' },
            image = ' ',
            custom = {
                github = { pattern = 'github', icon = ' ' },
                gitlab = { pattern = 'gitlab', icon = ' ' },
                youtube = { pattern = 'youtube', icon = ' ' },
            },
            hyperlink = ' ',
        },
    }

    if use_ascii_icons then
        opts = vim.tbl_deep_extend("force", opts, ascii_icons)
    end

    vim.api.nvim_set_hl(0, "RenderMarkdownShowbreak", { bg = "NONE" })
    local group = vim.api.nvim_create_augroup("RenderMarkdownQuoteLinebreak", { clear = true })
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        callback = function(args)
            local win = vim.api.nvim_get_current_win()
            vim.schedule(function()
                if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= args.buf then
                    return
                end
                vim.api.nvim_win_call(win, function()
                    local ft = vim.bo.filetype
                    if ft == "markdown" or ft == "vimwiki" or ft == "Avante" then
                        vim.opt_local.showbreak = "  "
                        vim.opt_local.breakindent = false
                        local mapping = "NonText:RenderMarkdownShowbreak"
                        if not vim.wo.winhighlight:find(mapping, 1, true) then
                            vim.opt_local.winhighlight:append(mapping)
                        end
                    end
                end)
            end)
        end,
    })

    mk.setup(opts)
end

function M.deviconsConfig()
    local scripts_color = '#cbcb41'
    local scripts_ccolor = '185'
    local vs_color = '#63E7FF'
    local vs_ccolor = '74'
    local mk_color = '#89e051'
    local mk_ccolor = '113'
    local keyword_color = '#A074C4'
    local keyword_ccolor = '100' -- TODO: need to confirm
    require("nvim-web-devicons").setup {
        override = {
            mk = {
                icon = use_ascii_icons and "M" or "",
                color = mk_color,
                cterm_color = mk_ccolor,
                name = "CMake2",
            },
            yml = {
                icon = use_ascii_icons and "Y" or "",
                color = scripts_color,
                cterm_color = scripts_ccolor,
                name = "yaml2",
            },
            sh = {
                icon = use_ascii_icons and "$" or "",
                color = scripts_color,
                cterm_color = scripts_ccolor,
                name = "sh",
            },
            png = {
                icon = "",
                color = keyword_color,
                cterm_color = keyword_ccolor,
                name = "png",
            }
        },
        override_by_filename = {
            ["CMakelists.txt"] = {
                icon = use_ascii_icons and "M" or "",
                color = mk_color,
                cterm_color = mk_ccolor,
                name = "CMake2",
            },
            ["Makefile"] = {
                icon = use_ascii_icons and "M" or "",
                color = mk_color,
                cterm_color = mk_ccolor,
                name = "Makefile2",
            },
            ["Kconfig"] = {
                icon = use_ascii_icons and "K" or "",
                color = scripts_color,
                cterm_color = scripts_ccolor,
                name = "Kconfig2",
            },
            ["code-workspace"] = {
                icon = use_ascii_icons and "V" or "",
                color = vs_color,
                cterm_color = vs_ccolor,
                name = "vscodeSpace",
            },
            ["readme"] = {
                icon = use_ascii_icons and "D" or "",
                color = vs_color,
                cterm_color = vs_ccolor,
                name = "markdown2",
            },
            ["README"] = {
                icon = use_ascii_icons and "D" or "",
                color = vs_color,
                cterm_color = vs_ccolor,
                name = "markdown3",
            },
            ["README.md"] = {
                icon = use_ascii_icons and "D" or "",
                color = vs_color,
                cterm_color = vs_ccolor,
                name = "markdown3",
            },
            [""] = {
                icon = use_ascii_icons and "B" or "",
                color = vs_color,
                cterm_color = vs_ccolor,
                name = "markdown3",
            },
        }
    }
end

function M.accjkConfig()
    local function smart_(key, cmd)
        return function()
            local count = vim.v.count

            if count > 0 then
                vim.cmd(("normal! %d%s"):format(count, key)) return
            end

            vim.b.snacks_scroll = false

            vim.fn["accelerated#time_driven#command"](cmd)

            vim.defer_fn(function()
                vim.b.snacks_scroll = nil
            end, 0)
        end
    end

    vim.keymap.set("n", "j", smart_("j", "gj"), { silent = true })
    vim.keymap.set("n", "k", smart_("k", "gk"), { silent = true })
end

function M.interestingwordsConfig()
    require('interestingwords').setup{
        colors = { '#8CCBEA', '#A4E57E', '#FFDB72', '#FF7272', '#FFB3FF', '#9999FF' },
        search_count = true,
        navigation = false,
        scroll_center = false,
        color_key = "<leader>e",
        select_mode = "loop",
    }

    local iw = require("interestingwords")
    local illuminate = require("illuminate")
    local illuminate_ref = require("illuminate.reference")

    local function cursor_in_pattern(pattern)
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local start = 0

        while start <= #line do
            local ok, match = pcall(vim.fn.matchstrpos, line, pattern, start)
            if not ok or match[1] == "" then
                return false
            end

            local match_start = match[2]
            local match_end = match[3]
            if col >= match_start and col < match_end then
                return true
            end

            start = math.max(match_end, start + 1)
        end

        return false
    end

    local function jump_search(forward)
        if vim.v.hlsearch == 0 or vim.fn.getreg("/") == "" then
            return false
        end

        local flags = forward and "" or "b"
        local ok, found = pcall(vim.fn.search, vim.fn.getreg("/"), flags)
        return ok and found ~= 0
    end

    local function cursor_word_is_interesting()
        local matches = vim.fn.getmatches()

        for _, m in ipairs(matches) do
            if m.group and m.group:match("^InterestingWord") then
                if cursor_in_pattern(m.pattern) then
                    return true
                end
            end
        end

        return false
    end

    local function cursor_in_illuminate_reference()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local pos = { cursor[1] - 1, cursor[2] }

        return illuminate_ref.buf_cursor_in_references(vim.api.nvim_get_current_buf(), pos)
    end

    local function cursor_in_search()
        return vim.v.hlsearch ~= 0 and vim.fn.getreg("/") ~= "" and cursor_in_pattern(vim.fn.getreg("/"))
    end

    local function jump_pair_under_cursor(forward)
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2] + 1
        local char = line:sub(col, col)
        local pairs = forward and { ["("] = true, ["{"] = true, ["["] = true }
            or { [")"] = true, ["}"] = true, ["]"] = true }

        if not pairs[char] then
            return false
        end

        vim.cmd("normal! %")
        return true
    end

    local function jump_forward()
        if jump_pair_under_cursor(true) then
            return
        elseif cursor_word_is_interesting() then
            iw.NavigateToWord(true)
        elseif cursor_in_illuminate_reference() then
            illuminate.goto_next_reference()
        elseif cursor_in_search() then
            jump_search(true)
        else
            return
        end
    end

    local function jump_backward()
        if jump_pair_under_cursor(false) then
            return
        elseif cursor_word_is_interesting() then
            iw.NavigateToWord(false)
        elseif cursor_in_illuminate_reference() then
            illuminate.goto_prev_reference()
        elseif cursor_in_search() then
            jump_search(false)
        else
            return
        end
    end

    local function jump_next_interesting()
        local nearest
        local nearest_pattern

        for pattern in pairs(iw.words) do
            local pos = vim.fn.searchpos(pattern, "nW")
            if pos[1] ~= 0 and (not nearest or pos[1] < nearest[1]
                    or (pos[1] == nearest[1] and pos[2] < nearest[2])) then
                nearest = pos
                nearest_pattern = pattern
            end
        end

        if not nearest then
            for pattern in pairs(iw.words) do
                local pos = vim.fn.searchpos(pattern, "nw")
                if pos[1] ~= 0 and (not nearest or pos[1] < nearest[1]
                        or (pos[1] == nearest[1] and pos[2] < nearest[2])) then
                    nearest = pos
                    nearest_pattern = pattern
                end
            end
        end

        if nearest then
            vim.api.nvim_win_set_cursor(0, { nearest[1], nearest[2] - 1 })
            iw.search_count(nearest_pattern)
        end
    end

    local function jump_previous_interesting()
        local nearest
        local nearest_pattern

        for pattern in pairs(iw.words) do
            local pos = vim.fn.searchpos(pattern, "bnW")
            if pos[1] ~= 0 and (not nearest or pos[1] > nearest[1]
                    or (pos[1] == nearest[1] and pos[2] > nearest[2])) then
                nearest = pos
                nearest_pattern = pattern
            end
        end

        if not nearest then
            for pattern in pairs(iw.words) do
                local pos = vim.fn.searchpos(pattern, "bnw")
                if pos[1] ~= 0 and (not nearest or pos[1] > nearest[1]
                        or (pos[1] == nearest[1] and pos[2] > nearest[2])) then
                    nearest = pos
                    nearest_pattern = pattern
                end
            end
        end

        if nearest then
            vim.api.nvim_win_set_cursor(0, { nearest[1], nearest[2] - 1 })
            iw.search_count(nearest_pattern)
        end
    end

    vim.keymap.set("n", "]e", jump_next_interesting, { silent = true, desc = "Next interesting word" })
    vim.keymap.set("n", "[e", jump_previous_interesting, { silent = true, desc = "Previous interesting word" })
    vim.keymap.set("n", "<A-j>", jump_forward,  { silent = true, desc = "Next matching highlight" })
    vim.keymap.set("n", "<A-k>", jump_backward, { silent = true, desc = "Prev matching highlight" })
end

-- flash 的 `f` 单字符搜索期间（等待输入目标字符，或跳到某个字符后继续重复查找），按 <CR> 直接退出（等同 <Esc>）
function M.flashConfig()
    local ns = vim.api.nvim_create_namespace("lip_flash_char_exit")
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
    vim.on_key(function(key)
        -- 仅在 flash 的单字符搜索处于活动状态时拦截，避免影响普通 <CR>
        local char = package.loaded["flash.plugins.char"]
        if key == "\r" and char and (char.jumping or char.visible()) then
            -- 丢弃 <CR> 并回放 <Esc>，让 flash 退出单字符搜索
            vim.api.nvim_feedkeys(esc, "n", false)
            return ""
        end
    end, ns)
end

return M
