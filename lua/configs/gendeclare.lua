
local M = {}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize_space(value)
    return trim(value:gsub("%s+", " "))
end

local function normalize_declaration(value)
    return normalize_space(value)
        :gsub("%(%s+", "(")
        :gsub("%s+%)", ")")
        :gsub("%s+;", ";")
end

local function pesc(value)
    if vim and vim.pesc then
        return vim.pesc(value)
    end

    return (value:gsub("([^%w])", "%%%1"))
end

local function strip_function_body(lines)
    local text = table.concat(lines, "\n")
    text = text:gsub("%s*{.*$", "")
    return normalize_declaration(text)
end

local function is_static_signature(signature)
    return signature:match("^static%s+") ~= nil or
        signature:match("^inline%s+static%s+") ~= nil or
        signature:match("^static%s+inline%s+") ~= nil
end

local function get_function_name(signature)
    local before_paren = signature:match("^(.-)%s*%(")
    if not before_paren then
        return nil
    end

    return before_paren:match("([_%a][_%w:~]*)%s*$")
end

local function build_declaration(lines, ft)
    local signature = strip_function_body(lines)
    if signature == "" or is_static_signature(signature) then
        return nil
    end

    signature = signature:gsub("^inline%s+", "")
    signature = signature:gsub("%s*;%s*$", "")

    if ft == "c" and not signature:match("^extern%s+") then
        signature = "extern " .. signature
    end

    return signature .. ";"
end

local function get_parser_root(bufnr, ft)
    if ft ~= "c" and ft ~= "cpp" then
        vim.notify("just support C/C++", vim.log.levels.WARN)
        return nil
    end

    -- 兼容 0.9/0.10/0.11 的查询接口
    local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
    if not ok_parser or not parser then
        vim.notify("can't find Treesitter parser，need :TSInstall " .. ft, vim.log.levels.ERROR)
        return nil
    end

    local tree = parser:parse()[1]
    return tree:root()
end

local function get_function_lines(bufnr, node)
    local start_row, _, end_row = node:range()
    return vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
end

local function collect_functions(bufnr, ft, root)
    local parse_query = vim.treesitter.query.parse or vim.treesitter.parse_query

    -- 捕获函数定义节点本体，方便拿到起始行
    local query = parse_query(ft, [[
        (function_definition) @func
    ]])

    local funcs = {}
    for id, node in query:iter_captures(root, bufnr, 0, -1) do
        if query.captures[id] == "func" then
            local start_row, _, end_row = node:range()
            local signature = strip_function_body(get_function_lines(bufnr, node))
            table.insert(funcs, {
                node = node,
                start_row = start_row,
                end_row = end_row,
                name = get_function_name(signature),
                is_static = is_static_signature(signature),
            })
        end
    end

    table.sort(funcs, function(left, right)
        return left.start_row < right.start_row
    end)

    return funcs
end

local function find_current_function(funcs, cur_row)
    for i, func in ipairs(funcs) do
        if func.start_row <= cur_row and cur_row <= func.end_row then
            return i, func
        end
    end

    return nil, nil
end

local function nearest_anchor(funcs, index)
    for i = index + 1, #funcs do
        if not funcs[i].is_static and funcs[i].name then
            return funcs[i].name, "up"
        end
    end

    for i = index - 1, 1, -1 do
        if not funcs[i].is_static and funcs[i].name then
            return funcs[i].name, "down"
        end
    end

    return nil, nil
end

local function header_candidates(source)
    local dir = vim.fn.fnamemodify(source, ":h")
    local base_name = vim.fn.fnamemodify(source, ":t:r")
    local exts = { ".h", ".hpp", ".hh", ".hxx" }
    local results = {}
    local seen = {}

    local function add(path)
        if path and path ~= "" and not seen[path] and vim.fn.filereadable(path) == 1 then
            seen[path] = true
            table.insert(results, path)
        end
    end

    for _, ext in ipairs(exts) do
        add(dir .. "/" .. base_name .. ext)
    end

    for _, ext in ipairs(exts) do
        local matches = vim.fn.globpath(vim.loop.cwd(), "**/" .. base_name .. ext, false, true)
        for _, path in ipairs(matches) do
            add(path)
        end
    end

    return results
end

local function open_header()
    local base_name = vim.fn.expand("%:t:r")
    local results = header_candidates(vim.fn.expand("%:p"))
    if #results == 0 then
        vim.notify("not find header for: " .. base_name, vim.log.levels.WARN)
        return false
    end

    vim.cmd("edit " .. vim.fn.fnameescape(results[1]))
    return true
end

local function search_word_in_lines(lines, word)
    -- 构造全词匹配的 Lua 模式，%f[%w] 表示词边界
    local pattern = "%f[%w]" .. pesc(word) .. "%f[%W]"

    for i, line in ipairs(lines) do
        if line:match(pattern) then
            return i
        end
    end

    return nil
end

local function declaration_exists(lines, declaration)
    local wanted = normalize_declaration(declaration)
    local statement = ""

    for _, line in ipairs(lines) do
        statement = trim(statement .. " " .. trim(line))

        if statement ~= "" and normalize_declaration(statement) == wanted then
            return true
        end

        if line:match(";") then
            statement = ""
        end
    end

    return false
end

local function find_preamble_end(lines)
    local insert_row = 0

    for i, line in ipairs(lines) do
        local text = trim(line)
        if text == "" or text == "#pragma once" or text:match("^#ifndef%s+") or
            text:match("^#define%s+") or text:match("^#include%s+") then
            insert_row = i
        elseif text:match('^extern%s+"C"%s*{') then
            insert_row = i
        else
            break
        end
    end

    return insert_row
end

local function find_insert_row(lines, declaration, anchor, direction)
    if anchor then
        local row = search_word_in_lines(lines, anchor)
        if row then
            if direction == "up" then
                return row - 1
            end
            return row
        end

        local short_anchor = anchor:match("([^:~]+)$")
        if short_anchor and short_anchor ~= anchor then
            row = search_word_in_lines(lines, short_anchor)
            if row then
                if direction == "up" then
                    return row - 1
                end
                return row
            end
        end
    end

    return find_preamble_end(lines)
end

function M.create_declare()
    -- 记录跳转前的 buffer 和光标位置
    local origin_buf = vim.api.nvim_get_current_buf()
    local origin_pos = vim.api.nvim_win_get_cursor(0)
    local ft = vim.bo.filetype
    local root = get_parser_root(origin_buf, ft)
    if not root then
        return
    end

    local funcs = collect_functions(origin_buf, ft, root)
    local current_index, current_func = find_current_function(funcs, origin_pos[1] - 1)
    if not current_func then
        vim.notify("not in function definition", vim.log.levels.WARN)
        return
    end

    local declaration = build_declaration(get_function_lines(origin_buf, current_func.node), ft)
    if not declaration then
        vim.notify("skip static or empty function declaration", vim.log.levels.WARN)
        return
    end

    local anchor, direction = nearest_anchor(funcs, current_index)
    if not open_header() then
        return
    end

    local header_buf = vim.api.nvim_get_current_buf()
    local header_lines = vim.api.nvim_buf_get_lines(header_buf, 0, -1, false)
    if declaration_exists(header_lines, declaration) then
        vim.notify("declaration already exists")
    else
        local insert_row = find_insert_row(header_lines, declaration, anchor, direction)
        vim.api.nvim_buf_set_lines(header_buf, insert_row, insert_row, false, { declaration })
        vim.api.nvim_command("write")
    end

    vim.api.nvim_set_current_buf(origin_buf)
    vim.api.nvim_win_set_cursor(0, origin_pos)
end

-- lua/tests/gendeclare_spec.lua 覆盖：
-- - 多行 C 函数定义会转换为 extern 声明
-- - static 和 inline static 函数会被跳过
-- - static inline 函数同样会被跳过
-- - C++ 声明保留尾随限定符，并且不会强制添加 extern
-- - 已存在的多行声明会被识别，避免重复插入
-- - 没有锚点时，插入位置回退到头文件前导部分之后
-- - 有可用锚点时，插入位置使用最近的函数声明锚点
M._test = {
    build_declaration = build_declaration,
    declaration_exists = declaration_exists,
    find_insert_row = find_insert_row,
}

return M

