local use_ascii_icons = require("configs.icons").use_ascii_icons()

local nerd_icons = {
    ft = "",
    lazy = "󰂠 ",
    loaded = "",
    not_loaded = "",
}

local ascii_icons = {
    ft = "F",
    lazy = "L",
    loaded = "+",
    not_loaded = "",
}

return {
  defaults = { lazy = true },

  ui = {
    icons = use_ascii_icons and ascii_icons or nerd_icons,
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
}

