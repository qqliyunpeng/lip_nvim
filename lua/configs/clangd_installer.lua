-- 安装目录: ~/.local/clangd/
local M = {}

local home         = vim.fn.expand("~")
local base_dir     = home .. "/.local/clangd"
local repo_dir     = base_dir .. "/repo"
local current_link = base_dir .. "/current"
local repo_url     = "https://gitee.com/nvim_lip/clangd.releases.git"

local notify_id = nil
local running = false

local function notify(msg, level)
    level = level or vim.log.levels.INFO
    vim.schedule(function()
        notify_id = vim.notify(msg, level, { title = "Clangd Installer", replace = notify_id })
    end)
end

-- 判断路径是否存在
local function exists(path)
  return vim.loop.fs_stat(path) ~= nil
end

-- 安全 echo
local function echo(msg)
    if not msg or msg == "" then
        return
    end
    vim.schedule(function()
        vim.api.nvim_echo({ { msg, "None" } }, false, {})
    end)
end

-- 异步 system（带 stdout/stderr）
local function system(cmd, opts, on_exit)
    opts = opts or {}
    opts.text = true
    opts.stdout = function(_, data)
        if data and data ~= "" then
            echo(data:gsub("%s+$", ""))
        end
    end
    opts.stderr = function(_, data)
        if data and data ~= "" then
            echo(data:gsub("%s+$", ""))
        end
    end
    vim.system(cmd, opts, function(res)
        if on_exit then on_exit(res) end
    end)
end

-- 静默 system（用于 unzip 阶段）
local function system_silent(cmd, on_exit)
    vim.system(cmd, { text = true }, function(res)
        if on_exit then on_exit(res) end
    end)
end

-- clone 或 fetch repo
local function ensure_repo(done)
    if exists(repo_dir .. "/.git") then
        notify("Updating clangd: " .. repo_url)
        system(
            { "git", "-C", repo_dir, "fetch", "--tags", "--progress" },
            {},
            function(res)
                if res.code == 0 then done() end
            end
        )
    else
        notify("git clone " .. repo_url)
        system(
            { "git", "clone", "--progress", repo_url, repo_dir },
            {},
            function(res)
                if res.code == 0 then done() else notify("git clone failed") end
            end
        )
    end
end

-- 获取最新 tag
local function get_latest_tag(cb)
    vim.system(
        { "git", "-C", repo_dir, "tag", "--sort=-v:refname" },
        { text = true },
        function(res)
            for line in res.stdout:gmatch("[^\n]+") do
                if line:match("^V%d+%.%d+%.%d+$") then
                    cb(line)
                    return
                end
            end
            cb(nil)
        end
    )
end

-- unzip clangd
local function install_clangd(tag, done)
    local version = tag:sub(2)
    local version_dir = base_dir .. "/" .. version
    local unzip_dir = version_dir .. "/clangd_" .. version
    local clangd_bin = unzip_dir .. "/bin/clangd"

    -- 本地已经存在直接返回
    if exists(clangd_bin) then
        done(clangd_bin)
        running = false
        return
    end

    local zip = string.format("%s/clangd-linux-%s.zip", repo_dir, version)

    notify("Extracting clangd " .. version .. " …", vim.log.levels.INFO)

    system_silent(
        {
            "sh",
            "-c",
            table.concat({
                "mkdir -p " .. version_dir,
                "unzip -oq " .. zip .. " -d " .. version_dir,
                "ln -sfn " .. unzip_dir .. " " .. current_link,
            }, " && "),
        },
        function(res)
            vim.schedule(function()
                if res.code == 0 then
                    -- 解压完成，替换为完成提示
                    notify("clangd " .. version .. " ready", vim.log.levels.INFO)
                    done(clangd_bin)
                else
                    notify("clangd install failed", vim.log.levels.ERROR)
                    done("clangd")
                end
                running = false
            end)
        end
    )
end

-- 获取本地 clangd 二进制路径
local function get_clangd_bin()
    if not exists(current_link .. "/bin/clangd") then return nil end
    local target = vim.loop.fs_realpath(current_link)
    if not target then return nil end
    return target .. "/bin/clangd"
end

-- public API
function M.setup(on_ready)
    if running then return end
    running = true

    local clangd_bin = get_clangd_bin()
    if clangd_bin then
        on_ready(clangd_bin)
        running = false
        return
    end

    -- 没有 clangd 二进制，才拉取 repo 下载
    ensure_repo(function()
        get_latest_tag(function(tag)
            if not tag then
                echo("No valid clangd tag found")
                on_ready("clangd")
                running = false
                return
            end
            install_clangd(tag, on_ready)
        end)
    end)
end

vim.api.nvim_create_user_command("ClangdPath", function()
  for _, client in pairs(vim.lsp.get_active_clients()) do
    if client.name == "clangd" then
      print(client.config.cmd[1])
      return
    end
  end
  print("No active clangd client")
end, {})

return M

