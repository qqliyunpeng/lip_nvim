local ge = require("lip.utils").ge

-- nvim-bqf 的预览高亮走的是 nvim-treesitter 的旧接口（nvim-treesitter.configs、
-- parsers.get_parser），而本配置用的是重写后的 main 分支，这些接口都没了，
-- 直接打开 qf 窗口会在 require 阶段报错。这里用 Neovim 自带的 vim.treesitter
-- 顶上 bqf 用到的 4 个函数（接口见 bqf/preview/handler.lua）：
-- 预览继续走 treesitter，语言没有装 parser 时返回 false，bqf 自己回退到 syntax。
-- 等上游适配了新接口（或删掉 nvim-bqf 时），这段可以直接去掉。
local function install_treesitter_preview()
    if package.loaded["bqf.preview.treesitter"] then
        return
    end

    package.loaded["bqf.preview.treesitter"] = {
        ---@param bufnr number
        disableActive = function(bufnr)
            pcall(vim.treesitter.stop, bufnr)
        end,

        shrinkCache = function() end,

        -- 预览缓冲区只有内容、没有 filetype，按探测出来的 ft 直接起 treesitter
        ---@param _ number 源 buffer
        ---@param dst number 预览 buffer
        ---@param ft string
        attach = function(_, dst, ft)
            local ok, lang = pcall(vim.treesitter.language.get_lang, ft)
            if not ok or not lang then
                return false
            end
            return pcall(vim.treesitter.start, dst, lang)
        end,

        -- 复用已加载 buffer 的 parser 属于优化项，这里不做，交给 attach 重新解析
        tryAttach = function()
            return false
        end,
    }
end

-- 开关 quickfix 窗口；窗口里的操作仍用 bqf 自带键位（<CR> 打开、zf 进 fzf、Tab 打点）
local function toggle_qf()
    local winid = vim.fn.getqflist({ winid = 0 }).winid
    if winid ~= 0 and vim.api.nvim_win_is_valid(winid) then
        vim.cmd("cclose")
    else
        vim.cmd("copen")
    end
end

return {
    {
        -- quickfix 窗口增强：预览浮窗、sign 过滤、fzf 过滤。https://github.com/kevinhwang91/nvim-bqf
        -- 只在 :copen / Overseer / vimgrep 打开 qf 时加载
        ge("nvim_lip/nvim-bqf"),
        ft = "qf",
        init = install_treesitter_preview,
        keys = {
            { "<leader>uq", toggle_qf, desc = "Toggle QuickFix" },
        },
        opts = {
            auto_enable = true,
            -- qf 窗口的宽高交给 edgy 的底部 edgebar 统一分配（30% 行高），
            -- 不要再跟着列表长度自动缩放，也不让 bqf 去调相邻窗口高度，
            -- 否则两套布局逻辑会抢同一个窗口。
            auto_resize_height = false,
            magic_window = false,
            preview = {
                border = "rounded",
                win_height = 15, -- 横向布局时预览窗高度
                win_vheight = 15, -- 纵向布局时预览窗高度
                delay_syntax = 50,
                winblend = 0, -- 预览不透明，C 代码在 catppuccin 下更好读
                show_title = true,
                show_scroll_bar = true,
                wrap = false,
                buf_label = true,
                -- 大文件不预览：每次移动光标都会重绘整个预览缓冲区
                should_preview_cb = function(bufnr)
                    if not vim.api.nvim_buf_is_valid(bufnr) then
                        return false
                    end
                    local name = vim.api.nvim_buf_get_name(bufnr)
                    -- 空名字（未保存）和 term://、fugitive:// 这类虚拟 buffer 没有意义
                    if name == "" or name:match("^%a[%w+.-]*://") then
                        return false
                    end
                    local size = vim.fn.getfsize(name)
                    return size >= 0 and size <= 200 * 1024
                end,
            },
            filter = {
                fzf = {
                    -- fzf 模式下用 ctrl-t/x/v 打开条目；fzf 需要在 PATH 里（~/.fzf/bin）
                    action_for = {
                        ["ctrl-t"] = "tab drop",
                        ["ctrl-x"] = "split",
                        ["ctrl-v"] = "vsplit",
                    },
                    extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "> " },
                },
            },
        },
    },
}

