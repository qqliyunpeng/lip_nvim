local M = {}

---生成 Gitee 仓库地址
---@param repo string
---@return string
function M.ge(repo)
    return "https://gitee.com/" .. repo
end

---生成 GitHub 仓库地址
---@param repo string
---@return string
function M.gh(repo)
    return "https://github.com/" .. repo
end

return M
