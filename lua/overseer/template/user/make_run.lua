return {
    name = "make run",
    builder = function()
        return {
            cmd = { "make" },
            args = { "run" },
        }
    end,
    condition = {
        filetype = { "c" },
    },
}

