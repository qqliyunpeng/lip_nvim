-- ~/.config/nvim/lua/clangd_installer.lua
local M = {}

local home = vim.fn.expand("~")
local base_dir = home .. "/.local/clangd"
local tmp_dir = base_dir .. "/.tmp_clangd_repo"
local current_link = base_dir .. "/current"

local git_repo = "https://gitee.com/nvim_lip/clangd.releases.git"

local function exists(path)
  return vim.loop.fs_stat(path) ~= nil
end

local function run(cmd)
  vim.notify("Running: " .. cmd, vim.log.levels.INFO)
  local ok = os.execute(cmd)
  return ok == 0
end

-- 获取最新 tag（格式 Vxx.xx.xx）
local function get_latest_tag()
  if not exists(tmp_dir) then
    if not run("git clone " .. git_repo .. " " .. tmp_dir) then
      vim.notify("Failed to clone repository", vim.log.levels.ERROR)
      return nil
    end
  else
    run("git -C " .. tmp_dir .. " fetch --tags")
  end

  local handle = io.popen("git -C " .. tmp_dir .. " tag --sort=-v:refname")
  if not handle then return nil end

  local tags = {}
  for line in handle:lines() do
    if line:match("^V[%d%.]+$") then
      table.insert(tags, line)
    end
  end
  handle:close()
  return tags[1]
end

-- 安装 clangd
local function install_custom_clangd_async(tag, on_done)
    local version = tag:sub(2)
    local version_dir = base_dir .. "/" .. version
    local clangd_bin = version_dir .. "/bin/clangd"

    if exists(clangd_bin) then
        if on_done then on_done(clangd_bin) end
        return
    end

    vim.notify("Installing clangd " .. version .. " asynchronously...", vim.log.levels.WARN)
    local zip_file = string.format("%s/clangd-linux-%s.zip", tmp_dir, version)
    local cmds = {
        "mkdir -p " .. version_dir,
        "unzip -o " .. zip_file .. " -d " .. version_dir,
        "ln -sfn " .. version_dir .. " " .. current_link
    }

    async_run(cmds, function()
        if on_done then on_done(clangd_bin) end
        vim.notify("clangd " .. version .. " installed!", vim.log.levels.INFO)
    end)
end-- 主函数：确保 clangd 可用

function M.ensure_clangd()
  local clangd_bin = current_link .. "/bin/clangd"
  if exists(clangd_bin) then
    return clangd_bin
  end

  local latest_tag = get_latest_tag()
  if not latest_tag then
    vim.notify("Failed to get latest tag from repo", vim.log.levels.ERROR)
    return nil
  end

  return install_custom_clangd(latest_tag)
end

-- mason 管理 clangd
local function get_mason_clangd()
    local ok, mason_registry = pcall(require, "mason-registry")
    if not ok then
        vim.notify("mason-registry not found, fallback to system clangd.", vim.log.levels.WARN)
        return "clangd"
    end

    local clangd_pkg = mason_registry.get_package("clangd")
    if not clangd_pkg:is_installed() then
        vim.notify("Installing clangd via mason...", vim.log.levels.INFO)
        clangd_pkg:install()
    end
    return clangd_pkg:get_install_path() .. "/bin/clangd"
end

-- 对外接口：根据开关返回 clangd 路径
function M.get_clangd_path(use_custom)
    if use_custom then
        local clangd_bin = current_link .. "/bin/clangd"
        if exists(clangd_bin) then
            return clangd_bin
        end

        local latest_tag = get_latest_tag()
        if not latest_tag then
            vim.notify("Failed to get latest tag, fallback to system clangd.", vim.log.levels.WARN)
            return "clangd"
        end

        return install_custom_clangd(latest_tag)
    else
        return get_mason_clangd()
    end
end

return M

