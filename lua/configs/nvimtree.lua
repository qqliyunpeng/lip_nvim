return {
  -- filters = { dotfiles = false },
  filters = {
        custom = { ".git", ".vscode", "build", ".gitignore", "*.out", "tags" },
  },
  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  view = {
    width = 30,
    preserve_window_proportions = true,
    mappings = {
            custom_only = false,
            list = {
                { key = "l", action = "edit" },
                { key = "h", action = "close_node" },
            },
        },
  },
  renderer = {
    root_folder_label = false,
    highlight_git = true,
    indent_markers = { enable = true },
    icons = {
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = { unmerged = "" },
      },
    },
  },
    git = {
        enable = true,
        ignore = false,
    },
}
