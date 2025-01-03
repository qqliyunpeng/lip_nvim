

local function is_available(plugin)
  local lazy_config_avail, lazy_config_l = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config_l.spec.plugins[plugin] ~= nil
end

local telescope = require("telescope")
local db_path = os.getenv('HOME') .. '/.local/share/nvim/databases'

telescope.load_extension("zf-native")
telescope.load_extension("projects")
telescope.load_extension("noice")

if is_available("nvim-neoclip.lua") then
    telescope.load_extension("neoclip")
    telescope.load_extension("macroscope")
end

if is_available("telescope-smart-history.nvim") then
    if not vim.loop.fs_stat(db_path) then
        vim.loop.fs_mkdir(db_path, 493) -- 0x755
    end
    telescope.load_extension("smart_history")
end

return {
    defaults = {
        -- 全部文件，默认是如果有.gitignore 的话会根据 gitignore 进行处理
        vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename", "--line-number",
            "--column", "--smart-case",
            "--no-ignore",
        },
        -- 排除这些文件
        file_ignore_patterns = {
            "%.git/", "tags", "%.gitignore", "build/", "%.vscode/", "%.out$",
        },
        -- layout_strategy = "bottom_pane",
        path_display = {
            "filename_first",
            -- "truncate",
            -- truncate = 3,
        },
        prompt_prefix = "   ",
        selection_caret = "▍",
        entry_prefix = " ",
        sorting_strategy = "ascending",
        layout_config = {
            horizontal = {
                prompt_position = "top",
                preview_width = 0.55,
            },
            width = 0.90,
            height = 0.40,
        },
        mappings = {
            n = { ["q"] = require("telescope.actions").close },
            i = {
                ["<C-j>"] = require("telescope.actions").move_selection_next,
                ["<C-k>"] = require("telescope.actions").move_selection_previous,
                ["<Up>"]  = require("telescope.actions").cycle_history_prev,
                ["<Down>"]= require("telescope.actions").cycle_history_next,
            },
        },
        history = {
            path = db_path .. '/telescope_history.sqlite3',
            limit = 100,
        },
    },
    layout_config = {
        bottom = {
            height = 0.1,
        },
    },
    extensions = {
        file = {
            enable = true,
            highlight_results = true,
            match_filename = true,
            initial_sort = nil,
            smart_case = true,
        },
        generic = {
            enable = true,
            match_filename = false,
            initial_sort = nil,
            smart_case = true,
        },
    },
}
