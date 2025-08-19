local use_ascii_icons = require("configs.icons").use_ascii_icons()

local ascii_icons = {
    glyphs = {
        default = "[f]",
        folder = {
            default    = "[+]",
            empty      = "[o]",
            empty_open = "[o-]",
            open       = "[-]",
            symlink    = "[sym]",
        },
        git = {
            unmerged = "[um]",
        },
    },
}

local nerd_icons = {
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
}

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
  },
  renderer = {
    root_folder_label = false,
    highlight_git = true,
    indent_markers = { enable = true },
    icons = use_ascii_icons and ascii_icons or nerd_icons
  },
    git = {
        enable = true,
        ignore = false,
    },
}
