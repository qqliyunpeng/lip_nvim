return {
    name = "03. aq300_pc",
    builder = function()
        -- 复制当前环境
        local env = vim.fn.environ()
        -- 修改或新增
        env.SYSROOT = "/home/lip/wor_/test/tools/sysroots/aarch64-xilinx-linux"
        env.PATH = vim.fn.getenv("PATH") .. ":/home/lip/petalinux_202001/tools/xsct/gnu/armr5/lin/gcc-arm-none-eabi/bin"
        env.LVGL_PC_SIM = "yes"
        -- 删除 CROSS_COMPILE
        env.CROSS_COMPILE = nil

        return {
            cmd = { "make" },
            args = { "-j123" },
            env = env,
        }
    end,
    condition = {
        filetype = { "c" },
    },
}

