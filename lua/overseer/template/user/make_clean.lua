return {
    name = "make clean",
    builder = function()
        return {
            cmd = { "make" },
            args = { "clean" },
        }
    end,
    condition = {
        filetype = { "c" },
    },
}

