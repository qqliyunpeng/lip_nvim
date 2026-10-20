package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

local calls = {}

_G.vim = {
    g = {},
    env = {},
    bo = {
        [1] = { buftype = "" },
        [2] = { buftype = "" },
        [3] = { buftype = "nofile" },
    },
    api = {
        nvim_set_hl = function(_, name, opts)
            calls[name] = opts
        end,
        nvim_get_autocmds = function()
            return { { id = 17 } }
        end,
        nvim_del_autocmd = function(id)
            calls.deleted_autocmd = id
        end,
        nvim_list_wins = function()
            return { 101, 102, 103 }
        end,
        nvim_win_get_buf = function(win)
            return win - 100
        end,
        nvim_win_get_config = function(win)
            return { relative = win == 103 and "editor" or "" }
        end,
        nvim_buf_get_name = function(buf)
            return buf < 3 and "/tmp/file" .. buf or ""
        end,
    },
}

local ai = require("configs.ai")
local helpers = ai._test

helpers.set_avante_window_highlights()
helpers.disable_avante_quitpre()

local function eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s\nexpected: %s\nactual:   %s", label, tostring(expected), tostring(actual)), 2)
    end
end

eq(calls.AvanteSidebarNormal.link, "Normal", "Avante sidebar uses the active window background")
eq(calls.AvantePromptInput.link, "Normal", "Avante input uses the active window background")
helpers.set_avante_window_highlights(false)
eq(calls.AvanteSidebarNormal.link, "NormalNC", "Avante sidebar dims after focus leaves")
helpers.set_avante_window_highlights(true)
eq(calls.AvanteSidebarNormal.link, "Normal", "Avante sidebar turns black again after focus enters")
eq(calls.deleted_autocmd, 17, "Avante's window-counting QuitPre autocmd is disabled")
eq(helpers.count_file_windows(), 2, "split file windows are counted separately")
eq(
    helpers.avante_winhighlight("CursorLine:Normal,Normal:AvanteSidebarNormal", "Avante", false),
    "CursorLine:Normal,Normal:NormalNC",
    "Avante sidebar uses the inactive window background after leaving"
)
eq(
    helpers.avante_winhighlight("FloatBorder:AvantePromptInputBorder,Normal:NormalNC", "AvantePromptInput", true),
    "FloatBorder:AvantePromptInputBorder,Normal:AvantePromptInput",
    "Avante prompt input restores the active window background after entering"
)
eq(
    helpers.avante_winhighlight("Normal:EdgyNormal,CursorLine:Normal,Normal:AvanteSidebarNormal", "Avante", true),
    "CursorLine:Normal,Normal:AvanteSidebarNormal",
    "duplicate Normal mappings collapse and the desired background is applied last"
)

print("avante_highlight_spec: ok")
