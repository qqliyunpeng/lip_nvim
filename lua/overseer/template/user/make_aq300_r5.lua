return {
    name = "05. aq300_r5",
    builder = function()
        -- 复制当前环境
        local env = vim.fn.environ()
        -- 修改或新增
        env.CROSS_COMPILE_R5 = "/home/lip/petalinux_202001/tools/xsct/gnu/armr5/lin/gcc-arm-none-eabi/bin/armr5-none-eabi-"

        return {
            cmd = { "bash" },
            args = { "lip_build.sh" },
            env = env,
        }
    end,
    condition = {
        filetype = { "c" },
    },
}

