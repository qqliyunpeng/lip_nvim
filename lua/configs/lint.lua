local M = {}

local function available_linters(names)
    local lint = require("lint")
    local result = {}

    for _, name in ipairs(names) do
        local linter = lint.linters[name]
        local cmd = linter and linter.cmd

        if type(cmd) == "function" or (type(cmd) == "string" and vim.fn.executable(cmd) == 1) then
            table.insert(result, name)
        end
    end

    return result
end

local function try_lint()
    if vim.bo.buftype ~= "" then
        return
    end

    require("lint").try_lint()
end

function M.setup()
    local lint = require("lint")

    -- 忽略可缩小变量作用域的提示
    table.insert(lint.linters.cppcheck.args, "--suppress=variableScope")
    -- 将条件编译配置检查上限从 12 提高到 40
    table.insert(lint.linters.cppcheck.args, "--max-configs=40")

    lint.linters_by_ft = {
        lua = available_linters({ "luacheck" }),
        python = available_linters({ "ruff" }),
        c = available_linters({ "cppcheck" }),
        cpp = available_linters({ "cppcheck" }),
        sh = available_linters({ "shellcheck" }),
        bash = available_linters({ "shellcheck" }),
        zsh = available_linters({ "shellcheck" }),
        markdown = available_linters({ "markdownlint" }),
        yaml = available_linters({ "yamllint" }),
        javascript = available_linters({ "eslint_d" }),
        typescript = available_linters({ "eslint_d" }),
    }

    local group = vim.api.nvim_create_augroup("lip_nvim_lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = group,
        callback = try_lint,
    })

    vim.schedule(try_lint)

    vim.api.nvim_create_user_command("Lint", try_lint, {
        desc = "Run nvim-lint for current buffer",
    })
end

return M

