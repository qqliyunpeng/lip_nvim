local M = {}
local heirline = require('heirline')

local conditions = require("heirline.conditions")
local utils = require("heirline.utils")
local Align = { provider = "%="  }
local Space = { provider = " "  }
local heirline_components = require("heirline-components.all")
local lib = require "heirline-components.all"
local mode_colors = require("configs.mode_colors")

local avante_filetypes = {
    Avante = true,
    AvanteInput = true,
    AvantePromptInput = true,
    AvanteSelectedFiles = true,
    AvanteTodos = true,
}

local function is_avante_buffer()
    return avante_filetypes[vim.bo.filetype] == true
end

-- Setup heirline-components.nvim
heirline_components.init.subscribe_to_events()
heirline.load_colors(heirline_components.hl.get_colors())

local avante_state_colors = { utils.get_highlight("Normal").fg, "#101010", "#292929", "#444444", "#606060", "#767676" }
for index, color in ipairs(avante_state_colors) do
    vim.api.nvim_set_hl(0, "AvanteHeirlineState" .. index, { fg = color })
end


----lip 1----
-- 项目名显示层数（2 = 父目录/项目目录）与最大宽度（字符）
local PROJECT_NAME_DEPTH = 2
local PROJECT_NAME_MAX = 24

local function project_name()
    local root = vim.fs.normalize(vim.fs.root(0, ".git") or vim.fn.getcwd())
    local parts = {}
    for _ = 1, PROJECT_NAME_DEPTH do
        local base = vim.fs.basename(root)
        if base == "" then break end
        table.insert(parts, 1, base)
        root = vim.fs.dirname(root)
    end
    local name = table.concat(parts, "/")
    -- 超长时保留尾部（叶子目录信息量更大），前面用省略号
    local len = vim.fn.strchars(name)
    if len > PROJECT_NAME_MAX then
        name = "…" .. vim.fn.strcharpart(name, len - PROJECT_NAME_MAX + 1)
    end
    return name
end

local ProjectName = {
    provider = function()
        if vim.g.overseer_heirline_status == "running" then
            local letters = {}
            for index = 1, #"building" do
                letters[index] = string.format("%%#OverseerBuilding%d#%s", index, string.sub("building", index, index))
            end
            return table.concat(letters) .. "%*"
        elseif vim.g.overseer_heirline_status == "success" then
            return "Success"
        elseif vim.g.overseer_heirline_status == "failure" then
            return "Failed"
        end
        return project_name()
    end,
    hl = function()
        if vim.g.overseer_heirline_status == "running" then
            return { fg = "#EEC956" }
        end
        local task_colors = {
            success = "#9ECE6A",
            failure = "#E47272",
        }
        local task_color = task_colors[vim.g.overseer_heirline_status]
        return {
            fg = task_color or utils.get_highlight("Directory").fg,
        }
    end,
}

local ViMode = {
    -- get vim current mode, this information will be required by the provider
    -- and the highlight functions, so we compute it only once per component
    -- evaluation and store it as a component attribute
    init = function(self)
        self.mode = vim.fn.mode(1) -- :h mode()
    end,
    -- Now we define some dictionaries to map the output of mode() to the
    -- corresponding string and color. We can put these into `static` to compute
    -- them at initialisation time.
    static = {
        mode_names = { -- change the strings if you like it vvvvverbose!
            n = "N",
            no = "N?",
            nov = "N?",
            noV = "N?",
            ["no\22"] = "N?",
            niI = "Ni",
            niR = "Nr",
            niV = "Nv",
            nt = "Nt",
            v = "V",
            vs = "Vs",
            V = "V_",
            Vs = "Vs",
            ["\22"] = "^V",
            ["\22s"] = "^V",
            s = "S",
            S = "S_",
            ["\19"] = "^S",
            i = "I",
            ic = "Ic",
            ix = "Ix",
            R = "R",
            Rc = "Rc",
            Rx = "Rx",
            Rv = "Rv",
            Rvc = "Rv",
            Rvx = "Rv",
            c = "C",
            cv = "Ex",
            r = "...",
            rm = "M",
            ["r?"] = "?",
            ["!"] = "!",
            t = "T",
        },
        mode_colors = mode_colors,
    },
    -- We can now access the value of mode() that, by now, would have been
    -- computed by `init()` and use it to index our strings dictionary.
    -- note how `static` fields become just regular attributes once the
    -- component is instantiated.
    -- To be extra meticulous, we can also add some vim statusline syntax to
    -- control the padding and make sure our string is always at least 2
    -- characters long. Plus a nice Icon.
    provider = function(self)
        return " " .. self.mode_names[self.mode] .. " "
    end,
    -- Same goes for the highlight. Now the foreground will change according to the current mode.
    hl = function(self)
        local mode = self.mode:sub(1, 1) -- get only the first mode character
        return { fg = "#000000", bg = self.mode_colors[mode], bold = true, }
    end,
    -- Re-evaluate the component only on ModeChanged event!
    -- Also allows the statusline to be re-evaluated when entering operator-pending mode
    update = {
        "ModeChanged",
        pattern = "*:*",
        callback = vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
        end),
    },
}

----lip 2----
local FileNameBlock = {
    -- let's first set up some attributes needed by this component and its children
    init = function(self)
        self.filename = vim.api.nvim_buf_get_name(0)
    end,
}
-- We can now define some children separately and add them later

local FileIcon = {
    init = function(self)
        local filename = vim.fn.fnamemodify(self.filename, ":t")
        self.icon, self.icon_color =
            require("nvim-web-devicons").get_icon_color(filename, nil, { default = true })
    end,
    provider = function(self)
        return self.icon and (self.icon .. " ")
    end,
    hl = function(self)
        return { fg = self.icon_color }
    end
}

local FileName = {
    provider = function(self)
        local avante_names = {
            Avante = " AI ",
            AvanteInput = " AI ",
            AvanteSelectedFiles = " AI ",
        }
        if avante_names[vim.bo.filetype] then
            return avante_names[vim.bo.filetype]
        end
        -- first, trim the pattern relative to the current directory. For other
        -- options, see :h filename-modifers
        local filename = vim.fn.fnamemodify(self.filename, ":.")
        if filename == "" then return "[No Name]" end
        -- now, if the filename would occupy more than 1/4th of the available
        -- space, we trim the file path to its initials
        -- See Flexible Components section below for dynamic truncation
        if not conditions.width_percent_below(#filename, 0.25) then
            filename = vim.fn.pathshorten(filename)
        end
        return filename
    end,
    hl = { fg = utils.get_highlight("Directory").fg },
}

local FileFlags = {
    {
        condition = function()
            return vim.bo.modified
        end,
        provider = "[+]",
        hl = { fg = "green" },
    },
    {
        condition = function()
            return not is_avante_buffer() and (not vim.bo.modifiable or vim.bo.readonly)
        end,
        provider = "",
        hl = { fg = "orange" },
    },
}

-- Now, let's say that we want the filename color to change if the buffer is
-- modified. Of course, we could do that directly using the FileName.hl field,
-- but we'll see how easy it is to alter existing components using a "modifier"
-- component

local FileNameModifer = {
    hl = function()
        if vim.bo.modified then
            -- use `force` because we need to override the child's hl foreground
            return { fg = "cyan", bold = true, force=true }
        end
    end,
}

-- let's add the children to our FileNameBlock component
FileNameBlock = utils.insert(FileNameBlock, FileIcon,
        utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
        FileFlags,
        { provider = '%<'} -- this means that the statusline is cut here when there's not enough space
    )

local FileEncoding = {
    condition = function()
        return not is_avante_buffer()
    end,
    provider = function()
        local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
        return enc:upper()
    end,
    hl = { fg = heirline_components.hl.get_colors().green,
            bg = heirline_components.hl.get_colors().blue },
}

local FileFormat = {
    condition = function()
        return not is_avante_buffer()
    end,
    provider = function()
        local eol = vim.bo.fileformat
        if eol == 'unix' then
            return 'LF'
        elseif eol == 'dos' then
            return 'CRLF'
        else
            return 'N/A'
        end
    end
}

local VisualSelection = {
    provider = function()
        local mode = vim.fn.mode()
        if not mode:match("[vV]") then
            return ""
        end
        local wc = vim.fn.wordcount()
        local count = wc.visual_chars or 0
        if count > 999 then
            return ""
        end
        return string.format("[v:%d]", count)
    end,
    hl = { fg = "#00FFFF", bold = true },
    condition = function()
        return vim.fn.mode():match("[vV]") ~= nil
    end,
}

local AvanteSubmitHint = {
    condition = function()
        return vim.bo.filetype == "AvanteInput" or vim.bo.filetype == "AvantePromptInput"
    end,
    provider = function()
        local submit = require("avante.config").mappings.submit
        local key = vim.fn.mode() == "i" and submit.insert or submit.normal
        return key .. ": submit"
    end,
    hl = { fg = utils.get_highlight("AvantePopupHint").fg },
    update = { "ModeChanged" },
}

local AvanteScrollHint = {
    condition = function()
        return vim.bo.filetype == "Avante" or vim.bo.filetype == "AvanteInput"
    end,
    provider = " <C-End>: bottom ",
    hl = { fg = utils.get_highlight("AvantePopupHint").fg },
}

local AvanteInputStatusLine = {
    condition = function()
        return conditions.is_active() and AvanteSubmitHint.condition()
    end,
    hl = { fg = "fg", bg = "bg" },
    {
        provider = function()
            local winid = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
            local win_col = vim.api.nvim_win_get_position(winid)[2]
            local boundary = win_col + vim.api.nvim_win_get_width(winid)
            return "%-" .. boundary .. "("
        end,
    },
    { ViMode }, Space, Space,
    ProjectName, Space, Space,
    lib.component.git_branch(),
    lib.component.git_diff(),
    { FileNameBlock },
    Align,
    Space,
    AvanteSubmitHint,
    AvanteScrollHint,
    { provider = "%)" },
    Align,
}

local AvanteState = {
    condition = function()
        return is_avante_buffer() and vim.g.avante_heirline_state ~= nil
    end,
    provider = function()
        local state = vim.g.avante_heirline_state
        local animated = state == "generating" or state == "tool calling"
            or state == "thinking" or state == "compacting"
        if not animated then
            return state
        end
        local trail_length = #avante_state_colors - 1
        local pause_frames = 32
        local active = ((vim.g.avante_heirline_spinner or 1) - 1)
            % (#state + trail_length + pause_frames) + 1
        local letters = {}
        for index = 1, #state do
            local distance = active - index
            local color_index = distance >= 0 and distance < trail_length and distance + 2 or 1
            local group = "AvanteHeirlineState" .. color_index
            letters[index] = string.format("%%#%s#%s", group, state:sub(index, index))
        end
        return table.concat(letters) .. "%*"
    end,
    hl = function()
        local colors = {
            failed = "red",
            succeeded = "#98C379",
            cancelled = "orange",
            thinking = "yellow",
        }
        return { fg = colors[vim.g.avante_heirline_state] or "cyan", bold = true }
    end,
}

local function neo_composer_active()
    if package.loaded["NeoComposer.state"] == nil then
        return false
    end
    local state = require("NeoComposer.state")
    return state.get_recording() or state.get_playing() or state.get_delay()
end

local NeoComposerStatus = {
    condition = function()
        return neo_composer_active()
    end,
    init = function(self)
        self.status = require("NeoComposer.ui").status_recording()
    end,
    provider = function(self)
        return self.status or ""
    end,
    update = {
        "User",
        pattern = {
            "NeoComposerRecordingSet",
            "NeoComposerPlayingSet",
            "NeoComposerDelaySet",
        },
        callback = function(self)
            self.status = require("NeoComposer.ui").status_recording()
        end,
    },
}

local VisualSeparators = {
    provider = function()
        local mode = vim.fn.mode()
        -- getregion() 只接受基础 Visual 模式，去掉 select 状态后缀。
        local region_type = mode:sub(1, 1)
        if region_type ~= "v" and region_type ~= "V" and region_type ~= "" then
            return ""
        end
        -- 获取当前 Visual 选区，并把多行内容拼接成一段文本。
        local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = region_type })
        local text = table.concat(region, "\n")
        local count = 0
        local label = ","
        if text:find(",", 1, true) then
            -- 包含逗号时，统计由逗号分隔出的段落数量。
            local _, matches = text:gsub(",", "")
            count = matches + 1
            -- 末尾逗号不算作一个空段落。
            if text:match(",%s*$") then
                count = count - 1
            end
        else
            -- 不包含逗号时，统计由空白分隔出的非空段落数量。
            label = "s"
            for _ in text:gmatch("%S+") do
                count = count + 1
            end
        end
        if count == 0 then
            return ""
        end
        return string.format("[%s:%d]", label, count)
    end,
    hl = { fg = "#00FFFF", bold = true },
    condition = function()
        return vim.fn.mode():match("[vV]") ~= nil
    end,
}

local StatusLine = {
    condition = conditions.is_active,
    hl = { fg = "fg", bg = "bg" },
    { ViMode }, Space, Space,
    ProjectName, Space, Space,
    lib.component.git_branch(),
    lib.component.git_diff(),
    { FileNameBlock }, Space, Space,
    -- AvanteState,
    -- lib.component.file_info(),
    Align,
    {
        condition = function()
            return not neo_composer_active()
        end,
        lib.component.cmd_info(),
    },
    NeoComposerStatus,
    AvanteScrollHint,
    Align,
    -- lib.component.lsp(),
    {
        condition = function()
            return not is_avante_buffer() and package.loaded.overseer ~= nil
        end,
        lib.component.compiler_state(),
    },
    Space, Space,
    lib.component.diagnostics(),
    -- lib.component.virtual_env(),
    Space, Space,
    { FileEncoding }, Space, Space,
    { FileFormat }, Space, Space,
    VisualSelection,
    VisualSeparators,
    {
        condition = function()
            return not is_avante_buffer()
        end,
        lib.component.nav(),
    },
}

function M.config()
    -- show one statusline in bottom
    vim.cmd("set laststatus=3")
    heirline.setup({
        statusline = {
            fallthrough = false,
            AvanteInputStatusLine,
            StatusLine,
        },
    })
end

return M
