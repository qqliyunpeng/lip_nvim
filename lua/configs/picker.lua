local M = {}

-- picker 后端开关：'fff' 或 'snacks'
-- 影响的键位：<leader>p / <leader>ff 找文件，<leader>fw / <leader>fc 查找
M.backend = 'snacks'

-- 当前是否使用 fff；plugins/lip_plugins.lua 也用它决定是否加载 fff.nvim
function M.is_fff()
    return M.backend == 'fff'
end

-- 找文件
function M.find_files()
    if M.is_fff() then
        require('fff').find_files()
    else
        require('snacks').picker.files()
    end
end

-- 查找（live grep）
function M.live_grep()
    if M.is_fff() then
        require('fff').live_grep()
    else
        require('snacks').picker.grep()
    end
end

-- 查找当前单词/选区
function M.grep_word()
    if M.is_fff() then
        require('fff').live_grep_under_cursor()
    else
        require('snacks').picker.grep_word({ live = true })
    end
end

-- 当前 buffer 模糊查找（fff 后端下为 FFF fuzzy grep，只保留 fuzzy/plain 模式）
function M.fuzzy_grep()
    if M.is_fff() then
        require('fff').live_grep({ grep = { modes = { 'fuzzy', 'plain' } } })
    else
        vim.cmd("Telescope current_buffer_fuzzy_find")
    end
end

return M
