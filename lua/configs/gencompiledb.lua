-- ~/.config/nvim/lua/utils/gen_compile_db.lua
local M = {}

-- 更稳健的 JSON 美化函数（不会执行任何外部命令）
local function pretty_print(json_str)
    local indent = 0
    local in_str = false
    local res = {}
    local i = 1
    while i <= #json_str do
        local ch = json_str:sub(i, i)
        if ch == '"' then
            -- 判断是否被转义
            local j = i - 1
            local esc = false
            while j > 0 and json_str:sub(j, j) == "\\" do
                esc = not esc
                j = j - 1
            end
            if not esc then
                in_str = not in_str
            end
            table.insert(res, ch)
            i = i + 1
        elseif not in_str and (ch == "{" or ch == "[") then
            table.insert(res, ch)
            indent = indent + 1
            table.insert(res, "\n" .. string.rep("  ", indent))
            i = i + 1
        elseif not in_str and (ch == "}" or ch == "]") then
            indent = indent - 1
            table.insert(res, "\n" .. string.rep("  ", indent) .. ch)
            i = i + 1
        elseif not in_str and ch == "," then
            table.insert(res, ch)
            table.insert(res, "\n" .. string.rep("  ", indent))
            i = i + 1
        elseif not in_str and ch == ":" then
            table.insert(res, ch .. " ")
            i = i + 1
        elseif not in_str and (ch == " " or ch == "\t" or ch == "\n" or ch == "\r") then
            -- 跳过结构空白：json_encode 已在 ":" "," 后自带空格，
            -- 不跳过会导致换行后每行多出一个空格（缩进错位）
            i = i + 1
        else
            table.insert(res, ch)
            i = i + 1
        end
    end
    return table.concat(res)
end

-- 规范化目录为不带尾斜杠的绝对路径（根目录 "/" 除外）
local function abs_dir(path)
    local p = vim.fn.fnamemodify(path, ":p")
    if #p > 1 then
        p = p:gsub("/+$", "")
    end
    return p
end

-- =====================================================================
-- Makefile 静态解析：提取编译用的 -I / -D（不执行 make 或任何外部命令）
-- =====================================================================

-- 去掉行内注释：从第一个未被反斜杠转义的 '#' 到行尾
local function strip_comment(line)
    local i = 1
    while i <= #line do
        if line:sub(i, i) == "#" then
            local j, n = i - 1, 0
            while j >= 1 and line:sub(j, j) == "\\" do
                n = n + 1
                j = j - 1
            end
            if n % 2 == 0 then
                return line:sub(1, i - 1)
            end
        end
        i = i + 1
    end
    return line
end

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- 相对路径基于 base 目录解析为绝对路径（根目录除外，去掉尾部斜杠）
local function resolve_path(base, p)
    if not p or p == "" then
        return nil
    end
    local full = (p:sub(1, 1) == "/") and p or (base .. "/" .. p)
    local abs = vim.fn.fnamemodify(full, ":p")
    -- 折叠重复斜杠与 "/./" 段，得到干净路径
    abs = abs:gsub("//+", "/")
    while abs:find("/%./", 1) do
        abs = abs:gsub("/%./", "/")
    end
    abs = abs:gsub("/%.$", "")
    if #abs > 1 then
        abs = abs:gsub("/+$", "")
    end
    if abs == "" then
        abs = "/"
    end
    return abs
end

-- 读取文件并合并续行（行尾反斜杠），同时去掉注释
local function load_logical_lines(path)
    local f = io.open(path, "r")
    if not f then
        return {}
    end
    local out, pending = {}, nil
    for raw in f:lines() do
        local line = strip_comment(raw:gsub("\r$", ""))
        if pending ~= nil then
            line = pending .. " " .. line
        end
        if line:match("\\%s*$") then
            pending = line:gsub("\\%s*$", "")
        else
            pending = nil
            out[#out + 1] = line
        end
    end
    if pending ~= nil then
        out[#out + 1] = pending
    end
    f:close()
    return out
end

-- 当前正在解析的变量表：name -> { value = 原始文本, dir = 定义所在目录 }
local make_vars
local expand
local expand_ref

local function lookup_var(name, dir, depth)
    if name == "CURDIR" or name == "PWD" then
        return dir
    end
    local v = make_vars and make_vars[name]
    if not v then
        return ""
    end
    return expand(v.value, v.dir, depth + 1)
end

-- 展开 $(...) 内容：带空格的视为函数调用，否则视为变量
expand_ref = function(inner, dir, depth)
    if inner == "" then
        return ""
    end
    local first, rest = inner:match("^(%S+)%s*(.*)$")
    if rest ~= "" then
        -- 只支持 realpath / abspath，其它函数（shell/wildcard/patsubst...）无法静态求值
        if first == "realpath" or first == "abspath" then
            local arg = trim(expand(rest, dir, depth))
            if arg == "" then
                arg = "."
            end
            return resolve_path(dir, arg) or ""
        end
        return ""
    end
    return lookup_var(inner, dir, depth)
end

expand = function(s, dir, depth)
    depth = depth or 0
    if depth > 20 or s == nil or s == "" then
        return s or ""
    end
    local out = {}
    local i = 1
    while i <= #s do
        local ch = s:sub(i, i)
        if ch ~= "$" then
            out[#out + 1] = ch
            i = i + 1
        else
            local nxt = s:sub(i + 1, i + 1)
            if nxt == "$" then
                out[#out + 1] = "$"
                i = i + 2
            elseif nxt == "(" or nxt == "{" then
                local open, close = nxt, (nxt == "(" and ")" or "}")
                local level, j = 1, i + 2
                while j <= #s and level > 0 do
                    local c = s:sub(j, j)
                    if c == open then
                        level = level + 1
                    elseif c == close then
                        level = level - 1
                    end
                    j = j + 1
                end
                out[#out + 1] = expand_ref(s:sub(i + 2, j - 2), dir, depth)
                i = j
            else
                -- $@ $< 等自动变量无法静态求值
                i = i + 2
            end
        end
    end
    return table.concat(out)
end

-- 判断变量名是否可能承载编译标志
local function is_flag_var(name)
    if name:match("^LD") then
        return false
    end
    return name:find("INC", 1, true) ~= nil
        or name:find("DEF", 1, true) ~= nil
        or name:find("FLAG", 1, true) ~= nil
end

-- 从变量表中提取 -I（绝对化）与 -D
local function extract_flags(vars)
    local includes, inc_seen = {}, {}
    local defines, def_seen = {}, {}
    local names = {}
    for name in pairs(vars) do
        names[#names + 1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
        if is_flag_var(name) then
            local v = vars[name]
            local toks = {}
            for t in expand(v.value, v.dir, 0):gmatch("%S+") do
                toks[#toks + 1] = t
            end
            local k = 1
            while k <= #toks do
                local t = toks[k]
                -- 兼容 "-I dir" / "-D NAME" 分两个 token 的写法
                if (t == "-I" or t == "-D") and toks[k + 1] then
                    t = t .. toks[k + 1]
                    k = k + 1
                end
                k = k + 1
                if t:sub(1, 2) == "-I" then
                    local p = t:sub(3)
                    if p ~= "" and not p:find("$", 1, true) then
                        local abs = resolve_path(v.dir, p)
                        if abs and not inc_seen[abs] then
                            inc_seen[abs] = true
                            includes[#includes + 1] = abs
                        end
                    end
                elseif t:sub(1, 2) == "-D" then
                    if #t > 2 and not t:find("$", 1, true) and not def_seen[t] then
                        def_seen[t] = true
                        defines[#defines + 1] = t
                    end
                end
            end
        end
    end
    return includes, defines
end

-- 解析单个 Makefile，收集变量并递归跟踪 include
local function parse_makefile(path, vars, seen, depth)
    if depth > 10 then
        return
    end
    local abs = abs_dir(path)
    if seen[abs] then
        return
    end
    seen[abs] = true

    local dir = abs:match("^(.*)/[^/]*$")
    if not dir or dir == "" then
        dir = "/"
    end

    local in_define = false
    for _, line in ipairs(load_logical_lines(abs)) do
        if in_define then
            if line:match("^%s*endef%s*$") then
                in_define = false
            end
        elseif line:match("^%s*define%s") then
            in_define = true
        else
            local l = line:gsub("^%s+", "")
            l = l:gsub("^export%s+", ""):gsub("^override%s+", ""):gsub("^private%s+", "")
            local name, rest = l:match("^([%a_][%w_]*)%s*(.*)$")
            local op, value
            if name then
                if rest:sub(1, 3) == "::=" then
                    op, value = "::=", rest:sub(4)
                elseif rest:sub(1, 2) == ":=" then
                    op, value = ":=", rest:sub(3)
                elseif rest:sub(1, 2) == "?=" then
                    op, value = "?=", rest:sub(3)
                elseif rest:sub(1, 2) == "+=" then
                    op, value = "+=", rest:sub(3)
                elseif rest:sub(1, 1) == "=" then
                    op, value = "=", rest:sub(2)
                end
            end
            if op then
                value = trim(value)
                if op == "+=" and vars[name] then
                    vars[name].value = vars[name].value .. " " .. value
                elseif op == "?=" then
                    if not vars[name] then
                        vars[name] = { value = value, dir = dir }
                    end
                else
                    vars[name] = { value = value, dir = dir }
                end
            else
                local inc = l:match("^%-?s?include%s+(.+)$")
                if inc then
                    for tok in expand(inc, dir, 0):gmatch("%S+") do
                        local target = resolve_path(dir, tok)
                        if target and vim.fn.filereadable(target) == 1 then
                            parse_makefile(target, vars, seen, depth + 1)
                        end
                    end
                end
            end
        end
    end
end

-- 解析指定目录（不含父目录）下的 Makefile，返回 { includes, defines }
local function collect_flags_in(dir)
    local vars, seen = {}, {}
    make_vars = vars
    -- 与 GNU make 一致：按 GNUmakefile > makefile > Makefile 取第一个存在的
    -- （make 只会读其中一个，而不是全部合并）
    for _, name in ipairs({ "GNUmakefile", "makefile", "Makefile" }) do
        local p = dir .. "/" .. name
        if vim.fn.filereadable(p) == 1 then
            parse_makefile(p, vars, seen, 0)
            break
        end
    end
    local includes, defines = extract_flags(vars)
    make_vars = nil
    return { includes = includes, defines = defines }
end

-- 解析 root 下的 Makefile 中的 -I / -D
-- opts.upward：当前目录无任何 -I/-D 时，是否向上级目录继续查找（默认 true）
-- opts.max_up：最多向上查找几层（默认 6）
-- 返回 { includes = { "<绝对目录>", ... }, defines = { "-DNAME", ... }, dir = <命中目录> }
function M.collect_makefile_flags(root, opts)
    opts = opts or {}
    local search_up = (opts.upward ~= false)
    local max_up = opts.max_up or 6

    local home = vim.fn.expand("~"):gsub("/+$", "")
    local dir = abs_dir(root)
    local steps = 0
    while true do
        local flags = collect_flags_in(dir)
        if #flags.includes > 0 or #flags.defines > 0 then
            flags.dir = dir
            return flags
        end
        if not search_up or steps >= max_up or dir == "/" or dir == home then
            break
        end
        local parent = dir:match("^(.*)/[^/]*$")
        if not parent or parent == "" then
            break
        end
        dir = parent
        steps = steps + 1
    end
    return { includes = {}, defines = {}, dir = abs_dir(root) }
end

-- 生成 compile_commands.json（扫描当前目录及子目录，不执行任何编译）
function M.generate()
    local cwd = vim.fn.getcwd()
    local output = cwd .. "/compile_commands.json"

    -- ---- 可调整的编译参数 ----------------------------------------------
    local defines = {}              -- 宏定义，如 { "-DDEBUG" }（默认不添加）
    -- 额外头文件目录（相对项目根目录，不存在会被自动跳过）
    local extra_includes = { "include" }
    -- 当前目录 Makefile 无 -I/-D 时，是否向上级目录查找（如子目录 Makefile 仅转发 make -C ..）
    local makefile_search_up = true
    -- --------------------------------------------------------------------

    -- 从 Makefile 中静态提取编译用的 -I / -D（必要时向上查找父级 Makefile）
    local make_flags = M.collect_makefile_flags(cwd, { upward = makefile_search_up })

    -- 递归扫描当前目录下所有 .c / .cpp 文件
    local files = vim.fn.glob("**/*.c", true, true)
    local cpp_files = vim.fn.glob("**/*.cpp", true, true)
    vim.list_extend(files, cpp_files)

    if #files == 0 then
        vim.notify("GenCompileDB: 未找到源文件 (*.c, *.cpp)", vim.log.levels.WARN)
        return
    end

    local entries = {}
    for _, file in ipairs(files) do
        -- 头文件目录：额外目录 + 源文件所在目录 + 项目根目录（去重）
        local includes, seen = {}, {}
        local function add_include(dir)
            if not dir or dir == "" then
                return
            end
            local abs = abs_dir(dir)
            if not seen[abs] then
                seen[abs] = true
                includes[#includes + 1] = abs
            end
        end
        -- Makefile 中的头文件目录优先（相对各 Makefile 已是绝对路径）
        for _, dir in ipairs(make_flags.includes) do
            add_include(dir)
        end
        for _, dir in ipairs(extra_includes) do
            if vim.fn.isdirectory(dir) == 1 then
                add_include(dir)
            end
        end
        add_include(vim.fn.fnamemodify(file, ":h"))
        add_include(cwd)

        -- arguments 只放头文件目录 (-I) 和宏定义 (-D)
        local arguments = {}
        for _, dir in ipairs(includes) do
            arguments[#arguments + 1] = "-I" .. dir
        end
        for _, define in ipairs(defines) do
            arguments[#arguments + 1] = define
        end
        for _, define in ipairs(make_flags.defines) do
            arguments[#arguments + 1] = define
        end

        table.insert(entries, {
            directory = cwd,
            arguments = arguments,
            file = file,
        })
    end

    -- 先用 nvim 的 json_encode 生成紧凑 JSON，再用 pretty_print 美化
    local ok, compact = pcall(vim.fn.json_encode, entries)
    if not ok or not compact then
        vim.notify("GenCompileDB: JSON 序列化失败", vim.log.levels.ERROR)
        return
    end
    local pretty = pretty_print(compact)

    local f, err = io.open(output, "w")
    if not f then
        vim.notify("GenCompileDB: 无法写入文件: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    f:write(pretty)
    f:close()

    local mk_src = ""
    if make_flags.dir and abs_dir(make_flags.dir) ~= abs_dir(cwd) then
        mk_src = " @ " .. abs_dir(make_flags.dir)
    end
    vim.notify("✅ GenCompileDB: 已生成 " .. output .. " （" .. #entries .. " 条目，Makefile -I/-D: "
        .. #make_flags.includes .. "/" .. #make_flags.defines .. mk_src .. "）", vim.log.levels.INFO)
end

-- 定义命令 :GenCompileDB
vim.api.nvim_create_user_command("GenCompileDB", function()
    M.generate()
end, { nargs = 0 })

return M

