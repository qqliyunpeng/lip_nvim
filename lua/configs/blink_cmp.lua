
local M = {}
local use_ascii_icons = require("configs.icons").use_ascii_icons()

local ascii_icons = {
    Text = "[T]",
    Method = "[M]",
    Function = "[F]",
    Constructor = "[C]",

    Field = "[Fd]",
    Variable = "[V]",
    Property = "[P]",

    Class = "[Cl]",
    Interface = "[I]",
    Struct = "[S]",
    Module = "[Mo]",

    Unit = "[U]",
    Value = "[Val]",
    Enum = "[E]",
    EnumMember = "[Em]",

    Keyword = "[K]",
    Constant = "[Co]",

    Snippet = "[Snip]",
    Color = "[Col]",
    File = "[File]",
    Reference = "[Ref]",
    Folder = "[Dir]",
    Event = "[Evt]",
    Operator = "[Op]",
    TypeParameter = "[Ty]",

    Yank = "󰅍",
}

local draw_lspkind_nerd = {
    -- nvim-cmp style menu
    -- columns = {
    --     { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" }
    -- },
    components = {
        kind_icon = {
            text = function(ctx)
                local icon = ctx.kind_icon
                if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                        icon = dev_icon
                    end
                else
                    if ctx.kind == "Yank" then
                        icon = ""
                    else
                        icon = require("lspkind").symbolic(ctx.kind, {
                            mode = "symbol",
                            -- symbol_map = require("configs.lspconfig").lspkindSymbolMap()
                            -- symbol_map = lspkind_ascii_icons
                        })
                    end
                end

                return icon .. ctx.icon_gap
            end,

            -- Optionally, use the highlight groups from nvim-web-devicons
            -- You can also add the same function for `kind.highlight` if you want to
            -- keep the highlight groups in sync with the icons.
            highlight = function(ctx)
                local hl = ctx.kind_hl
                if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                        hl = dev_hl
                    end
                end
                return hl
            end,
        }
    }
}

function M.blinkBuild()
    local version_file = vim.fn.expand("~/.local/share/nvim/lazy/blink.cmp/target/release/version")
    local libpath = vim.fn.expand("~/.local/share/nvim/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.so")

    if vim.fn.filereadable(libpath) == 1 then
        return
    end

    local release_dir = vim.fn.expand("~/.local/share/nvim/lazy/blink.cmp/target/release/")
    vim.fn.mkdir(release_dir, "p")

    local base = "https://gitee.com/nvim_lip/blink.cmp.releases/raw/v1.6.0/x86_64-unknown-linux-gnu.so"

    -- 启动后台下载
    vim.fn.jobstart({
        "curl", "-L", base, "-o", libpath
    }, {
        stdout_buffered = true,
        on_exit = function(_, code)
            if code == 0 then
                vim.fn.jobstart({
                    "curl", "-L", base .. ".sha256", "-o", libpath .. ".sha256"
                }, {
                    on_exit = function(_, code2)
                        if code2 == 0 then
                            -- 写 version 文件
                            local f = io.open(version_file, "w")
                            if f then
                                f:write("v1.6.0")
                                f:close()
                            end
                            vim.schedule(function()
                                vim.notify("blink.cmp binary downloaded successfully (v1.6.0)", vim.log.levels.INFO)
                            end)
                        else
                            vim.schedule(function()
                                vim.notify("Failed to download .sha256 file", vim.log.levels.ERROR)
                            end)
                        end
                    end,
                })
            else
                vim.schedule(function()
                    vim.notify("Failed to download libblink_cmp_fuzzy.so", vim.log.levels.ERROR)
                end)
            end
        end,
    })
end

function M.blinkConfig()
    local cmp = require("blink.cmp")

    cmp.setup({
        keymap = {
            preset = 'default',
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ["<Tab>"] = {
                function(bcmp)
                    local buf = vim.api.nvim_get_current_buf()

                    -- 1) Copilot LSP NES: accept pending suggestion first.
                    if vim.b[buf].nes_state then
                        local ok, nes = pcall(require, "copilot-lsp.nes")
                        if ok and nes then
                            bcmp.hide()
                            nes.apply_pending_nes()
                            return true
                        end
                    end

                    -- 2) When blink.cmp menu is NOT visible, accept Copilot inline suggestion
                    -- (virtual text) with <Tab>.
                    local menu_visible = type(bcmp.is_visible) == "function" and bcmp.is_visible() or false
                    if not menu_visible then
                        local ok, suggestion = pcall(require, "copilot.suggestion")
                        if ok and suggestion and type(suggestion.is_visible) == "function" and suggestion.is_visible() then
                            bcmp.hide()
                            suggestion.accept()
                            return true
                        end
                    end

                    -- 3) Menu visible: keep blink.cmp behavior.
                    if menu_visible then
                        local ok, accepted = pcall(bcmp.select_and_accept)
                        if ok and accepted then
                            return true
                        end
                    end

                    -- Returning nil continues to snippet_forward / fallback.
                end,
                'snippet_forward',
                'fallback',
            },
            -- ["<S-Tab>"] = { 'select_prev', 'snippet_backward', 'fallback' },
            ['<CR>']  = { 'accept', 'fallback' },
            ['<C-e>'] = { 'cancel' }, -- or {}
            ["<C-b>"] = false,
            ["<C-f>"] = false,
            ["<Down>"] = false,
            ["<Up>"]  = false,
            ["<C-n>"] = false,
            ["<C-p>"] = false,
            ["<C-h>"] = false,
        },
        appearance = {
            nerd_font_variant = 'mono',
            kind_icons = use_ascii_icons and ascii_icons or {},
        },
        cmdline = {
            keymap = {
                preset = 'cmdline',
                ['<C-j>'] = { 'select_next', 'fallback' },
                ['<C-k>'] = { 'select_prev', 'fallback' },
                ['<Left>'] = false;
                ['<Right>'] = false;
                -- ['<CR>']  = { 'show_and_insert', 'fallback' },
            },
            completion = {
                menu = { auto_show  = true },
                list = {
                    selection = { preselect = false, auto_insert = true },
                },
                ghost_text = {
                    enabled = true,
                },
            },
        },
        completion = {
            list = {
                selection = { preselect = false, auto_insert = true }, -- 不自动选择，自动插入
            },
            ghost_text = {  -- 虚拟文本
                enabled = true,
                -- Show the ghost text when an item has been selected
                show_with_selection = true,
                -- Show the ghost text when no item has been selected, defaulting to the first item
                show_without_selection = true,
                -- Show the ghost text when the menu is open
                show_with_menu = true,
                -- Show the ghost text when the menu is closed
                show_without_menu = true,
            },
            menu = {
                enabled = true,
                -- min_width = 5,
                max_height = 15,
                border = "rounded",
                winblend = 0,
                draw = not use_ascii_icons and draw_lspkind_nerd or {}
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 0,
                window = {
                    min_width = 10,
                    max_width = 80,
                    max_height = 20,
                    border = "rounded",
                }
            },
        },
        snippets = { preset = 'luasnip' },
        sources = {
            default = { 'lsp', 'path', 'snippets', 'buffer', "yank", "ripgrep" },
            providers = {
                yank = {
                    name = "yank",
                    module = "blink-yanky",
                    opts = {
                        minLength = 5,
                        onlyCurrentFiletype = true,
                        trigger_characters = { '"' },
                        kind_icon = "󰅍",
                    },
                },
                -- copilot = {
                --     name = "copilot",
                --     module = "blink-cmp-copilot",
                --     score_offset = 100,
                --     async = true,
                --     enabled = function ()
                --         return vim.g.blink_enable_copilot
                --     end,
                -- },
                ripgrep = {
                    name = "Ripgrep",
                    module = "blink-ripgrep",
                    opts = {},
                },
            }
        },
        fuzzy = {
            implementation = "prefer_rust",
            prebuilt_binaries = {
                force_version = "v1.6.0",
            },
            sorts = {
                'score',      -- Primary sort: by fuzzy matching score
                'sort_text',  -- Secondary sort: by sortText field if scores are equal
                'label',      -- Tertiary sort: by label if still tied
            }
        },
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "BlinkCmpMenuOpen",
        callback = function()
            vim.b.copilot_suggestion_hidden = true
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "BlinkCmpMenuClose",
        callback = function()
            vim.b.copilot_suggestion_hidden = false
        end,
    })
end

return M

