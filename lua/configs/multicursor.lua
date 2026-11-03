--- multicursor.nvim 配置：多光标编辑（替代 vim-visual-multi）
--- 同一 buffer 内放置多个光标，一次编辑多处；可按匹配或按行添加光标，
--- 支持光标间跳转、删除、开关光标集，所有光标共享同一套编辑操作。
local M = {}

function M.setup()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Keep the familiar Visual-Multi mapping for selecting matches.
    set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end,
        { desc = "Add cursor at next match" })

    -- Add or skip cursors above/below the current cursor.
    set({ "n", "x" }, "<C-Up>", function() mc.lineAddCursor(-1) end,
        { desc = "Add cursor above" })
    set({ "n", "x" }, "<C-Down>", function() mc.lineAddCursor(1) end,
        { desc = "Add cursor below" })
    set({ "n", "x" }, "<leader><Up>", function() mc.lineSkipCursor(-1) end,
        { desc = "Skip line above" })
    set({ "n", "x" }, "<leader><Down>", function() mc.lineSkipCursor(1) end,
        { desc = "Skip line below" })

    -- Match navigation and cursor toggle.
    set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end,
        { desc = "Add cursor at next match" })
    set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end,
        { desc = "Add cursor at previous match" })
    set({ "n", "x" }, "<leader>s", function() mc.matchSkipCursor(1) end,
        { desc = "Skip next match" })
    set({ "n", "x" }, "<leader>S", function() mc.matchSkipCursor(-1) end,
        { desc = "Skip previous match" })
    set({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "Toggle multicursors" })

    -- These mappings exist only while multiple cursors are active.
    mc.addKeymapLayer(function(layer_set)
        layer_set({ "n", "x" }, "<Left>", mc.prevCursor,
            { desc = "Previous cursor" })
        layer_set({ "n", "x" }, "<Right>", mc.nextCursor,
            { desc = "Next cursor" })
        layer_set({ "n", "x" }, "<leader>x", mc.deleteCursor,
            { desc = "Delete cursor" })
        layer_set("n", "<Esc>", function()
            if not mc.cursorsEnabled() then
                mc.enableCursors()
            else
                mc.clearCursors()
            end
        end, { desc = "Clear multicursors" })
    end)
end

return M
