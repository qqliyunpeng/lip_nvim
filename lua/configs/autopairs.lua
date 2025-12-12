local M = {}

function M.setup(opts)
    local npairs = require("nvim-autopairs")
    local Rule = require("nvim-autopairs.rule")
    local cond = require("nvim-autopairs.conds")
    local ts_conds = require("nvim-autopairs.ts-conds")

    -- 默认配置
    local defaults = {
        check_ts = true,
        enable_moveright = true,
        map_cr = true,
        map_bs = true,
        enable_afterquote = true,
        fast_wrap = {},
        disable_filetype = { "TelescopePrompt", "vim" },
    }

    -- 合并 opts (优先使用外部传入的)
    opts = vim.tbl_deep_extend("force", defaults, opts or {})

    -- 基本配置
    npairs.setup(opts)

    -- 自动补全括号/引号
    local pairs = { {"(",")"}, {"[","]"}, {"{","}"}, {'"','"'},{ "'", "'" } }
    for _, p in ipairs(pairs) do
        npairs.add_rule(Rule(p[1], p[2]))
    end

    -- 空格补全两个空格
    npairs.add_rules({
        Rule(" ", " ")
        :with_pair(function(context)
            local pair = context.line:sub(context.col - 1, context.col)
            return vim.tbl_contains({ "()", "[]", "{}", "\'\'", "\"\"" }, pair)
        end)
    })

    -- Treesitter 高级支持: 字符串和注释中禁止自动配对
    for _, p in ipairs(pairs) do
        npairs.add_rule(
        Rule(p[1], p[2])
        :with_pair(ts_conds.is_not_ts_node({'string','comment'}))
        )
    end


    -- 自动补全开关
    Snacks.toggle({
        name = "autopairs",
        get = function()
            return npairs.state.disabled == false
        end,
        set = function(state)
            if state then
                npairs.enable()
            else
                npairs.disable()
            end
        end,
    }):map("<leader>ua")
end

return M

