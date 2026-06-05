local use_ascii_icons = require("configs.icons").use_ascii_icons()
local avante_refresh = require("configs.avante_refresh")

local function setup_avante_refresh_on_tree_events()
    if vim.g.lip_nvim_tree_avante_refresh_events then
        return
    end

    local ok, api = pcall(require, "nvim-tree.api")
    if not ok then
        return
    end

    api.events.subscribe(api.events.Event.TreeClose, function()
        avante_refresh.refresh({ require_tree_closed = true })
    end)
    vim.g.lip_nvim_tree_avante_refresh_events = true
end

setup_avante_refresh_on_tree_events()

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
