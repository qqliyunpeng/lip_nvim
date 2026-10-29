local M = {}

local function confirm_recording()
    local lines = {
        "开始记录宏？",
        "",
        "[y/Enter] 是    [n/q] 否",
    }
    local width = 34
    local height = #lines
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"

    local colorscheme = vim.g.colors_name or ""
    local is_catppuccin = colorscheme:match("^catppuccin") ~= nil
    local is_onedark = colorscheme:match("^onedark") ~= nil
    local winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

    if is_catppuccin or is_onedark then
        -- 使用当前主题自己的调色板，而不是重复写死颜色值。
        local theme_config = is_catppuccin and "configs.theme.catppuccin" or "configs.theme.onedark"
        local palette = require(theme_config).palette
        vim.api.nvim_set_hl(0, "NeoComposerConfirm", {
            bg = palette.base,
        })
        vim.api.nvim_set_hl(0, "NeoComposerConfirmBorder", {
            bg = palette.base,
        })
        vim.api.nvim_set_hl(0, "NeoComposerConfirmTitle", {
            bg = palette.base,
        })
        winhighlight =
            "Normal:NeoComposerConfirm,FloatBorder:NeoComposerConfirmBorder,FloatTitle:NeoComposerConfirmTitle"
    end

    local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2) - 1,
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Please Select ",
        title_pos = "center",
    })

    vim.wo[win].cursorline = false
    vim.wo[win].winhighlight = winhighlight
    vim.cmd("redraw")

    local ok, key = pcall(vim.fn.getcharstr)

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end

    if not ok then
        return false
    end

    return key == "y" or key == "Y" or key == "\r" or key == "\n"
end

---正常模式按 q 时先确认，避免误触直接开始录制宏。
---录制中再按 q 则直接停止，不再询问。
function M.toggle_record_with_confirm()
    local state = require("NeoComposer.state")
    local macro = require("NeoComposer.macro")

    if state.get_recording() then
        macro.toggle_record()
        return
    end

    if confirm_recording() then
        macro.toggle_record()
    end
end

function M.setup(opts)
    -- 必须让 NeoComposer 先按默认的 q 完成 setup，再覆盖 q；
    -- 不能把 keymaps.toggle_record 设成 false，否则它内部裁剪录制内容会出错。
    require("NeoComposer").setup(opts)

    vim.keymap.set("n", "q", M.toggle_record_with_confirm, {
        desc = "Record macro (confirm first)",
    })
end

return M

