package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

local calls = {}

_G.vim = {
    g = {},
    api = {
        nvim_set_hl = function(_, name, opts)
            calls[name] = opts
        end,
    },
}

local ai = require("configs.ai")
local helpers = ai._test

helpers.set_avante_window_highlights()

local function eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s\nexpected: %s\nactual:   %s", label, tostring(expected), tostring(actual)), 2)
    end
end

eq(calls.AvanteSidebarNormal.link, "Normal", "Avante sidebar uses the active window background")
eq(calls.AvantePromptInput.link, "Normal", "Avante input uses the active window background")
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

local rendered = nil
package.preload["render-markdown.api"] = function()
    return {
        render = function(context)
            rendered = context
        end,
    }
end
vim.api.nvim_buf_is_valid = function(bufnr)
    return bufnr == 42
end

helpers.render_avante_markdown(42)
eq(rendered.buf, 42, "Avante completion renders its result buffer")
eq(rendered.event, "AvanteViewBufferUpdated", "Avante completion identifies its render event")

print("avante_highlight_spec: ok")
