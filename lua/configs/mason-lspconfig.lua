local M = {}
local map = vim.keymap.set
local mason_lspconfig = require 'mason-lspconfig'

local signs = { Error = "", Warn = "", Hint = "󰌵", Info = "󰋼" }
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
                    globals = { "vim" },
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
        -- local server_config = {
        --     on_attach = M.on_attach,
        --     capabilities = capabilities,
        --     settings = servers[server_name],
        -- }
        -- -- 如果server_name为clangd,设置--offset-encoding=utf-16
        -- if server_name == 'clangd' then
        --     print("yes")
        --     server_config.cmd = {
        --         'clangd',
        --         'offset-encoding=utf-16',
        --     }
        --     server_config.init_options = {
        --         filetypes = { 'c', 'cpp' },
        --         clangdFileStatus = true,
        --         usePlaceholders = true,
        --         completeUnimported = true,
        --         semanticHighlighting = true,
        --         --root_dir = mason_lspconfig.util.root_pattern('compile_commands.json', 'compile_flags.txt', '.git'),
        --     }
        -- end

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

M.capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- 保存自动格式化
M.on_attach = function(client, bufnr)
    print("lip6: on_attach")

    local function opts(desc)
        return { buffer = bufnr, desc = "LSP " .. desc }
    end

    --client.offset_encoding = 'utf-16' -- 可能没有用
    if client.server_capabilities.documentFormattingProvider then
        local pos = vim.fn.getpos '.'
        --vim.cmd 'autocmd BufWritePre <buffer> lua vim.lsp.buf.format(format_opts)'
        vim.fn.setpos('.', pos)
    end

    -- client.offset_encoding = 'utf-8',

    map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
    map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
    map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
    -- map("n", "gr", vim.lsp.buf.references, opts "Go to references")
    map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts "Show references")
    -- map("n", "gr", require('telescope.builtin').lsp_references(), opts "Go to references")
    map("n", "<leader>sh", vim.lsp.buf.signature_help, opts "Show signature help")
    map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
    map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

    map("n", "<leader>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts "List workspace folders")

    map("n", "<leader>d", vim.lsp.buf.type_definition, opts "Go to type definition")
    -- map("n", "<leader><leader>ra", require "nvchad.lsp.renamer", opts "NvRenamer")

    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")
    -- map("n", "gr", vim.lsp.buf.references, opts "Show references")
end

M.defaults = function()
  -- dofile(vim.g.base46_cache .. "lsp")
  -- require("nvchad.lsp").diagnostic_config()

    mason_lspconfig.setup({
        ensure_installed = vim.tbl_keys(servers),
        handlers = handlers,
    })
    mason_lspconfig.setup_handlers(handlers)
end

return M

