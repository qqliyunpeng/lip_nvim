local M = {}
local map = vim.keymap.set
local use_ascii_icons = require("configs.icons").use_ascii_icons()

local dia_nerd_icons = { Error = "", Warn = "", Hint = "󰌵", Info = "󰋼" }
local dia_ascii_icons = { Error = "E", Warn = "W", Hint = "H", Info = "I" }
local signs = use_ascii_icons and dia_ascii_icons or dia_nerd_icons

vim.diagnostic.config({
    severity_sort = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = signs.Error,
            [vim.diagnostic.severity.WARN] = signs.Warn,
            [vim.diagnostic.severity.HINT] = signs.Hint,
            [vim.diagnostic.severity.INFO] = signs.Info,
        },
    },
})

local servers = {
    clangd = {},
    pyright = {},
    lua_ls = {
        settings = {
            Lua = {
                diagnostics = {
                    globals = { "vim", "Snacks" },
                },
                -- workspace = { checkThirdParty = false },
                workspace = {
                    library = {
                        vim.fn.expand "$VIMRUNTIME/lua",
                        vim.fn.expand "$VIMRUNTIME/lua/vim/lsp",
                        -- vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
                        vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
                        "${3rd}/luv/library",
                    },
                    maxPreload = 100000,
                    preloadFileSize = 10000,
                },
                telemetry = { enable = false },
            },
        }
    },
}

local capabilities = vim.lsp.protocol.make_client_capabilities()

local function clangd_capabilities()
    local caps = vim.deepcopy(capabilities)
    caps.textDocument.completion.completionItem.snippetSupport = false
    return caps
end

local function clangd_publish_diagnostics(err, result, ctx, config)
    if result and result.diagnostics then
        -- 忽略当前目标平台不支持编译参数的诊断
        result.diagnostics = vim.tbl_filter(function(diagnostic)
            return diagnostic.code ~= "drv_unsupported_opt_for_target"
        end, result.diagnostics)
    end

    return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
end

local clangd_handlers = {
    ["textDocument/publishDiagnostics"] = clangd_publish_diagnostics,
}

local handlers = {
    function(server_name)

        require('lspconfig')[server_name].setup({
            on_attach = M.on_attach,
            capabilities = server_name == "clangd" and clangd_capabilities() or capabilities,
            handlers = server_name == "clangd" and clangd_handlers or nil,

            settings = servers[server_name] and servers[server_name].settings or {},
        })
    end,
}

-- M.capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- 保存自动格式化
M.on_attach = function(client, bufnr)
    --client.offset_encoding = 'utf-16' -- 可能没有用
    if client.server_capabilities.documentFormattingProvider then
        local pos = vim.fn.getpos '.'
        --vim.cmd 'autocmd BufWritePre <buffer> lua vim.lsp.buf.format(format_opts)'
        vim.fn.setpos('.', pos)
    end

end

function M.defaults()
    local mason_lspconfig = require 'mason-lspconfig'
    local ensure = vim.tbl_keys(servers)

    if vim.g.use_custom_clangd then
        ensure = vim.tbl_filter(function(server)
            return server ~= "clangd"
        end, ensure)
    end

    local clangd_installer = require("configs.clangd_installer")
    clangd_installer.setup(function(clangd_path)
        require("lspconfig").clangd.setup({
            on_attach = M.on_attach,
            capabilities = clangd_capabilities(),
            cmd = { clangd_path },
            handlers = clangd_handlers,
            settings = servers.clangd.settings or {},
        })
    end)

    mason_lspconfig.setup({
        ensure_installed = ensure,
    })
    mason_lspconfig.setup_handlers(handlers)
end

--- 只在光标停在标识符（关键字字符）上时才显示 LSP 引用高亮。
---
--- 起因：Snacks.words（snacks 配置里 words = { enabled = true }）会在 CursorMoved /
--- CursorMovedI 之后调用 vim.lsp.buf.document_highlight()，它本身不判断光标停在什么字符上。
--- clangd 对“光标不在任何 token 上”的位置会回落到前一个表达式，例如
---     if(Ss.main_aux_display_mode == MODE_MAIN_REAL_AUX_PAUSE){
---                                     ^光标停在 ')' 上
--- 此时 clangd 依然把 MODE_MAIN_REAL_AUX_PAUSE 这份引用报回来，nvim 就给这段标识符
--- 整段刷上 LspReferenceText 的背景色（catppuccin 下是实心背景），看起来像“右括号前面的
--- 宏莫名其妙亮了”。
---
--- 另外 Snacks.words 自己的判断也有问题：M.get() 拿 extmark 的 end_col（非包含语义）当
--- 包含端点来判“光标是否还在这个词里”（`cursor[2] <= w.to[2]`），所以光标从标识符最后一个
--- 字符右移到紧跟的 ')' 时，它认为还在词内，于是跳过 M.update()、也就不会清掉旧高亮，
--- 旧背景色就会一直残留到光标离开。这种“已经不需要了但没人清”的情况，用拦
--- document_highlight 拦不住（因为压根没再调用），所以额外挂一个 CursorMoved 钩子：
--- 光标落到非关键字字符上就主动把引用高亮抹掉。
function M.gateDocumentHighlight()
    if vim.g.lip_document_highlight_gated then
        return
    end
    vim.g.lip_document_highlight_gated = true

    --- 光标是否落在关键字字符上（\k 走 'iskeyword'，`(`, `)`, `{`, 空格、行尾等都不算）
    local function cursor_on_keyword()
        local ok, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
        if not ok then
            return false
        end
        local char = vim.api.nvim_get_current_line():sub(cursor[2] + 1, cursor[2] + 1)
        return char ~= "" and vim.fn.match(char, [[\k]]) == 0
    end

    local original = vim.lsp.buf.document_highlight

    vim.lsp.buf.document_highlight = function()
        if not cursor_on_keyword() then
            vim.lsp.buf.clear_references()
            return
        end
        return original()
    end

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = vim.api.nvim_create_augroup("lip_document_highlight_gate", { clear = true }),
        callback = function()
            if cursor_on_keyword() then
                return
            end
            vim.lsp.buf.clear_references()
        end,
    })
end

local lspkind_nerd_icons = {
    Array         = "󰅪",
    Boolean       = "⊨",
    Class         = "󰌗",
    Constructor   = "",
    Key           = "󰌆",
    Namespace     = "󰅪",
    Null          = "NULL",
    Number        = "#",
    Object        = "󰀚",
    Package       = "󰏗",
    Property      = "",
    Reference     = "",
    Snippet       = "",
    String        = "󰀬",
    TypeParameter = "󰊄",
    Unit          = "",
}

local lspkind_ascii_icons = {
    Array         = "[]",
    Boolean       = "B",
    Class         = "C",
    Constructor   = "ctor",
    Key           = "K",
    Namespace     = "NS",
    Null          = "NULL",
    Number        = "#",
    Object        = "Obj",
    Package       = "Pkg",
    Property      = "",
    Reference     = "Ref",
    Snippet       = "Snp",
    String        = "Str",
    TypeParameter = "T",
    Unit          = "U",
}

function M.lspkindInit()
    local opts = {
        mode = "symbol",
        symbol_map = use_ascii_icons and lspkind_ascii_icons or lspkind_nerd_icons,
        menu = {},
    }

    require('lspkind').init({
        opts,
    })
end

return M
