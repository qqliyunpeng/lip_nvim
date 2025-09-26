local M = {}
local map = vim.keymap.set
local use_ascii_icons = require("configs.icons").use_ascii_icons()

local dia_nerd_icons = { Error = "", Warn = "", Hint = "󰌵", Info = "󰋼" }
local dia_ascii_icons = { Error = "E", Warn = "W", Hint = "H", Info = "I" }
local signs = use_ascii_icons and dia_ascii_icons or dia_nerd_icons

for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

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

local handlers = {
    function(server_name)
        local server_setting = {}

        if servers[server_name] and servers[server_name].settings ~= nil then
            server_setting = servers[server_name].settings
        end

        require('lspconfig')[server_name].setup({
            on_attach = M.on_attach,
            capabilities = capabilities,

            settings = server_setting,
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
    mason_lspconfig.setup({
        ensure_installed = vim.tbl_keys(servers),
        handlers = handlers,
    })
    mason_lspconfig.setup_handlers(handlers)
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

