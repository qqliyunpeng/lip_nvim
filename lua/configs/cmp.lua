-- dofile(vim.g.base46_cache .. "cmp")

local cmp = require "cmp"
local luasnip = require 'luasnip'
local lspkind = require 'lspkind'

local options = {
  completionopt = { completeopt = "menu,menuone,noinsert" },

  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },

  mapping = cmp.mapping.preset.insert {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),

    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    -- ["<CR>"] = cmp.mapping.confirm {
    --   behavior = cmp.ConfirmBehavior.Insert,
    --   select = true,
    -- },

    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        require("luasnip").expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        require("luasnip").jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },

  sources = {
    { name = "nvim_lsp", priority = 1000, group_index = 1 },
    { name = "luasnip" , priority = 900, group_index = 1 },
    { name = "buffer" , group_index = 2 },
    { name = "nvim_lua", group_index = 2 },
    { name = "path", group_index = 2 },
  },

  window = {
        completion = {
            border = 'rounded', -- 使用圆角边框
            winhighlight = 'NormalFloat:Pmenu,FloatBorder:FloatBorder', -- 自定义高亮
            -- winhighlight = 'NormalFloat:Pmenu,FloatBorder:FloatBorder', -- 自定义高亮
        },
        documentation = {
            border = 'rounded', -- 使用圆角边框
            winhighlight = 'NormalFloat:Pmenu,FloatBorder:FloatBorder', -- 自定义高亮
        },
    },
    -- 自定义高亮颜色
    vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#ffffff', bg = '#282828' }), -- 设置边框颜色

    formatting = {
        -- format = function(entry, vim_item)
        --     -- 自定义格式化
        --     if vim_item.king == "Function" or vim_item.kind then
        --         vim_item.menu = " " .. vim_item.kind -- 在前面添加类型
        --     end
        --     return vim_item
        -- end,

        -- format = require('lspkind').cmp_format({
        --     with_text = true,
        --     menu = {
        --         buffer = "[Buffer]",
        --         nvim_lsp = "[LSP]",
        --         nvim_lua = "[Lua]",
        --     },
        -- }),

        format = require('lspkind').cmp_format({
            mode = 'symbol',
            maxwidth = {
                menu = 50,
                abbr = 50,
            },
            ellipsis_char = '...',
            show_labelDetails = true,
            before = function (entry, vim_item)
                -- vim_item.kind = require('lspkind').symbolic(vim_item.kind, { with_text = true })
                -- 获取图标并将其放在文本前面
                -- local icon = lspkind.presets.default[vim_item.kind] .. ' '
                -- vim_item.kind = icon .. vim_item.kind -- 将图标添加到文本前面

                -- vim_item.menu = ({
                --     buffer = "[Buffer]",
                --     nvim_lsp = "[LSP]",
                --     nvim_lua = "[Lua]",
                -- })[entry.source.name] or ""

                return vim_item
            end
        })
    },
}

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline({ '/', '?' }, {
--     mapping = cmp.mapping.preset.cmdline(),
--     sources = {
--         { name = 'buffer' },
--     },
-- })

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline(':', {
--     mapping = cmp.mapping.preset.cmdline(),
--     sources = cmp.config.sources({
--         { name = 'path' },
--     }, {
--         { name = 'cmdline' },
--     }),
-- })
--

return options


