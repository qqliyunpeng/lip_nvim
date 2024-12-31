
# 1. LSP
clangd 需要在文件夹下生成 compile_commands.json 文件，辅助 clangd 理解代码结构
```c
compiledb make
```

# 2. Key maps

|key|功能|
|--|--|
|gf| 光标当前的关键字定义或者被引用的一个列表|
|vaq/viq|选中" ' \` 这些引号间的内容|
|vaj/vij|选中 {[( 这些符号间的内容 |
|<leader>a|切换开启和关闭 autopairs 的功能|

