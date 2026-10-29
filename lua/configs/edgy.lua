-- edgy.nvim：把侧边栏 / 面板窗口收进固定的 edgebar 布局。
--
-- 关键点：edgy 只接管「能被某个 view 的 ft 匹配到」的窗口。
-- 没写进下面的插件（snacks picker、lazygit 终端、noice…）行为完全不变，
-- 所以这份 view 列表就是白名单。
local M = {}

-- 浮窗（picker / lazygit / noice 都是浮窗）不归 edgy 管：
-- 将来万一 ft 撞上了，也不会被拽进 edgebar。
local function not_float(_, win)
    return vim.api.nvim_win_get_config(win).relative == ""
end

-- 是否让 edgy 接管 Avante 侧栏（结果区 / 选中代码 / 选中文件 / todos）。
-- 接管后高度归 edgebar：configs/ai.lua 把那几个 get_*_container_height() 改成
-- 读当前窗口高度，avante 就不会再自己 set_height 抢同列的行。
-- 但 zen / 全屏视图（avante 的 toggle_code_window）仍然自己改宽高，
-- 仍可能出现宽度抖动 / zen 退出后主窗变 0 宽。
-- 不想碰这些就把下面改成 false，让 avante 自己管布局。
M.avante = true

-- Avante 侧栏宽度（占屏宽比例）——这里是唯一的定义源：
-- Avante 打开时作为左 edgebar 的 size（和 Explorer 共用同一列），
-- 也同步给 avante 的 windows.width（configs/ai.lua）。
M.avante_width = 0.4

-- Explorer 单独在左侧时的宽度（列数）。Avante 打开时两者共用同一列，
-- 宽度以 avante_width 为准；否则固定列数比比例更稳（宽屏下不会越来越宽）。
M.explorer_width = 30

-- Avante 各容器高度：竖列（left/right）里一律用「绝对行数」，不用比例。
-- 原因在 edgy 的 Edgebar:resize()：它把这条列里每个窗口的当前高度加起来当预算
-- （bounds.height），再把 view 的 0.x 当作这个「和」的百分比。这个和
--   1) 漏算每个 view 自己 winbar 占的那一行；
--   2) 第一轮取的是窗口的瞬时高度，一旦算完就变成不动点，不会再自我纠正。
-- 于是 0.25/0.15/0.08/0.2 分出去的行数和真实可用行数总是差几行（列底部留白 /
-- 被 nvim 再改一次 => 观感抖动）。而 M.size() 只在 size < 1 时按比例，
-- >= 1 就是精确行数（不含 winbar），所以这里写死行数最稳。
-- 数值参考 avante 自己的上限：selected_code = min(行数, 5)、
-- selected_files = min(配置, #文件 + 1)、todos = 表头 + 2 行进度、
-- input = windows.input.height（见下，两处必须一致）。
M.avante_selected_code_height = 6
M.avante_selected_files_height = 4
M.avante_todos_height = 3
-- 输入框行数：同时作为 avante 的 windows.input.height（configs/ai.lua）。
-- 不一致的话 avante 建输入框时分的行数 ≠ edgebar 随后分配的行数，会跳动。
M.avante_input_height = 10

-- Explorer（snacks.explorer）高度：有 Avante 结果区时给它一个上限，剩下的行全给结果区。
-- edgy 的分配规则是「把剩余空间平均分给所有没有 size 的 auto 视图」
-- （edgebar.lua:294-303），所以 Explorer 不写高度时会和结果区对半分
-- —— 这就是「结果区只占一半」的原因。
-- 这里用函数形式（edgy 的 M.size 支持 function，每次 resize 时求值）：
--   · 有 Avante 结果区：限高 explorer_height_ratio * lines（至少 explorer_min_height 行）
--   · 没有：返回 vim.o.lines（= 想占满整列，nvim 会自然裁剪）
-- 后者很重要：Explorer 单独在一列时如果也写死小高度，nvim 为了填满列会把它撑开，
-- edgy 再改回去就变成互抢。
M.explorer_height_ratio = 0.25
M.explorer_min_height = 8

local function avante_result_open()
    if not M.avante then
        return false
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "Avante" then
            return true
        end
    end
    return false
end

local function explorer_column()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local meta = vim.w[win].snacks_win
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_layout_box"
            and not_float(nil, win) and meta ~= nil and meta.position == "left" then
            return win
        end
    end
end

local function left_edgebar_width()
    local win = vim.t.lip_avante_width_win
    -- edgy 的 close() 使用 noautocmd，不能仅依靠 BufWinLeave 清理。
    if win and (not vim.api.nvim_win_is_valid(win)
        or vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "Avante") then
        vim.t.lip_avante_width = nil
        vim.t.lip_avante_width_win = nil
    end
    if avante_result_open() then
        return vim.t.lip_avante_width or M.avante_width
    end
    vim.t.lip_avante_width = nil
    vim.t.lip_avante_width_win = nil
    local explorer_win = explorer_column()
    if vim.t.lip_explorer_width_win
        and (not explorer_win or vim.t.lip_explorer_width_win ~= explorer_win) then
        vim.t.lip_explorer_width = nil
        vim.t.lip_explorer_width_win = nil
    end
    local max_width = math.max(1, math.floor(vim.o.columns * M.avante_width))
    if vim.t.lip_explorer_width and explorer_win then
        return math.max(1, math.min(vim.t.lip_explorer_width, vim.o.columns - 2))
    end
    return math.min(M.explorer_width, max_width)
end

-- edgy 会接管的 avante 容器 buffer 类型。
local avante_filetypes = {
    Avante = true,
    AvanteInput = true,
    AvanteSelectedCode = true,
    AvanteSelectedFiles = true,
    AvanteTodos = true,
}

-- Avante 的 nui 容器是「先 mount 窗口、后写 win_options」的：
-- nvim_win_set_buf 触发 BufWinEnter（edgy 认领窗口并写入 edgebar 的 winbar），
-- 紧接着 sidebar.lua 才 set_win_options(base_win_options)，而那里是
-- winbar = "" + 自己的 winhighlight，于是结果区 / 选中文件区的 edgebar 标题栏
-- 刚写上就被冲掉（走 snacks 的输入框不受影响）。
-- edgy 的 wo 只在 Window.new() 应用一次，之后只补 winhighlight，不会重刷 winbar，
-- 所以这里在 avante 窗口完成挂载后再把 edgy 的窗口选项写回去。
function M.reattach_avante()
    if M._reattaching or not M.avante then
        return
    end
    M._reattaching = true

    local ok, Window = pcall(require, "edgy.window")
    if ok then
        local unclaimed = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
            if avante_filetypes[ft] and not Window.cache[win] then
                unclaimed = true
                break
            end
        end
        if unclaimed then
            pcall(function()
                require("edgy.layout").update()
            end)
        end

        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local edgy_win = Window.cache[win]
            local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
            if edgy_win and avante_filetypes[ft] then
                for key, value in pairs(edgy_win.wo) do
                    -- winhighlight 交给 fix_winhl 合并，直接覆盖会丢掉 avante 自己的映射
                    if key ~= "winhighlight" then
                        pcall(vim.api.nvim_set_option_value, key, value, { scope = "local", win = win })
                    end
                end
                pcall(edgy_win.fix_winhl, edgy_win)
            end
        end
    end

    M._reattaching = false
end

-- Avante 的 render() 会连续 mount 多个 nui Split。edgy 在 BufWinEnter 上的
-- layout 是同步的，会在 input 容器还没缩到目标高度时先把结果区搬进 edgebar；
-- 随后 nui 再 set_height 时，多出来的行只能塞进 cmdheight，表现为 heirline
-- 停在上半屏、下方一大片空白。render 期间先暂停 edgy 的 layout，等所有容器
-- 挂好后再统一排一次。
function M.install_avante_layout_pause()
    if M._avante_layout_pause_installed then
        return
    end
    local ok, Layout = pcall(require, "edgy.layout")
    if not ok then
        return
    end
    local original_update = Layout.update
    Layout.update = function(...)
        if vim.g.lip_edgy_pause or M._mouse_resizing then
            return
        end
        return original_update(...)
    end
    M._avante_layout_pause_installed = true
end

-- 临时宽度只放在当前 tab；关闭结果区后清除，不修改默认比例或持久化配置。
local function avante_column()
    if not avante_result_open() then
        return
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "Avante" and not_float(nil, win) then
            return win
        end
    end
end

function M.resize_avante(amount)
    local win = avante_column()
    if not win then
        return
    end
    vim.t.lip_avante_width = math.max(1, math.min(vim.o.columns - 2, vim.api.nvim_win_get_width(win) + amount))
    vim.t.lip_avante_width_win = win
    require("edgy.layout").update()
end

function M.install_avante_resize()
    if M._avante_resize_installed or not M.avante then
        return
    end
    M._avante_resize_installed = true
    for key, amount in pairs({ ["<C-S-Left>"] = -2, ["<C-S-Right>"] = 2 }) do
        vim.keymap.set({ "n", "i", "v" }, key, function()
            M.resize_avante(amount)
        end, { desc = amount > 0 and "加宽 Avante 侧栏" or "缩窄 Avante 侧栏" })
    end

    -- 保留原生鼠标行为，只在拖动左侧栏右侧分隔线时暂停 edgy。
    local target
    for _, key in ipairs({ "<LeftMouse>", "<LeftDrag>", "<LeftRelease>" }) do
        local native = vim.api.nvim_replace_termcodes(key, true, false, true)
        vim.keymap.set({ "n", "i", "v" }, key, function()
            if key == "<LeftMouse>" then
                target = nil
                local win = avante_result_open() and avante_column() or explorer_column()
                if win then
                    local pos = vim.fn.getmousepos()
                    local col = vim.api.nvim_win_get_position(win)[2] + vim.api.nvim_win_get_width(win) + 1
                    if pos.screencol == col then
                        target = { win = win, tab = vim.api.nvim_get_current_tabpage() }
                    end
                end
            elseif key == "<LeftDrag>" and target then
                M._mouse_resizing = true
            elseif key == "<LeftRelease>" then
                local dragged = target
                target = nil
                if not M._mouse_resizing then
                    return native
                end
                -- 原生 release 先处理完，再读取窗口的最终宽度。
                vim.schedule(function()
                    if M._mouse_resizing and dragged and vim.api.nvim_win_is_valid(dragged.win)
                        and vim.api.nvim_get_current_tabpage() == dragged.tab then
                        local width = math.max(
                            1,
                            math.min(vim.api.nvim_win_get_width(dragged.win), vim.o.columns - 2)
                        )
                        if avante_result_open() then
                            vim.t.lip_avante_width = width
                            vim.t.lip_avante_width_win = dragged.win
                        elseif explorer_column() == dragged.win then
                            vim.t.lip_explorer_width = width
                            vim.t.lip_explorer_width_win = dragged.win
                        end
                    end
                    M._mouse_resizing = false
                    require("edgy.layout").update()
                end)
            end
            return native
        end, { expr = true, replace_keycodes = false, desc = "左侧栏临时鼠标调宽（保留原生鼠标）" })
    end

    vim.api.nvim_create_autocmd("BufWinLeave", {
        group = vim.api.nvim_create_augroup("LipEdgyAvanteResize", { clear = true }),
        callback = function(ev)
            if vim.bo[ev.buf].filetype == "Avante" then
                vim.t.lip_avante_width = nil
                vim.t.lip_avante_width_win = nil
                M._mouse_resizing = false
                target = nil
            end
        end,
    })
end

function M.install_avante_reattach()
    if M._avante_reattach_installed or not M.avante then
        return
    end
    M._avante_reattach_installed = true
    -- schedule 是必需的：要等 avante 在同一个事件循环里把 win_options 写完
    vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "WinEnter" }, {
        group = vim.api.nvim_create_augroup("LipEdgyAvanteReattach", { clear = true }),
        pattern = vim.tbl_keys(avante_filetypes),
        callback = function()
            vim.schedule(M.reattach_avante)
        end,
    })
end

-- Avante 容器统一用 Normal 背景（当前主题为黑色）。edgy 默认的 EdgyNormal
-- 链接 NormalFloat，并在 WinEnter 时追加到 winhighlight 末尾，会把当前窗口
-- 变成非黑背景；这里给 Avante 视图单独指定，避免它追加 EdgyNormal。
local avante_wo = {
    winhighlight = table.concat({
        "WinBar:AvanteWinBar",
        "WinBarNC:AvanteWinBarNC",
        "WinSeparator:AvanteWinSeparator",
        "WinSeparatorNC:AvanteWinSeparatorNC",
        "Normal:AvanteSidebarNormal",
    }, ","),
}

-- 只给 Avante 的 winbar 使用独立高亮组，不修改 edgy 全局标题栏颜色。
local function setup_avante_winbar_highlights()
    local is_catppuccin = (vim.g.colors_name or ""):match("^catppuccin") ~= nil
    if not is_catppuccin then
        vim.api.nvim_set_hl(0, "AvanteWinBar", { link = "EdgyWinBar" })
        vim.api.nvim_set_hl(0, "AvanteWinBarNC", { link = "EdgyWinBarNC" })
        vim.api.nvim_set_hl(0, "AvanteWinSeparator", { link = "WinSeparator" })
        vim.api.nvim_set_hl(0, "AvanteWinSeparatorNC", { link = "WinSeparator" })
        vim.api.nvim_set_hl(0, "TodoQuickFixSeparator", { link = "WinSeparator" })
        vim.api.nvim_set_hl(0, "SagaOutlineSeparator", { link = "WinSeparator" })
        return
    end

    local ok, edgy_winbar = pcall(vim.api.nvim_get_hl, 0, { name = "EdgyWinBar", link = false })
    if not ok or not next(edgy_winbar) then
        edgy_winbar = vim.api.nvim_get_hl(0, { name = "Title", link = false })
    end
    edgy_winbar.bg = "#1E1E2E"
    vim.api.nvim_set_hl(0, "AvanteWinBar", edgy_winbar)
    vim.api.nvim_set_hl(0, "AvanteWinBarNC", edgy_winbar)

    -- 仅在 Catppuccin 下保留较亮的 Avante 分割线，背景与标题栏一致。
    local separator = { fg = "#7F849C", bg = "#1E1E2E" }
    vim.api.nvim_set_hl(0, "AvanteWinSeparator", separator)
    vim.api.nvim_set_hl(0, "AvanteWinSeparatorNC", separator)
end

function M.opts()
    setup_avante_winbar_highlights()
    -- Edgy 在创建 qf 窗口后会再次合并 winhighlight；在窗口真正出现后
    -- 再补一次，确保 Todo/QuickFix 这类通过 :copen 打开的列表也命中。
    local qf_group = vim.api.nvim_create_augroup("LipQuickFixHighlights", { clear = true })
    local qf_separator_windows = {}

    local function set_qf_separator(win)
        if not vim.api.nvim_win_is_valid(win) then
            return
        end
        if qf_separator_windows[win] == nil then
            qf_separator_windows[win] = vim.wo[win].winhighlight
        end
        local mappings = {}
        for mapping in vim.wo[win].winhighlight:gmatch("[^,]+") do
            local source = mapping:match("^([^:]+):")
            if source ~= "WinSeparator" and source ~= "WinSeparatorNC" then
                mappings[#mappings + 1] = mapping
            end
        end
        mappings[#mappings + 1] = "WinSeparator:TodoQuickFixSeparator"
        mappings[#mappings + 1] = "WinSeparatorNC:TodoQuickFixSeparator"
        vim.wo[win].winhighlight = table.concat(mappings, ",")
    end

    local function ensure_qf_separator_highlight()
        if (vim.g.colors_name or ""):match("^catppuccin") then
            vim.api.nvim_set_hl(0, "TodoQuickFixSeparator", {
                fg = "#B4BEFE",
                bg = "#1E1E2E",
            })
        end
    end

    local function restore_qf_separators()
        for win, value in pairs(qf_separator_windows) do
            if vim.api.nvim_win_is_valid(win) then
                vim.wo[win].winhighlight = value
            end
            qf_separator_windows[win] = nil
        end
    end

    local function refresh_qf_separators()
        local qf_windows = {}
        for _, candidate in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_is_valid(candidate)
                and vim.bo[vim.api.nvim_win_get_buf(candidate)].filetype == "qf"
            then
                qf_windows[#qf_windows + 1] = candidate
            end
        end

        if #qf_windows == 0 then
            restore_qf_separators()
            return
        end

        for _, qf_win in ipairs(qf_windows) do
            set_qf_separator(qf_win)
            local qf_row = vim.api.nvim_win_get_position(qf_win)[1]
            for _, candidate in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if candidate ~= qf_win and vim.api.nvim_win_is_valid(candidate) then
                    local buf = vim.api.nvim_win_get_buf(candidate)
                    local filetype = vim.bo[buf].filetype
                    local row = vim.api.nvim_win_get_position(candidate)[1]
                    local height = vim.api.nvim_win_get_height(candidate)
                    -- 这条边界由 qf 上方窗口绘制；Outline 自己有独立的
                    -- SagaOutlineSeparator，不能被 TodoQuickFixSeparator 覆盖。
                    if filetype ~= "qf" and filetype ~= "sagaoutline"
                        and (row + height == qf_row or row + height + 1 == qf_row)
                    then
                        set_qf_separator(candidate)
                    end
                end
            end
        end
    end

    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter", "WinClosed" }, {
        group = qf_group,
        callback = function()
            vim.schedule(function()
                ensure_qf_separator_highlight()
                refresh_qf_separators()
                -- Edgy 的 resize/layout 可能在本回调之后再次移动 qf，
                -- 因此在布局稳定后再补一次，覆盖由上方窗口绘制的边界线。
                vim.defer_fn(refresh_qf_separators, 80)
                vim.defer_fn(refresh_qf_separators, 250)
            end)
        end,
    })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("LipAvanteWinBarHighlights", { clear = true }),
        callback = function()
            vim.schedule(setup_avante_winbar_highlights)
        end,
    })
    local opts = {
        -- edgebar 展开/收起不播放动画（默认是开）
        animate = { enabled = false },
        -- 其余顶层选项（exit_when_last / close_when_all_hidden）和窗口选项（wo：
        -- winbar / winfixwidth / winhighlight / signcolumn…）都用 edgy 默认值，
        -- 只有下面这几条和默认值不同，所以只写这些。
        options = {
            -- Avante 在左侧 edgebar，和 Explorer 共用这一列的宽度；
            -- 只有 Explorer 时按 explorer_width 收窄
            left = { size = left_edgebar_width },
            -- 0.3 = 30% 行高。注意：底部 edgebar 里的所有 view 共用同一个高度，
            -- 这里才是真正的面板高度（view 自己的 size.height 只是最小值）
            bottom = { size = 0.3 },
        },
        left = {
            {
                -- snacks.explorer 侧栏：真 split 的根窗口 ft 是 snacks_layout_box，
                -- 用 vim.w[].snacks_win.position 识别左侧那一个（输入/列表
                -- 是叠在根窗口上的浮窗，edgy 只管根 split）
                ft = "snacks_layout_box",
                title = "Explorer",
                filter = function(buf, win)
                    if not not_float(buf, win) then
                        return false
                    end
                    local meta = vim.w[win].snacks_win
                    return meta ~= nil and meta.position == "left"
                end,
                -- 标题行由 snacks 自己的输入框边框显示，根窗口不要 winbar
                wo = { winbar = false },
                -- 有 Avante 结果区时限高，否则吃满整列（见上面 explorer_height_ratio 的注释）
                size = {
                    height = function()
                        if not avante_result_open() then
                            return vim.o.lines
                        end
                        return math.max(
                            M.explorer_min_height,
                            math.floor(M.explorer_height_ratio * vim.o.lines)
                        )
                    end,
                },
            },
        },
        bottom = {
            {
                ft = "OverseerList",
                title = "Tasks",
                filter = not_float,
            },
            {
                ft = "OverseerForm",
                title = "Task Form",
                filter = not_float,
            },
            {
                ft = "OverseerTaskAction",
                title = "Task Action",
                filter = not_float,
            },
            {
                ft = "qf",
                title = "QuickFix",
                filter = not_float,
                -- 不用 EdgyNormal（NormalFloat），随焦点切换当前/非当前窗口背景。
                -- 复用 Avante 的标题栏和分割线；其他主题下这些组回退到默认值。
                wo = { winhighlight = table.concat({
                    "WinBar:AvanteWinBar",
                    "WinBarNC:AvanteWinBarNC",
                    "EdgyTitle:AvanteWinBar",
                    "WinSeparator:AvanteWinSeparator",
                    "WinSeparatorNC:AvanteWinSeparatorNC",
                    "Normal:Normal",
                    "NormalNC:NormalNC",
                }, ",") },
            },
            -- snacks.terminal（<A-b>）：configs/snacks.lua 里已改成底部分屏；
            -- winbar 留给 snacks（显示终端标题），edgy 不写，避免互相覆盖
            {
                ft = "snacks_terminal",
                title = "Terminal",
                filter = not_float,
                wo = { winbar = false },
            },
        },
    }

    if M.avante then
        -- Avante 的容器窗口也进左侧 edgebar：排在 Explorer 下面，同一列、共用列宽
        vim.list_extend(opts.left, {
            {
                -- 结果区：自适应，吃掉其余面板剩下的高度
                ft = "Avante",
                title = "Avante",
                filter = not_float,
                wo = avante_wo,
            },
            {
                -- 竖列里用绝对行数，理由见文件顶部 avante_*_height 的注释
                ft = "AvanteSelectedCode",
                title = "Selected Code",
                filter = not_float,
                wo = avante_wo,
                size = { height = M.avante_selected_code_height },
            },
            {
                ft = "AvanteSelectedFiles",
                title = "Selected Files",
                filter = not_float,
                wo = avante_wo,
                size = { height = M.avante_selected_files_height },
            },
            {
                ft = "AvanteTodos",
                title = "Todos",
                filter = not_float,
                wo = avante_wo,
                size = { height = M.avante_todos_height },
            },
            {
                -- 输入区（native/nui provider 的 side 内输入框；snacks 浮窗被 not_float 过滤）
                ft = "AvanteInput",
                title = "Input",
                filter = not_float,
                wo = avante_wo,
                size = { height = M.avante_input_height },
            },
        })
        M.install_avante_layout_pause()
        M.install_avante_resize()
        M.install_avante_reattach()
    end

    return opts
end

return M
