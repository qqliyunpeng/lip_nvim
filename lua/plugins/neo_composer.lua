local ge = require("lip.utils").ge

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

local function setup_neo_composer(opts)
    require("NeoComposer").setup(opts)

    local ui = require("NeoComposer.ui")
    local toggle_macro_menu = ui.toggle_macro_menu

    -- 只在 NeoComposer 菜单 buffer 中定义 <leader>c；菜单外不改变原绑定。
    ui.toggle_macro_menu = function(...)
        toggle_macro_menu(...)

        local menu_buffer = rawget(_G, "BUFH")
        if menu_buffer and vim.api.nvim_buf_is_valid(menu_buffer) then
            local menu_window = rawget(_G, "WIN_ID")
            if menu_window and vim.api.nvim_win_is_valid(menu_window) then
                local window_config = vim.api.nvim_win_get_config(menu_window)
                window_config.title = " NeoComposer  |  ,c 清空 "
                window_config.title_pos = "center"
                vim.api.nvim_win_set_config(menu_window, window_config)
            end

            vim.keymap.set("n", "<leader>c", function()
                vim.cmd("ClearNeoComposer")
                vim.api.nvim_buf_set_lines(menu_buffer, 0, -1, false, {})
                vim.notify("NeoComposer macros cleared", vim.log.levels.INFO, {
                    title = "NeoComposer",
                })
            end, {
                buffer = menu_buffer,
                desc = "Clear NeoComposer macros",
                nowait = true,
                silent = true,
            })

            vim.keymap.set("n", "<C-c>", function()
                ui.toggle_macro_menu()
            end, {
                buffer = menu_buffer,
                desc = "Close NeoComposer menu",
                nowait = true,
                silent = true,
            })
        end
    end

    vim.keymap.set("n", "q", M.toggle_record_with_confirm, {
        desc = "Record macro (confirm first)",
    })
end

return {
    {
        ge("nvim_lip/neo-composer.nvim"),
        event = "VeryLazy",
        dependencies = {
            ge("nvim_lip/sqlite.lua.git"),
        },
        opts = {
            notify = false,
            keymaps = {
                cycle_next = "<A-n>",
                cycle_prev = "<A-p>",
            },
        },
        config = function(_, opts)
            setup_neo_composer(opts)
        end,
    },
}

