
local map = vim.keymap.set
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- clangd 要不要使用国内源
local cus = os.getenv("CLANGD_USE_GITHUB") == "1"
if cus then
    vim.g.use_custom_clangd = false
else
    vim.g.use_custom_clangd = true
end

local copilot_auto_trigger = (os.getenv("COPILOT_AUTO_TRIGGER") or ""):lower()
vim.g.blink_enable_copilot = copilot_auto_trigger == "1"
    or copilot_auto_trigger == "true"
    or copilot_auto_trigger == "yes"
    or copilot_auto_trigger == "on"

-- system
map("n", " ", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")
map("v", "q", "<Esc>")
map("n", "<a-q>", "<Esc><cmd>noh<CR>")
map("x", "<a-q>", "<Esc>")
map("n", "<leader>q", "<cmd>q<CR>",  { desc = "CMD quit" })
map("n", "<leader>x", "<cmd>qa<CR>", { desc = "CMD quit all" })

require('options')

vim.env.TREE_SITTER_BOOTSTRAP_URL = "https://gitcode.net/CAPYIN/nvim-treesitter"

vim.api.nvim_create_augroup('MyVimEnterGroup', { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "man", "lspinfo", "checkhealth", "qf" },
    callback = function()
        vim.keymap.set("n", "q", "<cmd>quit<cr>", { buffer = true, silent = true })
    end,
})

-- force *.h files to use c filetype
-- force *.hpp files to use cpp filetype
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.h",
    callback = function()
        local fname = vim.fn.expand("%:p")
        local dir = vim.fn.fnamemodify(fname, ":h")

        -- 向上查找工程根目录
        local function find_root(path)
            local markers = { "CMakeLists.txt", "meson.build", ".git" }
            for _, m in ipairs(markers) do
                if vim.fn.filereadable(path .. "/" .. m) == 1 or vim.fn.isdirectory(path .. "/" .. m) == 1 then
                    return path
                end
            end
            local parent = vim.fn.fnamemodify(path, ":h")
            if parent == path then return nil end
            return find_root(parent)
        end

        local root = find_root(dir) or dir
        local has_cpp = vim.fn.glob(root .. "/*.cpp") ~= ""

        if has_cpp then
            vim.bo.filetype = "cpp"
        else
            vim.bo.filetype = "c"
        end
    end,
})

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.notify("lip: Begin to download lazy.nvim ...")
    local repo = "https://gitee.com/nvim_lip/lazy.nvim"
    local out = vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=main", lazypath }
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg"  },
            { out, "WarningMsg"  },
            { "\nPress any key to exit..."  },

        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
    { import = "plugins" },
}, lazy_config)

require('mappings')

-- ui or color
vim.cmd.colorscheme "onedark"

-- IlluminatedWordText have problem
vim.cmd([[
hi! link IlluminatedWordText Search
hi! link IlluminatedWordRead HlSearchLens
hi! link IlluminatedWordWrite  HlSearchLens
"hi Normal guibg=NONE ctermbg=NONE
hi Normal guibg=black ctermbg=black
"hi NormalNC guibg=black ctermbg=black
hi LineNr guibg=NONE ctermbg=NONE
" 当前行
hi CursorLine guibg=#2a2b3c ctermbg=235
" 当前行号
hi CursorLineNr cterm = bold gui = bold guifg=#ff966c
" 搜索的结果中当前的块的背景颜色
hi CurSearch guibg=#ff966c
" set guicursor=n-v-c-sm:block-CursorLineNr,i-ci-ve:ver25,r-cr-o:hor20
hi Search guifg=#c8d3f5 guibg=#3e68d7
" 弹出的窗口右侧的下拉框的颜色
hi PmenuThumb guibg=#c678dd ctermbg=127
hi MiniIndentscopeSymbol guifg=#589ed7 guibg=NONE
hi GrugFarResultsMatch      guifg=#1b1d2b guibg=#ff757f
hi GrugFarResultsMatchAdded guifg=#1b1d2b guibg=#589ed7
hi! link GrugFarResultsMatchRemoved GrugFarResultsMatch
hi GrugFarResultsHeader     guifg=#ff966c guibg=NONE
hi! link VM_Cursor GrugFarResultsMatch
hi! link VM_Extend GrugFarResultsMatchAdded
hi! link VM_Mono   GrugFarResultsMatchAdded
hi! link VM_Insert GrugFarResultsMatch
hi! link BlinkCmpMenu       Normal
hi! link BlinkCmpMenuBorder Normal
hi! link BlinkCmpDoc        Normal
hi! link BlinkCmpDocBorder  Normal
hi! link BlinkCmpDocCursorLine  Normal
hi! link BlinkCmpDocSeparator   Normal
hi! link BlinkCmpMenuSelection  CursorLine
hi! link HoverNormal Normal
hi! link HoverBorder Normal
hi! link SagaNormal  Normal
hi! link SagaBorder  Normal
hi! link WhichKeyBorder  Normal
hi! link WhichKeyNormal  Normal
hi FloatBorder   guibg=Black
hi FlashBackdrop guifg=#6c7086
hi FlashCurrent  guifg=#fab387
hi FlashMatch    guifg=#b4befe
hi FlashLabel    cterm=bold gui=bold guifg=#a6e3a1 guibg=#1e1e2e
hi! link FlashPrompt NormalFloat

" hi LspReferenceRead  guibg=#45475a
" hi LspReferenceText  guibg=#45475a
" hi LspReferenceWrite guibg=#45475a
hi LspReferenceText guifg=NONE guibg=NONE

hi IlluminatedWordText  guibg=#45475a
hi IlluminatedWordWrite guibg=#45475a
hi IlluminatedWordRead  guibg=#45475a

hi BlinkCmpKindYank  guifg=#8957E5

hi TelescopeNormal        guibg=black ctermbg=black
hi TelescopePromptNormal  guibg=Black
hi TelescopePreviewLine   guibg=Black
hi TelescopePreviewBorder guibg=Black
hi TelescopePromptBorder  guifg=#ff966c guibg=Black
hi TelescopeBorder        guifg=#589ed7 guibg=Black
hi TelescopePromptTitle   guifg=#ff966c guibg=Black
hi TelescopeResultsTitle  guibg=Black
hi TelescopePromptCounter guifg=#5C636C
hi! link TelescopeTitle        TelescopeNormal
hi! link TelescopePreviewLine  CursorLine
hi! link TelescopePromptPrefix TelescopePromptTitle

hi! link SnacksPicker                  TelescopeNormal
hi! link SnacksPickerBorder            TelescopeBorder
hi! link SnacksPickerTotals            TelescopePromptCounter
hi! link SnacksPickerInputBorder       TelescopePromptTitle
hi! link SnacksPickerListCursorLine    CursorLine
hi! link SnacksPickerPreviewCursorLine CursorLine
hi! link SnacksPickerPreviewTitle      TelescopeBorder
hi! link SnacksPickerBoxTitle          TelescopePromptTitle
hi! link SnacksPickerMatch             FlashMatch
hi! link SnacksPickerDir               TelescopePromptCounter
hi! link SnacksPickerCol               TelescopePromptCounter
hi! link SnacksPickerRow               TelescopePromptCounter
hi! link SnacksPickerDelim             TelescopePromptCounter
]])

vim.api.nvim_set_hl(0, "@keyword.conditional", { fg = "#BB8AFF" })
vim.api.nvim_set_hl(0, "@conditional", { fg = "#BB8AFF" })
vim.api.nvim_set_hl(0, "Function", { fg = "#39A6FF" })
vim.api.nvim_set_hl(0, "@function", { fg = "#39A6FF" })
vim.api.nvim_set_hl(0, "@function.call", { fg = "#39A6FF" })
vim.api.nvim_set_hl(0, "@function.method", { fg = "#39A6FF" })
vim.api.nvim_set_hl(0, "@method", { fg = "#39A6FF" })
vim.api.nvim_set_hl(0, "@method.call", { fg = "#39A6FF" })
vim.api.nvim_set_hl(0, "@variable.member", { fg = "#FF5A4F" })
vim.api.nvim_set_hl(0, "@field", { fg = "#FF5A4F" })
vim.api.nvim_set_hl(0, "@property", { fg = "#FF5A4F" })
vim.api.nvim_set_hl(0, "MatchParen", { fg = "#D8D8D8", bg = "#4A4A4A", bold = true })

vim.lsp.set_log_level("off")

-- 打开文件后光标回到关闭的时候的位置
require('nvim-lastplace').setup{}

-- Project.nvim
vim.api.nvim_create_user_command('Root', 'ProjectRoot', {})  -- 将 :Root 映射到 :ProjectRoot
vim.api.nvim_create_user_command("A",    "Other",       {})
vim.api.nvim_create_user_command("AS",   "OtherSplit",  {})
vim.api.nvim_create_user_command("AV",   "OtherVSplit", {})
vim.api.nvim_create_user_command("AT",   "OtherTabNew", {})

require('noice')

require("configs.num_change").tg_format()
require("configs.num_change").tg_dot_array()
require("configs.num_change").tg_format_array()
require("configs.gencompiledb")

-- avante.nvim 兼容老 nvim 版本
vim.text = vim.text or {}
vim.text.diff = vim.diff
