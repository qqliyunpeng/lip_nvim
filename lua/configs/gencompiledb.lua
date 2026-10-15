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

-- 生成 compile_commands.json（扫描当前目录及子目录，不执行任何编译）
function M.generate()
    local cwd = vim.fn.getcwd()
    local output = cwd .. "/compile_commands.json"

    -- ---- 可调整的编译参数 ----------------------------------------------
    local defines = {}              -- 宏定义，如 { "-DDEBUG" }（默认不添加）
    -- 额外头文件目录（相对项目根目录，不存在会被自动跳过）
    local extra_includes = { "include" }
    -- --------------------------------------------------------------------

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

    vim.notify("✅ GenCompileDB: 已生成 " .. output .. " （" .. #entries .. " 条目）", vim.log.levels.INFO)
end

-- 定义命令 :GenCompileDB
vim.api.nvim_create_user_command("GenCompileDB", function()
    M.generate()
end, { nargs = 0 })

return M

