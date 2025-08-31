local M = {}

function M.detect_terminal()
    local term = vim.env.TERM or ""
    if term == "xterm-256color" then
        return "nerd"
    else
        return "ascii"
    end
end

function M.use_ascii_icons()
    local term = M.detect_terminal()
    if term == "ascii" then
        return true
    end
    return false
end


function M.componentsIcons()
    local nerd_icons = {
        ActiveLSP = "",
        ActiveTS = "",
        ArrowLeft = "",
        ArrowRight = "",
        Bookmarks = "",
        BufferClose = "󰅖",
        DapBreakpoint = "",
        DapBreakpointCondition = "",
        DapBreakpointRejected = "",
        DapLogPoint = ".>",
        DapStopped = "󰁕",
        Debugger = "",
        DefaultFile = "󰈙",
        Diagnostic = "󰒡",
        DiagnosticError = "",
        DiagnosticHint = "󰌵",
        DiagnosticInfo = "󰋼",
        DiagnosticWarn = "",
        Ellipsis = "…",
        Environment = "",
        FileNew = "",
        FileModified = "",
        FileReadOnly = "",
        FoldClosed = "",
        FoldOpened = "",
        FoldSeparator = " ",
        FolderClosed = "",
        FolderEmpty = "",
        FolderOpen = "",
        Git = "󰊢",
        GitAdd = "",
        GitBranch = "",
        GitChange = "",
        GitConflict = "",
        GitDelete = "",
        GitIgnored = "◌",
        GitRenamed = "➜",
        GitSign = "▎",
        GitStaged = "✓",
        GitUnstaged = "✗",
        GitUntracked = "★",
        LSPLoaded = "",
        LSPLoading1 = "",
        LSPLoading2 = "󰀚",
        LSPLoading3 = "",
        MacroRecording = "",
        Package = "󰏖",
        Paste = "󰅌",
        Refresh = "",
        Run = "󰑮",
        Search = "",
        Selected = "❯",
        Session = "󱂬",
        Sort = "󰒺",
        Spellcheck = "󰓆",
        Tab = "󰓩",
        TabClose = "󰅙",
        Terminal = "",
        Window = "",
        WordFile = "󰈭",
        Test = "󰙨",
        Docs = "",
    }

    local ascii_icons = {
        ActiveLSP = "",
        ActiveTS = "",
        ArrowLeft = "",
        ArrowRight = "",
        Bookmarks = "",
        BufferClose = "X",
        DapBreakpoint = "",
        DapBreakpointCondition = "?",
        DapBreakpointRejected = "!",
        DapLogPoint = ".>",
        DapStopped = "S",
        Debugger = "",
        DefaultFile = "F",
        Diagnostic = "D",
        DiagnosticError = "E",
        DiagnosticHint = "H",
        DiagnosticInfo = "I",
        DiagnosticWarn = "W",
        Ellipsis = "...",
        Environment = "[ENV]",
        FileNew = "+",
        FileModified = "*",
        FileReadOnly = "RO",
        FoldClosed = ">",
        FoldOpened = "v",
        FoldSeparator = " ",
        FolderClosed = "[DIR]",
        FolderEmpty = "[E-DIR]",
        FolderOpen = "[OPEN]",
        Git = "[GIT]",
        GitAdd = "",
        GitBranch = "",
        GitChange = "",
        GitConflict = "",
        GitDelete = "",
        GitIgnored = "◌",
        GitRenamed = "➜",
        GitSign = "▎",
        GitStaged = "✓",
        GitUnstaged = "✗",
        GitUntracked = "★",
        LSPLoaded = "",
        LSPLoading1 = "",
        LSPLoading2 = "󰀚",
        LSPLoading3 = "",
        MacroRecording = "",
        Package = "[PKG]",
        Paste = "[PASTE]",
        Refresh = "",
        Run = "[RUN]",
        Search = "",
        Selected = ">",
        Session = "[SESS]",
        Sort = "[SORT]",
        Spellcheck = "[SP]",
        Tab = "[TAB]",
        TabClose = "X",
        Terminal = "",
        Window = "[WIN]",
        WordFile = "[DOC]",
        Test = "[TEST]",
        Docs = "[MD]",
    }
    local icons = M.use_ascii_icons() and ascii_icons or nerd_icons
    return icons
end


local snacks_nerd_icons = {
    find_file   = " ",
    new_file    = " ",
    find_text   = " ",
    recent      = " ",
    config      = " ",
    all_session = " ",
    restore     = " ",
    extras      = " ",
    lazy        = "󰒲 ",
    quit        = " ",
}

local snacks_asci_icons = {
    find_file   = "[F] ",
    new_file    = "[N] ",
    find_text   = "[G] ",
    recent      = "[R] ",
    config      = "[C] ",
    all_session = "[S] ",
    restore     = "[SR]",
    extras      = "[X] ",
    lazy        = "[L] ",
    quit        = "[Q] ",
}


function M.snacksIcons()
    local icons = M.use_ascii_icons() and snacks_asci_icons or snacks_nerd_icons
    return icons
end


return M

