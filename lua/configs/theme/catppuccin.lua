-- catppuccin 专用的 hi 覆盖 —— 目前留空（占位）
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
    -- 暂时什么都不做：catppuccin 用自己的配色。
    --
    -- 以后要加就这样写（参考 configs/theme/onedark.lua 里那套 group）：
    --
    -- local C = M.palette
    -- vim.api.nvim_set_hl(0, "CursorLine", { bg = C.surface0 })
    -- vim.api.nvim_set_hl(0, "Search", { fg = C.crust, bg = C.blue })
    -- vim.api.nvim_set_hl(0, "MatchParen", { fg = C.text, bg = C.surface2, bold = true })
    -- vim.api.nvim_set_hl(0, "SnacksPickerBorder", { link = "FloatBorder" })
end

return M
