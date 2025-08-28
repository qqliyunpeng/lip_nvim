return {
    name = "make or160 machine",
    builder = function()
        return {
            cmd = { "make" },
            args = { "-j123" },
            env = {
                SYSROOT="/home/lip/tools_cross_build/arm-himix200-linux/target",
                PATH = vim.fn.getenv("PATH") .. ":/home/lip/petalinux_202001/tools/xsct/gnu/armr5/lin/gcc-arm-none-eabi/bin",
                LVGL_PC_SIM="no",
                CROSS_COMPILE="arm-himix200-linux-",
            },
        }
    end,
    condition = {
        filetype = { "c" },
    },
}

