return {
    name = "04. aq300_machine",
    builder = function()
        return {
            cmd = { "make" },
            args = { "-j123" },
            env = {
                SYSROOT="/home/lip/wor_/test/tools/sysroots/aarch64-xilinx-linux",
                PATH = vim.fn.getenv("PATH") .. ":/home/lip/petalinux_202001/tools/xsct/gnu/armr5/lin/gcc-arm-none-eabi/bin",
                LVGL_PC_SIM="no",
                CROSS_COMPILE="aarch64-linux-gnu-",
            },
        }
    end,
    condition = {
        filetype = { "c" },
    },
}

