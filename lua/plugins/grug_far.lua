local ge = require("lip.utils").ge

return {
    {
        ge("nvim_lip/grug-far.nvim.git"), branch = 'main',
        cmd = "GrugFar",
        keys = {
            {
                "<leader>sr",
                function()
                    local grug = require('grug-far')
                    local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
                    grug.open({
                        transient = true,
                        prefills = {
                            search = vim.fn.expand("<cword>"),
                            flags = "--fixed-strings",
                            filesFilter = ext and ext ~= "" and "*.*\n!/cscope.out" or nil,
                        },
                    })
                end,
                mode = { "n", "v" },
                desc = "Search and Replace",
            },
        },
        config = function()
            require('grug-far').setup({
                headerMaxWidth = 80,
                folding = {
                    enabled = false,
                },
                engines = {
                    ripgrep = {
                        placeholders = {
                            search = "e.g. foo   foo(bar)   func("
                        },
                    },
                },
                keymaps = {
                    qflist = { n = '=' },
                    close = { n = 'q' },
                },
                rg = {
                    options = {
                        '--no-ignore',
                    },
                },
            })
            vim.api.nvim_set_hl(0, "GrugFarResultsPath", { link = "Directory" })
        end,
    },
}

