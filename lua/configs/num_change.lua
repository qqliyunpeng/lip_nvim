local M = {}

-- 实现 十进制 十六进制 和 二进制 数的格式的转换
function M.tg_format()
    local function dec_to_bin(n)
        if n == 0 then return "0" end
        local t = {}
        while n > 0 do
            local rest = n % 2
            table.insert(t, 1, rest)
            n = math.floor(n / 2)
        end
        return table.concat(t)
    end

    -- 把十进制字符串乘以 2（返回新的十进制字符串）
    local function str_mul2(dec_str)
        local carry = 0
        local t = {}
        for i = #dec_str, 1, -1 do
            local d = tonumber(dec_str:sub(i, i))
            local prod = d * 2 + carry
            carry = math.floor(prod / 10)
            table.insert(t, 1, tostring(prod % 10))
        end
        if carry > 0 then table.insert(t, 1, tostring(carry)) end
        return table.concat(t)
    end

    -- 把十进制字符串加上 0/1（返回新的十进制字符串）
    local function str_add_small(dec_str, small) -- small = 0 or 1
        local carry = small
        local t = {}
        for i = #dec_str, 1, -1 do
            local d = tonumber(dec_str:sub(i, i))
            local s = d + carry
            carry = math.floor(s / 10)
            table.insert(t, 1, tostring(s % 10))
        end
        if carry > 0 then table.insert(t, 1, tostring(carry)) end
        return table.concat(t)
    end

    -- 二进制字符串（例如 "10101"）安全转十进制字符串
    local function bin_to_dec(bin_str)
        if not bin_str or bin_str == "" then return nil end
        local dec = "0"
        for i = 1, #bin_str do
            local bit = bin_str:sub(i, i)
            if bit == "0" then
                dec = str_mul2(dec)
            elseif bit == "1" then
                dec = str_mul2(dec)
                dec = str_add_small(dec, 1)
            else
                return nil
            end
        end
        return tostring(dec)
    end

    -- 自动识别并转换数字
    local function convert_number(word)
        if word:match("^%d+$") then
            return string.format("0x%X", tonumber(word)) -- dec → hex
        elseif word:match("^0x[0-9a-fA-F]+$") then
            return "0b" .. dec_to_bin(tonumber(word, 16)) -- hex → bin
        elseif word:match("^0b[01]+$") then
            return bin_to_dec(word:sub(3)) -- bin → dec
        else
            return nil
        end
    end

    local function find_number_under_cursor(line, cursor_col)
        local patterns = { "0x[0-9a-fA-F]+", "0b[01]+", "%d+" }

        for _, pat in ipairs(patterns) do
            local start_idx, end_idx = line:find(pat)
            while start_idx do
                if cursor_col >= start_idx and cursor_col <= end_idx then
                    return start_idx, end_idx
                end
                start_idx, end_idx = line:find(pat, end_idx + 1)
            end
        end
        return nil, nil
    end

    -- 支持 dot-repeat: https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
    _G.toggle_number_base_op = function()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2] + 1

        local start_idx, end_idx = find_number_under_cursor(line, col)
        if not start_idx or not end_idx then
            vim.notify("Not a supported number at cursor", vim.log.levels.ERROR)
            return
        end

        local word = line:sub(start_idx, end_idx)
        local new = convert_number(word)
        if not new then
            vim.notify("Not a supported number: " .. word, vim.log.levels.ERROR)
            return
        end

        local new_line = line:sub(1, start_idx - 1) .. new .. line:sub(end_idx + 1)
        vim.api.nvim_set_current_line(new_line)
    end

    _G.toggle_number_base_main = function()
        vim.go.operatorfunc = "v:lua.toggle_number_base_op"
        return "g@l"
    end

    vim.keymap.set("n", "<leader>ux", toggle_number_base_main, { expr = true, desc = "Dec <-> Hex <-> Bin" })
end

-- 将数组按最多一行16个分隔符为一行进行整理（支持单行与多行 { ... } 块）
function M.tg_format_array()
    -- 配置
    local max_items = 16 -- 每行最多元素数
    local supported_separators = { ",", ":", ";" } -- 支持的分隔符

    local function trim(s)
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    local function detect_separator(text)
        for _, s in ipairs(supported_separators) do
            if text:find(s, 1, true) then
                return s
            end
        end
        return nil
    end

    local function split_items(content, sep)
        local items = {}
        local pat = "([^" .. vim.pesc(sep) .. "]+)"
        for part in content:gmatch(pat) do
            local item = trim(part)
            if item ~= "" then
                table.insert(items, item)
            end
        end
        return items
    end

    local function find_brace_block(buf, from_line)
        local line_count = vim.api.nvim_buf_line_count(buf)

        -- Find opening '{' by scanning upward (single buffer read)
        local open_line
        do
            local up = vim.api.nvim_buf_get_lines(buf, 0, from_line + 1, false)
            for i = #up, 1, -1 do
                if up[i] and up[i]:find("{", 1, true) then
                    open_line = i - 1
                    break
                end
            end
        end
        if not open_line then
            return nil, nil
        end

        -- Find closing '}' by scanning downward (single buffer read)
        local close_line
        do
            local down = vim.api.nvim_buf_get_lines(buf, open_line, line_count, false)
            for i, line in ipairs(down) do
                if line and line:find("}", 1, true) then
                    close_line = open_line + (i - 1)
                    break
                end
            end
        end

        if not close_line then
            return nil, nil
        end
        return open_line, close_line
    end

    local function do_format_array_block(buf, start_line, end_line)
        local block = vim.api.nvim_buf_get_lines(buf, start_line, end_line + 1, false)
        if #block == 0 then
            return
        end

        -- Extract: pre { content } post, while supporting multi-line blocks
        local open_pre, after_open = block[1]:match("^(.-){(.*)$")
        if open_pre == nil then
            return
        end

        local before_close, close_post
        if #block == 1 then
            after_open, before_close, close_post = block[1]:match("^(.-){(.*)}(.-)$")
            if after_open == nil then
                return
            end
            open_pre = after_open
            after_open = before_close
            before_close = ""
        else
            before_close, close_post = block[#block]:match("^(.*)}(.-)$")
            if before_close == nil then
                return
            end
        end

        local parts = {}
        table.insert(parts, after_open or "")
        if #block > 2 then
            for i = 2, #block - 1 do
                table.insert(parts, block[i])
            end
        end
        if #block > 1 then
            table.insert(parts, before_close or "")
        end

        local content = table.concat(parts, " ")
        local sep = detect_separator(content)
        if not sep then
            return
        end

        local items = split_items(content, sep)
        if #items == 0 then
            return
        end

        local base_indent = (open_pre:match("^(%s*)") or "")
        local item_indent = base_indent .. "    "

        local out = {}
        table.insert(out, open_pre .. "{")

        local line_buf = item_indent
        for i, item in ipairs(items) do
            line_buf = line_buf .. item
            if i < #items then
                line_buf = line_buf .. sep .. " "
            end

            if i % max_items == 0 and i < #items then
                line_buf = line_buf:gsub("%s+$", "")
                table.insert(out, line_buf)
                line_buf = item_indent
            end
        end

        line_buf = line_buf:gsub("%s+$", "")
        table.insert(out, line_buf)
        table.insert(out, base_indent .. "}" .. (close_post or ""))

        vim.api.nvim_buf_set_lines(buf, start_line, end_line + 1, false, out)
    end

    -- operatorfunc 封装
    _G.op_format_array = function(type)
        local buf = vim.api.nvim_get_current_buf()

        if type == "line" then
            local start_line = vim.fn.line("'<") - 1
            local end_line = vim.fn.line("'>") - 1

            -- Format each distinct { ... } block intersecting the selection.
            local visited = {}
            for l = start_line, end_line do
                local s, e = find_brace_block(buf, l)
                if s and e and not visited[s] then
                    visited[s] = true
                    do_format_array_block(buf, s, e)
                end
            end
            return
        end

        local cur = vim.fn.line(".") - 1
        local s, e = find_brace_block(buf, cur)
        if not s or not e then
            -- Fallback: try current line only
            s, e = cur, cur
        end
        do_format_array_block(buf, s, e)
    end

    vim.keymap.set("n", "<leader>uf", function()
        vim.o.operatorfunc = "v:lua.op_format_array"
        return "g@l"
    end, { expr = true, noremap = true, desc = "Format {} 16 items" })
end

-- 检查数组，如果内容是空格隔开的，改成以逗号隔开
function M.tg_dot_array()
    local supported_separators = { ",", ":", ";" }

    local function has_supported_separator(text)
        -- Fast path: if user already has commas/colons/semicolons, don't touch.
        for _, s in ipairs(supported_separators) do
            if text:find(s, 1, true) then return true end
        end
        return false
    end

    -- Turn "18123 1173  -2912" into "18123, 1173,  -2912," while preserving whitespace.
    -- When add_trailing_comma=false, the last token won't get a trailing comma.
    local function format_space_separated_segment(segment, add_trailing_comma)
        add_trailing_comma = not not add_trailing_comma

        -- Preserve leading indentation (spaces/tabs) exactly.
        local leading = segment:match("^(%s*)") or ""
        segment = segment:sub(#leading + 1)

        local tokens = {}
        local spaces = {}
        for token, space in segment:gmatch("(%S+)(%s*)") do
            table.insert(tokens, token)
            table.insert(spaces, space or "")
        end

        if #tokens <= 1 then
            return leading .. segment
        end

        local out = { leading }
        for i, token in ipairs(tokens) do
            local is_last = i == #tokens
            table.insert(out, token)

            if not is_last then
                table.insert(out, ",")
                table.insert(out, spaces[i] or "")
            else
                if add_trailing_comma then
                    table.insert(out, ",")
                end
                table.insert(out, spaces[i] or "")
            end
        end

        return table.concat(out)
    end

    local function find_last_content_line_idx(lines)
        -- Find the last line that contains *real* content inside the {...} block.
        -- We treat "{" and "}" themselves as non-content.
        for i = #lines, 1, -1 do
            local stripped = (lines[i] or ""):gsub("[{}]", "")
            if stripped:match("%S") then return i end
        end
        return nil
    end

    local function block_has_supported_separator(lines)
        -- Check only the content inside braces, and early-exit on first hit.
        -- This avoids building a big concatenated string.
        local opened = false
        for _, line in ipairs(lines) do
            if not opened then
                local after_open = line:match("{(.*)$")
                if after_open ~= nil then
                    opened = true
                    if has_supported_separator(after_open) then return true end
                end
            else
                local before_close = line:match("^(.*)}")
                if before_close ~= nil then
                    if has_supported_separator(before_close) then return true end
                    break
                end
                if has_supported_separator(line) then return true end
            end
        end
        return false
    end

    -- 处理多行 { ... } 块：当块内不存在 ,/:/; 时，把空格分隔改为逗号分隔
    local function do_dot_array_block(buf, start_line, end_line)
        local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line + 1, false)
        if #lines == 0 then return end

        -- If already comma/colon/semicolon separated, do nothing.
        if block_has_supported_separator(lines) then
            return
        end

        local last_content_idx = find_last_content_line_idx(lines)

        -- Rewrite each line in the block
        for i, line in ipairs(lines) do
            local new_line = line
            local add_trailing_comma = last_content_idx and (i < last_content_idx) or false

            if line:find("{", 1, true) and line:find("}", 1, true) then
                -- Single line: pre { content } post
                local pre, content, post = line:match("^(.-){(.*)}(.-)$")
                if content then
                    -- Single-line: do not add trailing comma
                    new_line = pre .. "{" .. format_space_separated_segment(content, false) .. "}" .. post
                end
            elseif line:find("{", 1, true) then
                -- Opening line: pre { rest
                local pre, rest = line:match("^(.-){(.*)$")
                if rest ~= nil then
                    if rest:match("%S") then
                        new_line = pre .. "{" .. format_space_separated_segment(rest, add_trailing_comma)
                    else
                        new_line = pre .. "{" .. rest
                    end
                end
            elseif line:find("}", 1, true) then
                -- Closing line: before } post
                local before, post = line:match("^(.*)}(.-)$")
                if before ~= nil then
                    local formatted = before
                    if before:match("%S") then
                        formatted = format_space_separated_segment(before, add_trailing_comma)
                    end
                    new_line = formatted .. "}" .. (post or "")
                end
            else
                -- Middle content line
                if line:match("%S") then
                    new_line = format_space_separated_segment(line, add_trailing_comma)
                end
            end

            lines[i] = new_line
        end

        vim.api.nvim_buf_set_lines(buf, start_line, end_line + 1, false, lines)
    end

    local function find_brace_block(buf, from_line)
        local line_count = vim.api.nvim_buf_line_count(buf)

        -- Find opening '{' (1 buffer-read instead of per-line API calls)
        local open_line
        do
            local up = vim.api.nvim_buf_get_lines(buf, 0, from_line + 1, false)
            for i = #up, 1, -1 do
                if up[i] and up[i]:find("{", 1, true) then
                    open_line = i - 1
                    break
                end
            end
        end
        if not open_line then return nil, nil end

        -- Find closing '}' (also with a single buffer-read)
        local close_line
        do
            local down = vim.api.nvim_buf_get_lines(buf, open_line, line_count, false)
            for i, line in ipairs(down) do
                if line and line:find("}", 1, true) then
                    close_line = open_line + (i - 1)
                    break
                end
            end
        end

        if not close_line then return nil, nil end
        return open_line, close_line
    end

    -- operatorfunc wrapper
    _G.op_dot_array = function(type)
        local buf = vim.api.nvim_get_current_buf()
        local start_line, end_line

        if type == "line" then
            start_line = vim.fn.line("'<") - 1
            end_line = vim.fn.line("'>") - 1
        else
            local cur = vim.fn.line(".") - 1
            start_line, end_line = find_brace_block(buf, cur)
            if not start_line or not end_line then
                start_line = cur
                end_line = cur
            end
        end

        do_dot_array_block(buf, start_line, end_line)
    end

    vim.keymap.set("n", "<leader>um,", function()
        vim.o.operatorfunc = "v:lua.op_dot_array"
        return "g@l"
    end, { expr = true, noremap = true, desc = "Space -> Comma in {}" })
end

return M
