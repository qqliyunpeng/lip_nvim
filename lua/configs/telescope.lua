
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
            ".git/*", "tags", ".gitignore", "build/*", ".vscode/*", "*.out",
        },
        -- layout_strategy = "bottom_pane",
        path_display = {
            "filename_first",
            -- "truncate",
            -- truncate = 3,
        },
        prompt_prefix = "   ",
        selection_caret = " ",
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
            },
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
