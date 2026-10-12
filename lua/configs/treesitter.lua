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
    -- 记录最近一次是否已跳到当前函数范围边界，下一次按键才执行函数间移动。
    local range_boundary = nil

    -- 查找光标所在的函数、方法、类或结构体节点。
    local function enclosing_function_or_structure()
        local node = vim.treesitter.get_node()
        while node do
            local node_type = node:type()
            if node_type:find("function", 1, true)
                or node_type:find("method", 1, true)
                or node_type:find("class", 1, true)
                or node_type:find("struct", 1, true)
            then
                return node
            end
            node = node:parent()
        end
        return nil
    end

    local function cursor_position()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        return row - 1, col
    end

    local function before_position(row, col, target_row, target_col)
        return row < target_row or (row == target_row and col < target_col)
    end

    -- 第一次按键时跳到当前范围的起点或终点。
    local function move_to_range_boundary(direction)
        local node = enclosing_function_or_structure()
        if not node then
            return false
        end

        local start_row, start_col, end_row, end_col = node:range()
        local cursor_row, cursor_col = cursor_position()
        local target_row, target_col
        if direction == "next" then
            if not before_position(start_row, start_col, cursor_row, cursor_col) then
                return false
            end
            if not before_position(cursor_row, cursor_col, end_row, end_col) then
                return false
            end
            target_row, target_col = end_row, math.max(end_col - 1, 0)
        else
            if not before_position(start_row, start_col, cursor_row, cursor_col) then
                return false
            end
            target_row, target_col = start_row, start_col
        end

        vim.api.nvim_win_set_cursor(0, { target_row + 1, target_col })
        range_boundary = { direction = direction, row = target_row, col = target_col }
        return true
    end

    local function at_range_boundary(direction)
        if not range_boundary or range_boundary.direction ~= direction then
            return false
        end
        local row, col = cursor_position()
        return row == range_boundary.row and col == range_boundary.col
    end

    -- 正向移动：函数内部先到当前范围末端，再到下一个函数起点。
    local function smart_repeat_next()
        if not at_range_boundary("next") and move_to_range_boundary("next") then
            return
        end
        range_boundary = nil
        if has_last_move then
            ts_repeat_move.repeat_last_move_next()
        else
            move.goto_next_start("@function.outer", "textobjects")
            has_last_move = true
        end
    end

    -- 反向移动：函数内部先到当前范围起点，再到上一个函数起点。
    local function smart_repeat_prev()
        if not at_range_boundary("prev") and move_to_range_boundary("prev") then
            return
        end
        range_boundary = nil
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
    local disabled_filetypes = {
        snacks_dashboard = true,
        AvanteInput = true,
        AvantePromptInput = true,
        AvanteSelectedFiles = true,
    }
    treesitter.setup()
    treesitter.install({ "c", "make", "lua", "luadoc", "printf", "vim", "vimdoc", "bash", "markdown", "markdown_inline" })

    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            if vim.bo[args.buf].buftype == "terminal" or disabled_filetypes[vim.bo[args.buf].filetype] then
                pcall(vim.treesitter.stop, args.buf)
                return
            end
            pcall(vim.treesitter.start, args.buf)
        end,
    })

    vim.api.nvim_create_autocmd("TermOpen", {
        callback = function(args)
            pcall(vim.treesitter.stop, args.buf)
        end,
    })
end

return M
