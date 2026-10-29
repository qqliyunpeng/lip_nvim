-- F3（Lspsaga Outline）增强逻辑：
--
-- 1. 光标跟随：在源文件中移动光标时，将 Outline 光标同步到当前函数或符号；
--    在函数之间的空白区域，则定位到前一个可见符号，避免列表停留在旧位置。
--    关闭列表自身的光标行背景，仅用独立的深灰色行高亮标记源文件当前符号。
-- 2. 窗口分组：将源文件窗口和 Outline 视为同一组窗口。焦点位于源文件
--    或 Outline 时，两者使用黑色背景；焦点切换到 Quickfix、Explorer 等其他
--    窗口时，两者同步恢复为非活动窗口背景。
-- 3. 关闭预览：配合 Lspsaga 配置关闭 Outline 的自动代码预览，只保留函数列表。
-- 4. 生命周期管理：关闭最后一个源文件时，同时关闭 Outline，避免留下孤立的
--    函数列表窗口；关闭 Outline 时恢复源文件原有的窗口高亮设置。
--
-- 该模块不负责生成符号列表，符号数据和列表窗口仍由 Lspsaga 管理。
local M = {}
local source_winhighlight = {}
local current_symbol_ns = vim.api.nvim_create_namespace("SagaOutlineCurrentSymbol")
local autowidth_disabled_by_outline = false

local function disable_windows_autowidth()
    if autowidth_disabled_by_outline then
        return
    end
    local ok, config = pcall(require, "windows.config")
    if not ok or not config.autowidth.enable then
        return
    end
    local loaded, autowidth = pcall(require, "windows.autowidth")
    if not loaded or type(autowidth.disable) ~= "function" then
        return
    end
    autowidth.disable()
    autowidth_disabled_by_outline = true
end

local function has_outline_window()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win)
            and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "sagaoutline"
        then
            return true
        end
    end
    return false
end

local function restore_windows_autowidth()
    if autowidth_disabled_by_outline and not has_outline_window() then
        local ok, autowidth = pcall(require, "windows.autowidth")
        if ok and type(autowidth.enable) == "function" then
            autowidth.enable()
        end
        autowidth_disabled_by_outline = false
    end
end

local function set_winhighlight(win, active_group, is_outline)
    local parts = {}
    local seen = {}
    for mapping in vim.wo[win].winhighlight:gmatch("[^,]+") do
        if not mapping:match("^Normal:") and not mapping:match("^NormalNC:") then
            parts[#parts + 1] = mapping
            local name = mapping:match("^([^:]+):")
            if name then seen[name] = true end
        end
    end
    -- Outline 是真实分屏，复用 Avante 的分割线；其他主题下回退到默认值。
    if is_outline and not seen.WinSeparator then
        parts[#parts + 1] = "WinSeparator:SagaOutlineSeparator"
    end
    if is_outline and not seen.WinSeparatorNC then
        parts[#parts + 1] = "WinSeparatorNC:SagaOutlineSeparator"
    end
    parts[#parts + 1] = "Normal:" .. active_group
    parts[#parts + 1] = "NormalNC:" .. active_group
    vim.wo[win].winhighlight = table.concat(parts, ",")
end

local function set_outline_separator(win)
    local parts = {}
    for mapping in vim.wo[win].winhighlight:gmatch("[^,]+") do
        local source = mapping:match("^([^:]+):")
        if source ~= "WinSeparator" and source ~= "WinSeparatorNC" then
            parts[#parts + 1] = mapping
        end
    end
    parts[#parts + 1] = "WinSeparator:SagaOutlineSeparator"
    parts[#parts + 1] = "WinSeparatorNC:SagaOutlineSeparator"
    vim.wo[win].winhighlight = table.concat(parts, ",")
end

local function restore_source_highlights()
    for win, value in pairs(source_winhighlight) do
        if vim.api.nvim_win_is_valid(win) then
            vim.wo[win].winhighlight = value
        end
        source_winhighlight[win] = nil
    end
end

function M.setup()
    restore_source_highlights()
    require("configs.ai").setup_quit_sidebars()
    local api = vim.api
    local group = api.nvim_create_augroup("SagaOutlineFollow", { clear = true })

    local function follow()
        local outline = package.loaded["lspsaga.symbol.outline"]
        if not outline or not outline.winid or not api.nvim_win_is_valid(outline.winid) then
            return
        end
        local source_win = api.nvim_get_current_win()
        if source_win == outline.winid or api.nvim_get_current_buf() ~= outline.main_buf then
            return
        end

        local cursor = api.nvim_win_get_cursor(source_win)
        local row = cursor[1] - 1
        local node, target = outline.list, nil
        local preceding, preceding_line, first_visible = nil, -1, nil
        while node and node.value do
            local value = node.value
            local range = value.range or (value.location and value.location.range) or value.selectionRange
            if range and value.winline and value.winline > 0 then
                local first, last = range.start, range["end"]
                first_visible = first_visible or value
                if first.line <= row and first.line >= preceding_line then
                    preceding, preceding_line = value, first.line
                end
                local after_start = row >= first.line
                local before_end = row < last.line or (row == last.line and last.character > 0)
                if after_start and before_end then
                    -- Prefer the deepest visible symbol; collapsed children have winline = -1.
                    if not target or (value.inlevel or 0) >= (target.inlevel or 0) then
                        target = value
                    end
                end
            end
            node = node.next
        end

        -- Between symbols, follow the preceding declaration instead of keeping a stale cursor.
        target = target or preceding or first_visible
        outline.callerwinid = source_win
        -- 不使用 cursorline：它会把列表实际光标所在行显示成深色条。
        vim.wo[outline.winid].cursorline = false
        api.nvim_buf_clear_namespace(outline.bufnr, current_symbol_ns, 0, -1)
        if target and target.winline <= api.nvim_buf_line_count(outline.bufnr) then
            api.nvim_win_set_cursor(outline.winid, { target.winline, target.inlevel or 0 })
            api.nvim_buf_set_extmark(outline.bufnr, current_symbol_ns, target.winline - 1, 0, {
                line_hl_group = "SagaOutlineCurrentSymbol",
            })
        end
    end

    api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
        group = group,
        callback = follow,
        desc = "Follow the current source symbol in the F3 outline without changing focus",
    })
    api.nvim_create_autocmd("User", {
        group = group,
        pattern = "SagaSymbolUpdate",
        callback = function()
            -- Lspsaga schedules its outline refresh before this callback.
            vim.schedule(follow)
        end,
    })
    local function set_outline_background(win, active)
        if not api.nvim_win_is_valid(win) then
            return
        end
        local normal = api.nvim_get_hl(0, { name = "Normal", link = false })
        api.nvim_set_hl(0, "SagaOutlineNormal", {
            fg = normal.fg,
            bg = "#000000",
        })
        api.nvim_set_hl(0, "SagaOutlineCurrentSymbol", {
            fg = normal.fg,
            bg = "#45475A",
        })
        vim.wo[win].cursorline = false
        set_winhighlight(win, active and "SagaOutlineNormal" or "NormalNC", true)
    end

    local function sync_group_background()
        local outline = package.loaded["lspsaga.symbol.outline"]
        if not outline or not outline.winid or not api.nvim_win_is_valid(outline.winid) then
            restore_source_highlights()
            return
        end
        local source_win = outline.callerwinid
        if not source_win or not api.nvim_win_is_valid(source_win)
            or api.nvim_win_get_buf(source_win) ~= outline.main_buf
        then
            restore_source_highlights()
            set_outline_background(outline.winid, false)
            return
        end
        local current = api.nvim_get_current_win()
        local active = current == outline.winid or current == source_win
        local current_ft = vim.bo[api.nvim_win_get_buf(current)].filetype
        local avante_focus = current_ft == "Avante"
            or current_ft == "AvanteInput"
            or current_ft == "AvanteSelectedCode"
            or current_ft == "AvanteSelectedFiles"
            or current_ft == "AvanteTodos"
        restore_source_highlights()
        set_outline_background(outline.winid, active)
        -- 分割线实际可能由源文件窗口绘制。焦点进入 Avante 时保留
        -- Outline 的专用分割线，避免 Avante 的 WinEnter 覆盖它。
        if active or avante_focus then
            if source_winhighlight[source_win] == nil then
                source_winhighlight[source_win] = vim.wo[source_win].winhighlight
            end
            set_outline_separator(source_win)
        end
        if active then
            set_winhighlight(source_win, "SagaOutlineNormal", true)
        end
    end

    api.nvim_create_autocmd({ "WinEnter", "WinClosed", "BufWinEnter" }, {
        group = group,
        callback = function()
            -- Run after the plugin/window-enter handlers finish setting window options.
            vim.schedule(function()
                if has_outline_window() then
                    disable_windows_autowidth()
                else
                    restore_windows_autowidth()
                end
                follow()
                sync_group_background()
            end)
        end,
    })
    api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = sync_group_background,
    })
    api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "sagaoutline",
        callback = function()
            local win = api.nvim_get_current_win()
            vim.schedule(function()
                if api.nvim_win_is_valid(win) and vim.bo[api.nvim_win_get_buf(win)].filetype == "sagaoutline" then
                    disable_windows_autowidth()
                    sync_group_background()
                    vim.wo[win].cursorline = false
                end
            end)
        end,
    })
end

function M.is_open()
    local outline = package.loaded["lspsaga.symbol.outline"]
    return outline ~= nil and outline.winid ~= nil and vim.api.nvim_win_is_valid(outline.winid)
end

function M.close()
    local outline = package.loaded["lspsaga.symbol.outline"]
    if M.is_open() and vim.api.nvim_win_get_tabpage(outline.winid) == vim.api.nvim_get_current_tabpage() then
        -- Use the plugin's toggle-close path so its context and autocmds are cleaned too.
        restore_source_highlights()
        outline:outline()
    end
end

return M
