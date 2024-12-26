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
        dependencies = {
            "Zeioth/heirline-components.nvim"
        },
        event = "User BaseDefered",
        opts = function ()
            local lib = require "heirline-components.all"
            return {
                opts = {
                    statusline = { -- UI statusbar
                        hl = { fg = "fg", bg = "bg" },
                        lib.component.mode(),
                        lib.component.git_branch(),
                        lib.component.file_info(),
                        lib.component.git_diff(),
                        lib.component.diagnostics(),
                        lib.component.fill(),
                        lib.component.cmd_info(),
                        lib.component.fill(),
                        lib.component.lsp(),
                        lib.component.compiler_state(),
                        lib.component.virtual_env(),
                        lib.component.nav(),
                        lib.component.mode { surround = { separator = "right" } },
                    },
                },
            }
        end,
        config = function(_, opts)
            local heirline = require("heirline")
            local conditions = require("heirline.conditions")
            local utils = require("heirline.utils")
            local Align = { provider = "%="  }
            local Space = { provider = " "  }
            local heirline_components = require("heirline-components.all")
            local lib = require "heirline-components.all"

            -- Setup heirline-components.nvim
            heirline_components.init.subscribe_to_events()
            heirline.load_colors(heirline_components.hl.get_colors())
            heirline.setup(opts)


            ----lip 1----
            local ViMode = {
                -- get vim current mode, this information will be required by the provider
                -- and the highlight functions, so we compute it only once per component
                -- evaluation and store it as a component attribute
                init = function(self)
                    self.mode = vim.fn.mode(1) -- :h mode()
                end,
                -- Now we define some dictionaries to map the output of mode() to the
                -- corresponding string and color. We can put these into `static` to compute
                -- them at initialisation time.
                static = {
                    mode_names = { -- change the strings if you like it vvvvverbose!
                        n = "N",
                        no = "N?",
                        nov = "N?",
                        noV = "N?",
                        ["no\22"] = "N?",
                        niI = "Ni",
                        niR = "Nr",
                        niV = "Nv",
                        nt = "Nt",
                        v = "V",
                        vs = "Vs",
                        V = "V_",
                        Vs = "Vs",
                        ["\22"] = "^V",
                        ["\22s"] = "^V",
                        s = "S",
                        S = "S_",
                        ["\19"] = "^S",
                        i = "I",
                        ic = "Ic",
                        ix = "Ix",
                        R = "R",
                        Rc = "Rc",
                        Rx = "Rx",
                        Rv = "Rv",
                        Rvc = "Rv",
                        Rvx = "Rv",
                        c = "C",
                        cv = "Ex",
                        r = "...",
                        rm = "M",
                        ["r?"] = "?",
                        ["!"] = "!",
                        t = "T",
                    },
                    mode_colors = {
                        n = "red" ,
                        i = "green",
                        v = "cyan",
                        V =  "cyan",
                        ["\22"] =  "cyan",
                        c =  "orange",
                        s =  "purple",
                        S =  "purple",
                        ["\19"] =  "purple",
                        R =  "orange",
                        r =  "orange",
                        ["!"] =  "red",
                        t =  "red",
                    }
                },
                -- We can now access the value of mode() that, by now, would have been
                -- computed by `init()` and use it to index our strings dictionary.
                -- note how `static` fields become just regular attributes once the
                -- component is instantiated.
                -- To be extra meticulous, we can also add some vim statusline syntax to
                -- control the padding and make sure our string is always at least 2
                -- characters long. Plus a nice Icon.
                provider = function(self)
                    return " %2("..self.mode_names[self.mode].."  %)"
                end,
                -- Same goes for the highlight. Now the foreground will change according to the current mode.
                hl = function(self)
                    local mode = self.mode:sub(1, 1) -- get only the first mode character
                    return { fg = self.mode_colors[mode], bold = true, }
                end,
                -- Re-evaluate the component only on ModeChanged event!
                -- Also allows the statusline to be re-evaluated when entering operator-pending mode
                update = {
                    "ModeChanged",
                    pattern = "*:*",
                    callback = vim.schedule_wrap(function()
                        vim.cmd("redrawstatus")
                    end),
                },
            }

            ----lip 2----
            local FileNameBlock = {
                -- let's first set up some attributes needed by this component and its children
                init = function(self)
                    self.filename = vim.api.nvim_buf_get_name(0)
                end,
            }
            -- We can now define some children separately and add them later

            local FileIcon = {
                init = function(self)
                    local filename = self.filename
                    local extension = vim.fn.fnamemodify(filename, ":e")
                    self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
                end,
                provider = function(self)
                    return self.icon and (self.icon .. " ")
                end,
                hl = function(self)
                    return { fg = self.icon_color }
                end
            }

            local FileName = {
                provider = function(self)
                    -- first, trim the pattern relative to the current directory. For other
                    -- options, see :h filename-modifers
                    local filename = vim.fn.fnamemodify(self.filename, ":.")
                    if filename == "" then return "[No Name]" end
                    -- now, if the filename would occupy more than 1/4th of the available
                    -- space, we trim the file path to its initials
                    -- See Flexible Components section below for dynamic truncation
                    if not conditions.width_percent_below(#filename, 0.25) then
                        filename = vim.fn.pathshorten(filename)
                    end
                    return filename
                end,
                hl = { fg = utils.get_highlight("Directory").fg },
            }

            local FileFlags = {
                {
                    condition = function()
                        return vim.bo.modified
                    end,
                    provider = "[+]",
                    hl = { fg = "green" },
                },
                {
                    condition = function()
                        return not vim.bo.modifiable or vim.bo.readonly
                    end,
                    provider = "",
                    hl = { fg = "orange" },
                },
            }

            -- Now, let's say that we want the filename color to change if the buffer is
            -- modified. Of course, we could do that directly using the FileName.hl field,
            -- but we'll see how easy it is to alter existing components using a "modifier"
            -- component

            local FileNameModifer = {
                hl = function()
                    if vim.bo.modified then
                        -- use `force` because we need to override the child's hl foreground
                        return { fg = "cyan", bold = true, force=true }
                    end
                end,
            }

            -- let's add the children to our FileNameBlock component
             FileNameBlock = utils.insert(FileNameBlock,
             --FileNameBlock = utils.insert(FileName,
             FileIcon,
             utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
             FileFlags,
             { provider = '%<'} -- this means that the statusline is cut here when there's not enough space
             )

             -- lip 3 --
             local FileType = {
                 provider = function()
                     return string.upper(vim.bo.filetype)
                 end,
                 hl = { fg = "blue", bg = "black" },
             }
             local FileEncoding = {
                 provider = function()
                     local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
                     --return enc ~= 'utf-8' and enc:upper()
                     return enc:upper()
                 end,
                 hl = { fg = heirline_components.hl.get_colors().green, bg = heirline_components.hl.get_colors().blue },
             }

             local FileFormat = {
                 provider = function()
                     local eol = vim.bo.fileformat
                     if eol == 'unix' then
                         return 'LF'
                     elseif eol == 'dos' then
                         return 'CRLF'
                     else
                         return 'N/A'
                     end
                 end
             }

             -- lip 4 --
             -- I take no credits for this! 🦁
             local ScrollBar ={
                 static = {
                     sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }
                     -- Another variant, because the more choice the better.
                     -- sbar = { '🭶', '🭷', '🭸', '🭹', '🭺', '🭻' }
                 },
                 provider = function(self)
                     local curr_line = vim.api.nvim_win_get_cursor(0)[1]
                     local lines = vim.api.nvim_buf_line_count(0)
                     local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
                     return string.rep(self.sbar[i], 2)
                 end,
                 hl = { fg = "#c678dd", bg = "#1e222a" },
             }

            --local StatusLine = {
                --hl = { fg = 'white', bg = '#282828' },
                --{ ViMode }, Space,
                --{ FileNameBlock }, Space,
                --Align,
                --{ FileType }, Space, Space,
                --{ FileEncoding }, Space, Space,
                --{ FileFormat }, Space, Space,
                --{ ScrollBar },
            --}


            local StatusLine = {
                hl = { fg = "fg", bg = "bg" },
                { ViMode }, Space,
                lib.component.git_branch(),
                lib.component.git_diff(),
                { FileNameBlock }, Space,
                -- lib.component.file_info(),
                Align,
                lib.component.cmd_info(),
                Align,
                -- lib.component.lsp(),
                lib.component.compiler_state(),
                lib.component.diagnostics(),
                -- lib.component.virtual_env(),
                Space, Space,
                -- { FileType }, Space, Space,
                { FileEncoding }, Space, Space,
                { FileFormat },
                -- { ScrollBar },
                lib.component.nav(),
            }

            local StatusLines = {
                hl = function()
                    if conditions.is_active() then
                        return "StatusLine"
                    else
                        return "StatusLineNC"
                    end
                end,
                fallthrough = false,
            }

            local statusline = { -- UI statusbar
                hl = { fg = "fg", bg = "bg" },
                lib.component.mode(),
                lib.component.git_branch(),
                lib.component.file_info(),
                lib.component.git_diff(),
                lib.component.diagnostics(),
                lib.component.fill(),
                lib.component.cmd_info(),
                lib.component.fill(),
                lib.component.lsp(),
                lib.component.compiler_state(),
                lib.component.virtual_env(),
                lib.component.nav(),
                lib.component.mode { surround = { separator = "right" } },
            }

            heirline.setup({
                statusline = StatusLine,
            })
        end
    },
    {
        'https://gitee.com/yunduozhai/bufferline.nvim.git',
        version = "*",
        dependencies = 'nvim-web-devicons',
        options = {
            themable = true, -- allows highlight groups to be overriden i.e. sets highlights as default
            numbers = "both",
            close_command = "bdelete! %d",       -- can be a string | function, | false see "Mouse actions"
            right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
            left_mouse_command = "buffer %d",    -- can be a string | function, | false see "Mouse actions"
            middle_mouse_command = nil,          -- can be a string | function, | false see "Mouse actions"
            indicator = {
                style = 'underline',
            },
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    text_align = "center",
                    separator = true,
                }
            },
            color_icons = true, -- whether or not to add the filetype icon highlights
            highlights = {
                buffer_selected = {
                    fg = {attribute = "fg", highlight = "Normal" },
                    bg = "#ffcc00", -- 选中的缓冲区的背景颜色, not work!!!
                    -- gui = "bold",
                },
            },
        },
    },
    {
        --  [better ui elements]
        -- https://github.com/stevearc/dressing.nvim
        "https://gitee.com/yunduozhai/dressing.nvim.git",
        event = "User BaseDefered",
        opts = {
            input = { default_prompt = "➤ " },
            select = { backend = { "telescope", "builtin" } },
        }
    },
    {
        "https://gitee.com/yunduozhai/noice.nvim.git",
        event = "User BaseDefered",
        opts = function()
            local enable_conceal = false          -- Hide command text if true
            return {
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

            -- Disable every other noice feature
            messages = { enabled = false },
            lsp = {
                hover = { enabled = false },
                signature = { enabled = false },
                progress = { enabled = false },
                message = { enabled = false },
                smart_move = { enabled = false },
            },
        }
    end
    },
    {
        -- indent 的动画效果
        -- text object ii ai [i ]i
        "https://gitee.com/yunduozhai/mini.indentscope.git",
        version = false,
        opts = {
            symbol = '▎',
            options = { try_as_border = true },
        },
        init = function()
            return require("configs.indent").miniIndentInit()
        end,
    },
    {
        "https://gitee.com/sunn4mirror/snacks.nvim.git",
        priority = 1000,
        lazy = false,
        opts = {
            indent = { enabled = false },
            notifier = { enabled = true },
            quickfile = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true },
            scope = { enabled = false },
        },
    },
    {
        -- 函数缩进前的条
        "https://gitee.com/yunduozhai/indent-blankline.nvim.git",
        -- event = "User FilePost",
        -- event = "BufReadPost",
        main = "ibl",
        opts = function()
            return require("configs.indent").blanklineConfig()
        end,
    },
    {
        -- 显示并去掉空格
        "https://gitee.com/nvim_lip/whitespace.nvim.git",
        config = function()
            require("whitespace-nvim").setup({
                highlight = 'DiffDelete',
                ignored_filetypes = {
                    'lazy',
                    'help',
                    'mason',
                    "notify",
                    'Trouble',
                    'NvimTree',
                    'dashboard',
                    'TelescopePrompt',
                },
                ignore_terimal = true,
                return_cursor = true,
            })
            vim.keymap.set('n', '<leader><Space>', require('whitespace-nvim').trim)
        end
    },
}

