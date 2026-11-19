-- 安装目录: ~/.local/pyright/
-- 查看当前路径: :PyrightPath
local M = {}

local home = vim.fn.expand("~")
local base_dir = home .. "/.local/pyright"
local repo_dir = base_dir .. "/repo"
local current_link = base_dir .. "/current"
local repo_url = "https://gitee.com/nvim_lip/pyright.releases.git"
local version = "1.1.414"

local running = false

local function exists(path)
    return vim.loop.fs_stat(path) ~= nil
end

local function notify(message, level)
    vim.schedule(function()
        vim.notify(message, level or vim.log.levels.INFO, { title = "Pyright Installer" })
    end)
end

local function run(command, callback)
    vim.system(command, { text = true }, function(result)
        vim.schedule(function()
            callback(result)
        end)
    end)
end

local function ensure_repo(callback)
    if exists(repo_dir .. "/.git") then
        run({ "git", "-C", repo_dir, "fetch", "--tags", "--prune" }, callback)
    else
        vim.fn.mkdir(base_dir, "p")
        run({ "git", "clone", "--branch", "main", repo_url, repo_dir }, callback)
    end
end

local function install(callback)
    local archive = repo_dir .. "/pyright-" .. version .. ".tgz"
    local version_dir = base_dir .. "/" .. version
    local package_dir = version_dir .. "/package"
    local language_server = package_dir .. "/langserver.index.js"

    if not exists(language_server) then
        if not exists(archive) then
            notify("Missing Pyright archive: " .. archive, vim.log.levels.ERROR)
            callback(nil)
            return
        end

        vim.fn.mkdir(version_dir, "p")
        run({ "tar", "-xzf", archive, "-C", version_dir }, function(result)
            if result.code ~= 0 then
                notify("Pyright extraction failed", vim.log.levels.ERROR)
                callback(nil)
                return
            end
            vim.fn.delete(current_link)
            vim.fn.system({ "ln", "-s", package_dir, current_link })
            callback(language_server)
        end)
    else
        vim.fn.delete(current_link)
        vim.fn.system({ "ln", "-s", package_dir, current_link })
        callback(language_server)
    end
end

function M.setup(on_ready)
    if running then return end
    running = true

    local current = current_link .. "/langserver.index.js"
    if exists(current) then
        on_ready(current)
        running = false
        return
    end

    notify("Updating Pyright: " .. repo_url)
    ensure_repo(function(result)
        if result.code ~= 0 then
            notify("Pyright repository update failed", vim.log.levels.ERROR)
            on_ready(nil)
            running = false
            return
        end
        install(function(path)
            on_ready(path)
            running = false
        end)
    end)
end

vim.api.nvim_create_user_command("PyrightPath", function()
    for _, client in pairs(vim.lsp.get_clients()) do
        if client.name == "pyright" then
            print(vim.inspect(client.config.cmd))
            return
        end
    end
    print("No active pyright client")
end, {})

return M
