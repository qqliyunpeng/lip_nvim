-- 如果经常报错，尝试: rm -rf ~/.local/share/nvim/site/parser
local M = {}

function M.textobjectsConfig()
    require("nvim-treesitter-textobjects").setup {
        select = { lookahead = true, include_surrounding_whitespace = true },
        move = { set_jumps = true },
    }

    local select = require("nvim-treesitter-textobjects.select")
    local move = require("nvim-treesitter-textobjects.move")
    local ts_repeat_move = require "nvim-treesitter-textobjects.repeatable_move"

    local function map_select(key, query, group)
        vim.keymap.set({ "x", "o" }, key, function()
            select.select_textobject(query, group or "textobjects")
        end)
    end

    map_select("af", "@function.outer")
    map_select("if", "@function.inner")
    map_select("as", "@local.scope", "locals")

    local function map_move(key, fn, query, desc)
        vim.keymap.set({ "n", "x", "o" }, key, function()
            if vim.wo.diff and key:find("[cC]", 1, false) then
                vim.cmd("normal! " .. key)
                return
            end
            fn(query, "textobjects")
        end, { desc = desc })
    end

    map_move("]f", move.goto_next_start, "@function.outer", "Next function start")
    map_move("]c", move.goto_next_start, "@class.outer", "Next class start")
    map_move("]a", move.goto_next_start, "@parameter.inner", "Next parameter start")
    map_move("]F", move.goto_next_end, "@function.outer", "Next function end")
    map_move("]C", move.goto_next_end, "@class.outer", "Next class end")
    map_move("]A", move.goto_next_end, "@parameter.inner", "Next parameter end")
    map_move("[f", move.goto_previous_start, "@function.outer", "Previous function start")
    map_move("[c", move.goto_previous_start, "@class.outer", "Previous class start")
    map_move("[a", move.goto_previous_start, "@parameter.inner", "Previous parameter start")
    map_move("[F", move.goto_previous_end, "@function.outer", "Previous function end")
    map_move("[C", move.goto_previous_end, "@class.outer", "Previous class end")
    map_move("[A", move.goto_previous_end, "@parameter.inner", "Previous parameter end")
    -- map_move("]d", move.goto_next, "@conditional.outer")
    -- map_move("[d", move.goto_previous, "@conditional.outer")

    local has_last_move = false

    local function smart_repeat_next()
        if has_last_move then
            ts_repeat_move.repeat_last_move_next()
        else
            move.goto_next_start("@function.outer", "textobjects")
            has_last_move = true
        end
    end

    local function smart_repeat_prev()
        if has_last_move then
            ts_repeat_move.repeat_last_move_previous()
        else
            move.goto_previous_start("@function.outer", "textobjects")
            has_last_move = true
        end
    end

    vim.keymap.set({ "n", "x", "o" }, ";", smart_repeat_next)
    vim.keymap.set({ "n", "x", "o" }, "<a-;>", smart_repeat_prev)
end

function M.treesitterConfig()
    local treesitter = require("nvim-treesitter")
    treesitter.setup()
    treesitter.install({ "c", "make", "lua", "luadoc", "printf", "vim", "vimdoc", "bash", "markdown", "markdown_inline" })

    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            pcall(vim.treesitter.start, args.buf)
        end,
    })
end

return M
