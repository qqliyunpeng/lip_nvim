
local M = {}

function M.defaultConfig()
    require('neoscroll').setup({
        mappings = {                 -- Keys to be mapped to their corresponding default scrolling animation
            '<C-u>', '<C-d>',
            '<C-b>', '<C-f>',
            '<C-y>', '<C-e>',
            'zt', 'zz', 'zb',
        },
        hide_cursor = false,          -- Hide cursor while scrolling
        stop_eof = true,             -- Stop at <EOF> when scrolling downwards
        respect_scrolloff = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
        cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
        easing = 'quadratic',        -- Default easing function
        performance_mode = false,    -- Disable "Performance Mode" on all buffers.
        ignored_events = {           -- Events ignored while scrolling
            'WinScrolled', 'CursorMoved'
        },
        pre_hook  = function() Snacks.scroll.disable() end,
        post_hook = function() Snacks.scroll.enable()  end,
    })

    -- neoscroll 滚动顺滑
    local neoscroll = require('neoscroll')
    local keymap = {
        -- Use the "sine" easing function
        ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 200; easing = 'sine' }) end;
        ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 200; easing = 'sine' }) end;
        -- Use the "circular" easing function
        ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 450; easing = 'circular' }) end;
        ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 450; easing = 'circular' }) end;
        -- When no value is passed the `easing` option supplied in `setup()` is used
        ["<A-y>"] = function() neoscroll.scroll(-0.1, { move_cursor=false; duration = 100 }) end;
        ["<A-w>"] = function() neoscroll.scroll(-0.1, { move_cursor=false; duration = 100 }) end;
        ["<A-e>"] = function() neoscroll.scroll(0.1, { move_cursor=false; duration = 100 }) end;
    }
    local modes = { 'n', 'v', 'x' }
    for key, func in pairs(keymap) do
        vim.keymap.set(modes, key, func)
    end
end

return M

