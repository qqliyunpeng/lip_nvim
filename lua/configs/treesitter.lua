
local M = {}

M.treesitterConfig = {
    ensure_installed = { "c", "make", "lua", "luadoc", "printf", "vim", "vimdoc" },

    highlight = {
        enable = true,
        use_languagetree = true,
    },

    indent = { enable = false },

    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "<nop>",
            node_incremental = "v",
            scope_incremental = false,
            node_decremental = "<bs>", -- backspace 键
        },
    },

    textobjects = {
        select = {
            enable = true,
            lookahead = true,

            keymaps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
                ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
            },

            include_surrounding_whitespace = true,
        },
        move = {
            enable = true,
            set_jumps = true,
            goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
            goto_next_end   = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
            goto_previous_end   = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },


            goto_next     = { ["]d"] = "@conditional.outer", },
            goto_previous = { ["[d"] = "@conditional.outer", },
        }
    },
}

M.textobjectsConfig = function()
    -- If treesitter is already loaded, we need to run config again for textobjects
    -- When in diff mode, we want to use the default, 在 diff窗口中仍然使用默认的vim的配置，比如 ]c
    -- vim text objects c & C instead of the treesitter ones.
    local move = require("nvim-treesitter.textobjects.move") ---@type table<string,fun(...)>
    local configs = require("nvim-treesitter.configs")
    for name, fn in pairs(move) do
        if name:find("goto") == 1 then
            move[name] = function(q, ...)
                if vim.wo.diff then
                    local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
                    for key, query in pairs(config or {}) do
                        if q == query and key:find("[%]%[][cC]") then
                            vim.cmd("normal! " .. key)
                            return
                        end
                    end
                end
                return fn(q, ...)
            end
        end
    end
end

return M

