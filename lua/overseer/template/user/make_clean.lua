return {
    name = "00. make clean",
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

