local M = {}

function M.is_fzf_lua()
    return vim.g.picker_backend == 'fzf-lua'
end

-- 找文件
function M.find_files()
    if M.is_fzf_lua() then
        require('fzf-lua').files()
    else
        require('snacks').picker.files()
    end
end

-- 查找（live grep）
function M.live_grep()
    if M.is_fzf_lua() then
        require('fzf-lua').live_grep()
    else
        require('snacks').picker.grep()
    end
end

-- 查找当前单词/选区
function M.grep_word()
    if M.is_fzf_lua() then
        local fzf = require('fzf-lua')
        if vim.fn.mode():match('[vV]') then
            fzf.grep_visual()
        else
            fzf.grep_cword()
        end
    else
        require('snacks').picker.grep_word({ live = true })
    end
end

-- 当前 buffer 模糊查找
function M.fuzzy_grep()
    if M.is_fzf_lua() then
        require('fzf-lua').blines()
    else
        vim.cmd("Telescope current_buffer_fuzzy_find")
    end
end

return M
