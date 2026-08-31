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

