local M = {}
local heirline = require('heirline')

local conditions = require("heirline.conditions")
local utils = require("heirline.utils")
local Align = { provider = "%="  }
local Space = { provider = " "  }
local heirline_components = require("heirline-components.all")
local lib = require "heirline-components.all"

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


----lip 1----
local function project_name()
    local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
    local name = vim.fs.basename(vim.fs.normalize(root))
    return vim.fn.strcharpart(name, 0, 10)
end

local ProjectName = {
    provider = function()
        return project_name()
    end,
    hl = function()
        local task_colors = {
            running = "#EEC956",
            success = "#9ECE6A",
            failure = "#E47272",
        }
        local task_color = task_colors[vim.g.overseer_heirline_status]
        return {
            fg = task_color and "#000000" or utils.get_highlight("Directory").fg,
            bg = task_color,
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
        mode_colors = {
            n = "#7AA2F7",
            i = "#9ECE6A",
            v = "#BB9AF7",
            V = "#BB9AF7",
            ["\22"] = "#BB9AF7",
            c =  "orange",
            s =  "purple",
            S =  "purple",
            ["\19"] =  "purple",
            R =  "orange",
            r =  "orange",
            ["!"] =  "red",
            t =  "red",
        }
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

local VisualSeparators = {
    provider = function()
        local mode = vim.fn.mode()
        if not mode:match("[vV]") then
            return ""
        end
        local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
        local text = table.concat(region, "\n")
        local count = 0
        local label = ","
        if text:find(",", 1, true) then
            local _, matches = text:gsub(",", "")
            count = matches + 1
            if text:match(",%s*$") then
                count = count - 1
            end
        else
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
    { ViMode }, Space,
    ProjectName, Space, Space,
    lib.component.git_branch(),
    lib.component.git_diff(),
    { FileNameBlock }, Space,
    -- lib.component.file_info(),
    Align,
    lib.component.cmd_info(),
    Align,
    -- lib.component.lsp(),
    {
        condition = function()
            return not is_avante_buffer()
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
        statusline = StatusLine,
    })
end

return M
