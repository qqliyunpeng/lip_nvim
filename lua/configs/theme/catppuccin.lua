-- catppuccin 专用的高亮覆盖
--
-- 设计：onedark 的所有 hi 定制都放在 configs/theme/onedark.lua，
-- 用 catppuccin 时那些 hi 完全不生效，本文件就是你的 catppuccin 专属位置。
-- 生效时机：:colorscheme catppuccin / catppuccin-mocha ... 之后，由 configs.theme 调用 apply()。
local M = {}

---调色板（Mocha），写覆盖时直接取色，省得记 #hex
M.palette = {
    base = "#1e1e2e",
    mantle = "#181825",
    crust = "#11111b",
    surface0 = "#313244",
    surface1 = "#45475a",
    surface2 = "#585b70",
    overlay0 = "#6c7086",
    overlay1 = "#7f849c",
    text = "#cdd6f4",
    subtext0 = "#a6adc8",
    blue = "#89b4fa",
    lavender = "#b4befe",
    teal = "#94e2d5",
    green = "#a6e3a1",
    yellow = "#f9e2af",
    peach = "#fab387",
    red = "#f38ba8",
    pink = "#f5c2e7",
    mauve = "#cba6f7",
    flamingo = "#f2cdcd",
}

function M.apply()
    -- 与 onedark 一致：当前窗口用黑底，NormalNC 保留主题原生背景。
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    normal.bg = "#000000"
    normal.ctermbg = 0
    vim.api.nvim_set_hl(0, "Normal", normal)

    for _, group in ipairs({ "Comment", "Conditional" }) do
        local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
        highlight.italic = false
        highlight.cterm = nil
        vim.api.nvim_set_hl(0, group, highlight)
    end

    vim.api.nvim_set_hl(0, "MatchParen", {
        fg = M.palette.pink,
        bg = M.palette.surface2,
        bold = true,
    })

    -- Avante、QuickFix 和 F3 Outline 共用的标题栏/分割线颜色。
    -- 使用独立组，避免改变 Catppuccin 下其他普通窗口的分割线。
    local separator = { fg = M.palette.overlay1, bg = M.palette.base }
    vim.api.nvim_set_hl(0, "AvanteWinSeparator", separator)
    vim.api.nvim_set_hl(0, "AvanteWinSeparatorNC", separator)
    -- TodoQuickFix 的分割线单独提高亮度，避免在底部面板中被背景吞掉。
    vim.api.nvim_set_hl(0, "TodoQuickFixSeparator", {
        fg = M.palette.lavender,
        bg = M.palette.base,
    })
    vim.api.nvim_set_hl(0, "SagaOutlineSeparator", {
        fg = M.palette.overlay1,
        bg = M.palette.base,
    })
    vim.api.nvim_set_hl(0, "AvanteWinBar", {
        fg = M.palette.text,
        bg = M.palette.base,
    })
    vim.api.nvim_set_hl(0, "AvanteWinBarNC", {
        fg = M.palette.text,
        bg = M.palette.base,
    })
    vim.api.nvim_set_hl(0, "EdgyTitle", {
        fg = M.palette.text,
        bg = M.palette.base,
    })
end

return M
