local M = {}

local function format()
	local opts = { async = true, lsp_format = "fallback" }
	local mode = vim.api.nvim_get_mode().mode
	local original_lines
	local start_line
	local end_line

	if mode == "v" or mode == "V" then
		local start_pos = vim.fn.getpos("v")
		local end_pos = vim.fn.getpos(".")

		if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
			start_pos, end_pos = end_pos, start_pos
		end

		opts.range = {
			start = { start_pos[2], mode == "V" and 0 or start_pos[3] - 1 },
			["end"] = {
				end_pos[2],
				mode == "V" and #vim.api.nvim_buf_get_lines(0, end_pos[2] - 1, end_pos[2], true)[1] or end_pos[3],
			},
		}

		original_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
		start_line = start_pos[2]
		end_line = end_pos[2]
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
	end

	require("conform").format(opts, function(err)
		if err or not original_lines then
			return
		end

		local formatted_lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
		local selected_lines = vim.list_slice(formatted_lines, start_line, end_line)
		vim.api.nvim_buf_set_lines(0, 0, -1, true, original_lines)
		vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, true, selected_lines)
	end)
end

M.keys = {
	{
		"<leader>cf",
		format,
		mode = { "n", "x" },
		desc = "Format selection or buffer",
	},
}

M.opts = {
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		typescript = { "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", stop_after_first = true },
		typescriptreact = { "prettierd", "prettier", stop_after_first = true },
		json = { "prettierd", "prettier", stop_after_first = true },
		yaml = { "prettierd", "prettier", stop_after_first = true },
		markdown = { "prettierd", "prettier", stop_after_first = true },
		c = { "clang-format" },
		cpp = { "clang-format" },
	},
}

return M
