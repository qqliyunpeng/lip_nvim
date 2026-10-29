-- onedark / onedarkpro 专用的高亮覆盖
-- 由 configs.theme 在 ColorScheme 事件后调用（:colorscheme onedark* 时生效）
local M = {}

-- NeoComposer 等浮动窗口使用的主题基准色。
-- 统一从主题配置读取，避免在组件配置中重复写死颜色。
M.palette = {
    base = "#1e1e2e",
}

function M.apply()
    -- IlluminatedWordText have problem
    vim.cmd([[
    hi! link IlluminatedWordText Search
    hi! link IlluminatedWordRead HlSearchLens
    hi! link IlluminatedWordWrite  HlSearchLens
    "hi Normal guibg=NONE ctermbg=NONE
    hi Normal guibg=black ctermbg=black
    "hi NormalNC guibg=black ctermbg=black
    hi LineNr guibg=NONE ctermbg=NONE
    hi SignColumn guibg=NONE ctermbg=NONE
    " 当前行
    hi CursorLine guibg=#2a2b3c ctermbg=235
    " 当前行号
    hi CursorLineNr cterm = bold gui = bold guifg=#ff966c
    " 搜索的结果中当前的块的背景颜色
    hi CurSearch guibg=#ff966c
    " visual/v/V 选中内容的背景颜色
    hi Visual guifg=NONE guibg=#483A58 ctermbg=238
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

    " todo-comments
    hi TodoSignTODO guifg=#61afef guibg=NONE
    hi TodoSignPERF guifg=#e06c75 guibg=NONE
    hi TodoSignNOTE guifg=#56b6c2 guibg=NONE
    hi TodoSignFIX  guifg=#e06c75 guibg=NONE
    hi TodoSignHACK guifg=#e5c07b guibg=NONE
    hi TodoSignTEST guifg=#e06c75 guibg=NONE
    hi TodoSignWARN guifg=#e5c07b guibg=NONE

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
end

return M
