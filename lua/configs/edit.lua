
local M = {}

M.miniSurroundConfig = function ()
    require'mini.surround'.setup({
        mappings = {
            add = '<leader>sa',
            delete = '<leader>sd',
            replace = '<leader>sc',
            find = '<leader>sf',
            find_left = '<leader>sF',
            highlight = '<leader>sh',
            update_n_lines = '<leader>sn',

            suffix_last = 'l',
            suffix_next = 'n',
        }
    })
end

M.yankKeys = {
    { "<C-p>", function() require('telescope').extensions.yank_history.yank_history({}) end, desc = "Open Yank History" },
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
    -- { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after cursor" },
    -- { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before cursor" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after selection" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before selection" },
    -- 在已经粘贴的上边换成列表中之前的一个
    { "]y", "<Plug>(YankyPreviousEntry)", desc = "Select previous entry through yank history" },
    { "[y", "<Plug>(YankyNextEntry)", desc = "Select next entry through yank history" },
    { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
    { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
    { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
    { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
    { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and indent right" },
    { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and indent left" },
    { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put before and indent right" },
    { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put before and indent left" },
    { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put after applying a filter" },
    { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put before applying a filter" },
}

M.yankConfig = function ()
    local utils = require("yanky.utils")
    local mapping = require("yanky.telescope.mapping")

    require('yanky').setup({
        ring = {
            history_length = 100,
            storage = "shada",
        },
        highlight = {
            on_put = true,
            on_yank = true,
            timer = 150,
        },
        preserve_cursor_position = {
            enabled = true,
        },
        textobj = {
            enable = false,
        },
        picker = {
            telescope = {
                use_default_mappings = false,
                mappings = {
                    default = mapping.put("p"),
                    i = {
                        ["<c-x>"] = mapping.delete(),
                        ["<c-r>"] = mapping.set_register(utils.get_default_register()),
                    },
                    n = {
                        p = mapping.put("p"),
                        P = mapping.put("P"),
                        d = mapping.delete(),
                        r = mapping.set_register(utils.get_default_register()),
                    },
                }
            }
        },
    })

    vim.cmd([[
    hi! link YankyPut    Cursearch
    hi! link YankyYanked Cursearch
    ]])

    vim.keymap.set("i", "<C-p>", function()
        require("telescope").extensions.yank_history.yank_history({})
    end, { silent = true, desc = "Yank history in insert mode" })
end

M.nvimToggleConfig = function ()
    require('nvim-toggler').setup({
        inverses = {
            ['YES']    = 'NO',
            ['ON']     = 'OFF',
            ['UP']     = 'DOWN',
            ['LEFT']   = 'RIGHT',
            ['TRUE']   = 'FALSE',
            ['ENABLE'] = 'DISABLE',
            ['GET']    = 'SET',
            ['get']    = 'set',
            ['SHOW']   = 'HIDE',
            ['show']   = 'hide',
            ['top']    = 'bottom',
            ['TOP']    = 'BOTTOM',
        },
        -- removes the default <leader>i keymap
        remove_default_keybinds = true,
        -- auto-selects the longest match when there are multiple matches
        autoselect_longest_match = false
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>ui', require('nvim-toggler').toggle,
                                                    { desc = "True <-> False" })
end

M.visualMulConfig = function ()
    local npairs = require("nvim-autopairs")

    -- 单独禁用/启用 BS
    local function disable_bs_now()
        vim.keymap.del("i", "<BS>", { buffer = 0 })
    end

    local function restore_bs_now()
        vim.api.nvim_buf_set_keymap(
            0,  -- 当前 buffer
            "i",
            "<BS>",
            "",  -- 必须给个空字符串，callback 会覆盖执行逻辑
            {
                callback = npairs.autopairs_bs,
                expr = true,
                noremap = true,
            }
        )
    end

    vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_start",
        callback = function ()
            disable_bs_now()
            vim.keymap.set("n", "<A-q>", "<cmd>call vm#reset()<CR>")
        end
    })
    vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_exit",
        callback = function ()
            restore_bs_now()
            vim.keymap.set("n", "<A-q>", "<Esc><cmd>noh<CR>")
        end
    })
end

M.pasteSmart = function ()
    local clipboard_content = vim.fn.getreg('"')
    local ends_with_newline = clipboard_content:sub(-1) == '\n'

    if clipboard_content == nil or not ends_with_newline then
        vim.cmd('execute "normal \\<Plug>(YankyPutAfter)"')
        return
    end

    if ends_with_newline then
        vim.cmd('execute "normal \\<Plug>(YankyPutAfterFilter)"')
    end
end

M.PasteSmart = function ()
    local clipboard_content = vim.fn.getreg('"')
    local ends_with_newline = clipboard_content:sub(-1) == '\n'

    if clipboard_content == nil or not ends_with_newline then
        vim.cmd('execute "normal \\<Plug>(YankyPutBefore)"')
        return
    end

    if ends_with_newline then
        vim.cmd('execute "normal \\<Plug>(YankyPutBeforeFilter)"')
    end
end

--- Supports dec / hex / bin / oct
--- Respects parentheses and keeps original prefix case
local function evaluate_func(mode)
    local text = table.concat(mode.lines, "\n")
    text = vim.trim(text or "")
    if text == "" then return text end

    -- 保留括号和空格
    local prefix, inner, suffix = text:match("^(%s*%(*)(.-)(%)*%s*)$")
    if not inner or inner == "" then return text end

    local chunk, _ = load("return " .. inner)
    if not chunk then return text end
    local ok, result = pcall(chunk)
    if not ok then return text end

    -- 如果是 0x / 0X 开头的十六进制，保持大小写
    if inner:match("^0[xX]") then
        local fmt = inner:match("^0x") and "0x%X" or "0X%X"
        return prefix .. string.format(fmt, result) .. suffix
    else
        return prefix .. tostring(result) .. suffix
    end
end

M.operatorsConfig = function ()
    require("mini.operators").setup({
        -- 计算
        evaluate = {
            prefix = 'gz=',
            func = evaluate_func,
        },
        -- 交换
        exchange = {
            prefix = 'gzx',
        },
        -- 向下复制一行当前的内容
        multiply = {
            prefix = 'gzc',
        },
        -- 将寄存器中的内容复制到当前行
        replace = {
            prefix = 'gzr',
        },
        -- 排序
        sort = {
            prefix = 'gzs',
        }
    })
end

M.toggleNumFormat = function ()
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
            vim.notify("Not a supported number at cursor")
            return
        end

        local word = line:sub(start_idx, end_idx)
        local new = convert_number(word)
        if not new then
            vim.notify("Not a supported number: " .. word)
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

