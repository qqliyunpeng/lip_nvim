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
-- Avante 打开时作为左 edgebar 的 size（和 NvimTree 共用同一列），
-- 也同步给 avante 的 windows.width（configs/ai.lua）。
M.avante_width = 0.4

-- NvimTree 单独在左侧时的宽度（列数）。Avante 打开时两者共用同一列，
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

-- Explorer（NvimTree）高度：有 Avante 结果区时给它一个上限，剩下的行全给结果区。
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

local function left_edgebar_width()
    if avante_result_open() then
        return M.avante_width
    end
    local max_width = math.max(1, math.floor(vim.o.columns * M.avante_width))
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
        if vim.g.lip_edgy_pause then
            return
        end
        return original_update(...)
    end
    M._avante_layout_pause_installed = true
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
local avante_wo = { winhighlight = "Normal:AvanteSidebarNormal" }

function M.opts()
    local opts = {
        -- edgebar 展开/收起不播放动画（默认是开）
        animate = { enabled = false },
        -- 其余顶层选项（exit_when_last / close_when_all_hidden）和窗口选项（wo：
        -- winbar / winfixwidth / winhighlight / signcolumn…）都用 edgy 默认值，
        -- 只有下面这几条和默认值不同，所以只写这些。
        options = {
            -- Avante 在左侧 edgebar，和 NvimTree 共用这一列的宽度；
            -- 只有 NvimTree 时按 explorer_width 收窄
            left = { size = left_edgebar_width },
            -- 0.3 = 30% 行高。注意：底部 edgebar 里的所有 view 共用同一个高度，
            -- 这里才是真正的面板高度（view 自己的 size.height 只是最小值）
            bottom = { size = 0.3 },
        },
        left = {
            {
                ft = "NvimTree",
                title = "Explorer",
                filter = not_float,
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
        M.install_avante_reattach()
    end

    return opts
end

return M
