-- Compatibility for legacy snipmate snippets using `Filename()` in backticks.
-- LuaSnip evaluates those snippets through Vimscript, so this must be a real
-- Vimscript function rather than a Lua callback stored in vim.fn.
vim.cmd([[
function! Filename(...) abort
    let l:name = expand('%:t:r')

    if l:name ==# ''
        return a:0 >= 2 ? a:2 : ''
    endif

    if a:0 >= 1 && a:1 !=# ''
        return substitute(a:1, '\$1', l:name, 'g')
    endif

    return l:name
endfunction
]])

-- snipmate format
require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.g.snipmate_snippets_path or "" }

-- vscode format
require("luasnip.loaders.from_vscode").lazy_load { exclude = vim.g.vscode_snippets_exclude or {} }
require("luasnip.loaders.from_vscode").lazy_load { paths = vim.g.vscode_snippets_path or "" }

-- lua format
require("luasnip.loaders.from_lua").lazy_load { paths = vim.g.lua_snippets_path or "" }

-- 替换选中的占位符时，不要覆盖系统剪贴板。
local snippet_clipboard
local clipboard_group = vim.api.nvim_create_augroup("LuaSnipPreserveClipboard", { clear = true })

vim.api.nvim_create_autocmd("User", {
    group = clipboard_group,
    pattern = "LuasnipInsertNodeEnter",
    callback = function()
        snippet_clipboard = {
            unnamed = vim.fn.getreginfo('"'),
            plus = vim.fn.getreginfo("+"),
        }
    end,
})

vim.api.nvim_create_autocmd("ModeChanged", {
    group = clipboard_group,
    pattern = "s:i",
    callback = function()
        if not snippet_clipboard then return end

        vim.fn.setreg('"', snippet_clipboard.unnamed)
        vim.fn.setreg("+", snippet_clipboard.plus)
        snippet_clipboard = nil
    end,
})

