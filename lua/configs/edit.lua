
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
            ['prev']   = 'next',
            ['PREV']   = 'NEXT',
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

M.miniFileConfig = function ()
    require('mini.files').setup({})

    local function get_hl_bg(name)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
        if not ok or not hl then
            return nil
        end
        return hl.bg or hl.background
    end

    local original_normalfloat_bg = get_hl_bg("NormalFloat")

    local function open_mini_files()
        require("mini.files").open()
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = 0x000000 }) -- 黑色
    end

    local function restore_color()
        if original_normalfloat_bg then
            vim.api.nvim_set_hl(0, "NormalFloat", { bg = original_normalfloat_bg })
        else
            -- 如果原来没有定义，清除掉即可
            vim.api.nvim_set_hl(0, "NormalFloat", {})
        end
    end

    vim.keymap.set("n", "-", open_mini_files)

    -- 监听 mini.files buffer 关闭，恢复背景
    vim.api.nvim_create_autocmd("BufWipeout", {
        callback = function(args)
            local bufname = vim.api.nvim_buf_get_name(args.buf)
            vim.notify(bufname)
            if bufname:match("^minifiles://") then
                restore_color()
            end
        end,
    })
end

return M

