-- function: 实现 十进制 十六进制 和 二进制 数的格式的转换
local M = {}

M.toggle_format = function ()
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
    _G.toggle_number_base_op = function ()
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

return M

