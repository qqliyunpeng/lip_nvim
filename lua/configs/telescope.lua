

local function is_available(plugin)
  local lazy_config_avail, lazy_config_l = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config_l.spec.plugins[plugin] ~= nil
end

local function send_key(key)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", false)
end

local telescope = require("telescope")
local db_path = os.getenv('HOME') .. '/.local/share/nvim/databases'

telescope.load_extension("live_grep_args")
telescope.load_extension("zf-native")
telescope.load_extension("persisted")
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

local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
-- vim.keymap.set("n", "<leader>fc", live_grep_args_shortcuts.grep_word_under_cursor)
vim.keymap.set("n", "<leader>fc", function ()
    live_grep_args_shortcuts.grep_word_under_cursor()

    -- simulator push left
    vim.defer_fn(function() send_key("<Left><Left><Left><Left><Left>") end, 50) -- delay ms
end)

local harpoon = require('harpoon')
local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
    end

    require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
            results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
    }):find()
end

vim.keymap.set("n", "<leader>fe", function() toggle_telescope(harpoon:list()) end,
    { desc = "Open harpoon window"})

vim.keymap.set("n", "<leader>fe", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
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
        sort_lastused = false,
        layout_config = {
            horizontal = {
                prompt_position = "top",
                preview_width = 0.55,
            },
            width = 0.90,
            height = 0.40,
        },
        mappings = {
            n = {
                ["q"] = require("telescope.actions").close,
                ["<S-h>"] = function() send_key("^<Right><Right><Right>") end,
                ["<S-l>"] = function() send_key("$") end,
            },
            i = {
                ["<C-j>"] = require("telescope.actions").move_selection_next,
                ["<C-k>"] = require("telescope.actions").move_selection_previous,
                ["<C-l>"] = function() send_key("<Right>") end,
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
