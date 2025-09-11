
# 0. 正在使用的nvim版本
```sh
NVIM v0.10.4
Build type: Release
LuaJIT 2.1.1713484068
Run "nvim -V1 -v" for more info
```

# 1. LSP
clangd 需要在文件夹下生成 compile_commands.json 文件，辅助 clangd 理解代码结构
```c
compiledb make
```

```c++
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
```

# 2. Key maps

| key          | 模式 | 功能                                             |
|--------------|------|--------------------------------------------------|
| gf           | n    | 光标当前的关键字定义或者被引用的一个列表         |
| vaq/viq      | n    | 选中" ' \` 这些引号间的内容                      |
| vaj/vij      | n    | 选中 {[( 这些符号间的内容                        |
| var/vir      | n    | 选中 相同的缩进认为的段落，空格和不同的缩进结束  |
| vau/viu      | n    | 选中 to , . : ; ! ?                              |
| <leader>ua   | n    | 切换开启和关闭 autopairs 的功能                  |
| alt-h        | n    | 简短的hover形式的说明                            |
| alt-l        | n    | 打开一个小窗口，相当于进入了一个中，并显示上下文 |
| alt-f        | i    | 在插入模式下打开函数的帮助信息一下               |
| ctrl-h/j/k/l | n    | 在窗口间移动                                     |
| ctrl-h/j/k/l | i    | 相当于在不退出插入模式的情况下上下左右           |
| <leader>tm   | n    | 开启/关闭markdown里边的表格的自动化              |
| <leader>tr   | n    | markdown里边的表格的自动化                       |
| <leader>mm   | n    | create/del a bookmark                            |
| <leader>mc   | n    | del a bookmark                                   |
| <leader>fm   | n    | open telescope  show all bookmark                |
| <leader>sr   | n    | grug-far 查找替换                                |
| <leader>to   | n    | todo telescope find all                          |
| <leader>p    | n    | yank telescope picker                            |
| C-p          | i    | yank telescope picker                            |
| <leader>ui   | n    | True <-> False 交替变化                          |
| ]g           | n    | next git changs                                  |
| [g           | n    | prev git changs                                  |
| <leader>fe   | n    | 打开 harpoon 的界面，里边显示所有索引了的文件    |
| <leader>a    | n    | 当前文件加入到 harpoon 列表中                    |
| <leader>.    | n    | 打开 scratch                                     |
| <leader>S    | n    | 打开不同工作区的 scratch                         |

| cmd     | 功能                                                                |
|---------|---------------------------------------------------------------------|
| Root    | cd 到当前文件的根目录下，依据目录下是不是有                         |
|         | ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" |
| Neogen  | 生成doxgen类型的函数注释                                            |
| message | 显示右上角显示过的message信息                                       |

# 3. mul line control

| cmd         | 功能                                                     |
|-------------|----------------------------------------------------------|
| C-n         | the word select and you can select next same word        |
| C-up/down   | create cursor in up and down                             |
| `\\\`       | three \ is to create a cursor and use up/down/left/right |
|             | to move to cursor and tree \ to select the other         |
| C-c / alt-q | cancle VM mode                                           |

## 3.1 pattern
- \\w toggles whole word search
- \\c cycle case setting(case sensitive -> ignorecase -> smartcase)

## 3.2 select you want in scope
- 1 in visual mode, select some
- 2 and C-n to enter mul-mode
- 3 mii / mai / maq / maj / ...
- 4 8mj is to 8 line below search the same selected word
- 5 if you don't select some, you use `\\\` or C-down select some, you need use
    sii / sai /saq / saj / ...

## 3.3 C-n how to use
- 1 C-n select the word of current cursor
- 2 `C-n`/`n`/`N` goto next/next/prev select word the same of follow
- 3 q disseselect the current of jumped word
- 4 retry 2 and 3
- 5 use `alt-[`/`alt-]` goto previous/next the selected word

## 3.4 alian
- 1 C-down select some
- 2 w/e to need alian pos
- 3 `\\a` will alian

## 3.5 numbering
- 1 C-down select some
- 2 `\\N` will have a window `begin number\step(can native)\same some text`
- 3 '\\N' is before the cursor/regin, `\\n` to append the numbers

## 3.6 some line to one line
| origin | to dest |
|--------|---------|
| 123    | 123 145 |
| 145    | 156 178 |
| 156    |         |
| 178    |         |
- 1 C-down to select begin of all
- 2 `\\R` 隔一行选择
- 3 J

## 3.6 多行数字递增
```c
1
1
1

希望变成
1
2
3
```
选中第二三行的 1 , g<c-a>, <c-a> 表示的是增加数字，添加g表示递增的加，对应的<a-x> 是减

# 4. search
- 非全词匹配(default):
<leader>fc 后出现   "光标下的词" -F
- 全词匹配:
<leader>fc 后出现   "光标下的词" -F 后更改 -F 为 -w
- 搜索当前光标下的单词
Alt-/

> [!Bug]
1. telescope persisted open the workspace select ui, C-c don't close the window,
    but to copy a session. we need to close.

# 5. 生成注释
: neogen

# 5. copy-paste
## 原生按键
| 按键 | 行为                                |
|------|-------------------------------------|
| p    | 粘贴 y 和 d 复制和剪切的内容        |
| "0p  | 粘贴 y 复制的内容，d 相关的内容不算 |

## yanky 组件使用 <leader>y 调出 picker
| 按键 | 行为                         |
|------|------------------------------|
| c-x  | 在 insert 模式下删除一行记录 |
| c-r  | 将当前行复制到寄存器 0 和 "  |

# 6. 自动计算
```c
#define OPE() (0x123f + 1)
```
当选中里边的内容后，gz= 直接算出结果

# 7. 删除swap文件
```bash
rm ~/.local/state/nvim/swap/*
```

# 8. mini.nvim
## 8.1 mini.files
| 按键 | 功能                   |
| --   | --                     |
| L    | go_in_plus             |
| H    | go_out_plus            |
| @    | reveal_cwd             |
| <bs> | reset                  |
| <    | 将当前窗口移动到最左侧 |
| >    | 窗口向右移动           |

## 8.2 mini.move
只在选中的 visual 模式下生效
| 按键  | 功能             |
|-------|------------------|
| <a-j> | 选中的块向下移动 |
| <a-k> | 选中的块向上移动 |
| <a-h> | 选中的块向左移动 |
| <a-l> | 选中的块向右移动 |

## 8.3 mini.align
选中要进行操作的块
| 按键      | 功能                                            |
|-----------|-------------------------------------------------|
| ga        | 开始                                            |
| gA        | 带预览的开始                                    |
| j         | 进入模式后，按j后可以选择对齐方式，默认是左对齐 |
| ,='\|'' ' | 以这些字符进行对齐                              |

# 9. 显示函数的参数的说明
在输入的时候弹出小括号后，输入参数的时候，想要看第一个参数需要填什么，
在插入模式下<a-f>

