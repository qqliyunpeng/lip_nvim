
local map = vim.keymap.set

-- 普通 :q/:qa 遇到未保存缓冲区时显示 Neovim 原生确认。
vim.o.confirm = true

vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- picker 后端开关：'fzf-lua' 或 'snacks'
-- 影响的键位：<leader>p / <leader>ff 找文件，<leader>fw / <leader>fc 查找
vim.g.picker_backend = 'snacks'

-- clangd 要不要使用国内源
local cus = os.getenv("CLANGD_USE_GITHUB") == "1"
if cus then
    vim.g.use_custom_clangd = false
else
    vim.g.use_custom_clangd = true
end

-- Copilot 总开关：COPILOT_AUTO_TRIGGER=1 时才启动 Copilot（含 copilot-language-server 的 Node 进程）。
-- 运行时可用 <leader>uc 切换；关闭会停掉 Node 进程并释放 600-800MB 内存。
local copilot_enabled = (os.getenv("COPILOT_AUTO_TRIGGER") or ""):lower()
vim.g.copilot_enabled = copilot_enabled == "1"
    or copilot_enabled == "true"
    or copilot_enabled == "yes"
    or copilot_enabled == "on"

-- system
map("n", " ", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")
map("v", "q", "<Esc>")
map("n", "<a-q>", "<Esc><cmd>noh<CR>")
map("x", "<a-q>", "<Esc>")
map("n", "<leader>q", "<cmd>q<CR>",  { desc = "CMD quit" })
map("n", "<leader>x", "<cmd>qa<CR>", { desc = "CMD quit all" })

require('options')

vim.env.TREE_SITTER_BOOTSTRAP_URL = "https://gitcode.net/CAPYIN/nvim-treesitter"

vim.api.nvim_create_augroup('MyVimEnterGroup', { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "man", "lspinfo", "checkhealth", "qf" },
    callback = function()
        vim.keymap.set("n", "q", "<cmd>quit<cr>", { buffer = true, silent = true })
    end,
})

-- force *.h files to use c filetype
-- force *.hpp files to use cpp filetype
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.h",
    callback = function()
        local fname = vim.fn.expand("%:p")
        local dir = vim.fn.fnamemodify(fname, ":h")

        -- 向上查找工程根目录
        local function find_root(path)
            local markers = { "CMakeLists.txt", "meson.build", ".git" }
            for _, m in ipairs(markers) do
                if vim.fn.filereadable(path .. "/" .. m) == 1 or vim.fn.isdirectory(path .. "/" .. m) == 1 then
                    return path
                end
            end
            local parent = vim.fn.fnamemodify(path, ":h")
            if parent == path then return nil end
            return find_root(parent)
        end

        local root = find_root(dir) or dir
        local has_cpp = vim.fn.glob(root .. "/*.cpp") ~= ""

        if has_cpp then
            vim.bo.filetype = "cpp"
        else
            vim.bo.filetype = "c"
        end
    end,
})

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.notify("lip: Begin to download lazy.nvim ...")
    local repo = "https://gitee.com/nvim_lip/lazy.nvim"
    local out = vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=main", lazypath }
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg"  },
            { out, "WarningMsg"  },
            { "\nPress any key to exit..."  },

        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
    { import = "plugins" },
}, lazy_config)

if vim.g.copilot_enabled then
    require("configs.ai").setCopilotEnabled(true)
end

require('mappings')

-- ui or color
-- 默认主题："onedark" 或 "catppuccin"
-- 两个主题各自的高亮覆盖：lua/configs/theme/onedark.lua / lua/configs/theme/catppuccin.lua
-- 切到哪个主题，就只生效它自己那份 hi，互不影响
local colorscheme = "catppuccin"

-- remember = true 时，:colorscheme 手动切换的结果会记下来，下次启动优先用它（会盖过上面的 colorscheme）
require("configs.theme").setup({ default = colorscheme, remember = false })

vim.lsp.set_log_level("off")

-- 打开文件后光标回到关闭的时候的位置
require('nvim-lastplace').setup{}

-- Project.nvim
vim.api.nvim_create_user_command('Root', 'ProjectRoot', {})  -- 将 :Root 映射到 :ProjectRoot
vim.api.nvim_create_user_command("A",    "Other",       {})
vim.api.nvim_create_user_command("AS",   "OtherSplit",  {})
vim.api.nvim_create_user_command("AV",   "OtherVSplit", {})
vim.api.nvim_create_user_command("AT",   "OtherTabNew", {})

require('noice')

require("configs.num_change").tg_format()
require("configs.num_change").tg_dot_array()
require("configs.num_change").tg_format_array()
require("configs.gencompiledb")

-- avante.nvim 兼容老 nvim 版本
vim.text = vim.text or {}
vim.text.diff = vim.diff
