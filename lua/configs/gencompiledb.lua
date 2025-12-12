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
        else
            table.insert(res, ch)
            i = i + 1
        end
    end
    return table.concat(res)
end

-- 生成 compile_commands.json（扫描当前目录及子目录，不执行任何编译）
function M.generate()
    local cwd = vim.fn.getcwd()
    local output = cwd .. "/compile_commands.json"
    local compiler = "gcc"  -- 仅用于生成命令文本
    local cflags = "-Iinclude -DDEBUG -std=c11"

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
        local obj = {
            directory = cwd,
            command = string.format(
            "%s %s -c %s -o build/%s.o",
            compiler,
            cflags,
            file,
            vim.fn.fnamemodify(file, ":t:r")
            ),
            file = file,
        }
        table.insert(entries, obj)
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

