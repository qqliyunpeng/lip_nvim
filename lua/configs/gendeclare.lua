
local M = {}

local function goto_func_name()
    local bufnr = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row, _ = pos[1], pos[2]
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""

    -- 找到 "(" 并移动到它的前一个字符
    local col = string.find(line, "%(")
    if col and col > 1 then
        vim.api.nvim_win_set_cursor(0, { row, col - 2 })
    end
end

-- 跳到下一个函数，并报告是否有 static/inline 修饰
local goto_next_function = function (direction)
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.bo.filetype
    if ft ~= "c" and ft ~= "cpp" then
        vim.notify("just support C/C++", vim.log.levels.WARN)
        return false
    end

    -- 兼容 0.9/0.10/0.11 的查询接口
    local parse_query = vim.treesitter.query.parse or vim.treesitter.parse_query
    local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
    if not ok_parser or not parser then
        vim.notify("can't find Treesitter parser，need :TSInstall " .. ft, vim.log.levels.ERROR)
        return false
    end

    local tree = parser:parse()[1]
    local root = tree:root()
    local cur_row = vim.api.nvim_win_get_cursor(0)[1] - 1

    -- 捕获函数定义节点本体，方便拿到起始行
    local query = parse_query(ft, [[
        (function_definition
            declarator: (function_declarator) @decl) @func
    ]])

    local best_row = nil
    for id, node in query:iter_captures(root, bufnr, 0, -1) do
        if query.captures[id] == "func" then
            local start_row = select(1, node:range())
            if direction == "down" and start_row > cur_row then
                local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
                if not (line:match("^%s*static") or line:match("^%s*inline")) then
                    if not best_row or start_row < best_row then
                        best_row = start_row
                    end
                end
            elseif direction == "up" and start_row < cur_row then
                local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
                if not (line:match("^%s*static") or line:match("^%s*inline")) then
                    if not best_row or start_row > best_row then
                        best_row = start_row
                    end
                end
            end
        end
    end

    if best_row then
        vim.api.nvim_win_set_cursor(0, { best_row + 1, 0 })
        return true
    end

    return false
end

local function open_file()
    local base_name = vim.fn.expand('%:t:r')
    local pattern = '**/' .. base_name .. '.h'  -- 递归搜索所有子目录

    -- 在当前工作目录递归查找匹配文件，结果是字符串（多个文件以换行分隔）
    local results = vim.fn.globpath(vim.loop.cwd(), pattern, false, true)

    if #results == 0 then
        vim.notify('not find: ' .. base_name .. '.h', vim.log.levels.WARN)
        return false
    end

    -- 打开第一个匹配的文件
    vim.cmd('edit ' .. results[1])
    return true
end

local function search_word(word)
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- 构造全词匹配的 Lua 模式，%f[%w] 表示词边界
    local pattern = "%f[%w]" .. vim.pesc(word) .. "%f[%W]"

    for i, line in ipairs(lines) do
        if line:match(pattern) then
            vim.api.nvim_win_set_cursor(0, {i, 0})
            return true
        end
    end

    return false
end

local function insert_line_relative(direction, line_content)
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1]  -- 当前行号，1-based

    if direction == "up" then
        -- 在当前行上方插入
        vim.api.nvim_buf_set_lines(bufnr, row - 1, row - 1, false, { line_content })
    elseif direction == "down" then
        -- 在当前行下方插入
        vim.api.nvim_buf_set_lines(bufnr, row, row, false, { line_content })
    else
        vim.notify("insert_line_relative: direction must be 'up' or 'down'", vim.log.levels.ERROR)
    end
end

M.create_declare = function ()
    -- 记录跳转前的 buffer 和光标位置
    local origin_buf = vim.api.nvim_get_current_buf()
    local origin_pos = vim.api.nvim_win_get_cursor(0)

    -- 获取当前行
    local line = vim.api.nvim_get_current_line()
    line = line:gsub("%s*{.*$", "")
    line = line:gsub("%)%s*.*$", ")")
    line = "extern " .. line .. ";"

    if goto_next_function("down") then
        goto_func_name()
        local word_cur = vim.fn.expand("<cword>")
        if not open_file() then
            return
        end
        if not search_word(word_cur) then
            vim.notify("not find: " .. word_cur)
            return
        end
        insert_line_relative("up", line)

    elseif goto_next_function("up") then
        goto_func_name()
        local word_cur = vim.fn.expand("<cword>")
        if not open_file() then
            return
        end
        if not search_word(word_cur) then
            vim.notify("not find: " .. word_cur)
            return
        end
        insert_line_relative("down", line)
    end

    vim.api.nvim_command('write')
    vim.api.nvim_set_current_buf(origin_buf)
    vim.api.nvim_win_set_cursor(0, origin_pos)
end

return M

