# lip.nvim

一个面向 C/C++、Lua、Markdown 和日常工程编辑的个人 Neovim 配置。

这个配置不是最小化模板，而是把常用编辑动作、工程跳转、搜索替换、LSP、
AI 辅助、Markdown 写作、多光标和构建任务整理成一套开箱即用的工作环境，
并默认以 Gitee 镜像作为主要插件更新源。
## ✨ Features

<table>
<tr>
<td valign="top" width="33%">

### 🤖 AI & Assistance

-  [Avante](https://github.com/yetone/avante.nvim) - 侧边栏式 AI 编程辅助
-  [GitHub Copilot](https://github.com/features/copilot) - AI pair programmer
-  [Copilot NES](https://github.com/copilotlsp-nvim/copilot-lsp) - Next Edit Suggestions

</td>
<td valign="top" width="33%">

### 🎨 UI & Experience

-  [onedarkpro.nvim](https://github.com/olimorris/onedarkpro.nvim) - theme
-  Custom [heirline.nvim](https://github.com/rebelot/heirline.nvim) - statusline
-  [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) - 顶部 buffer 标签
-  [noice.nvim](https://github.com/folke/noice.nvim) - 命令行、消息、LSP 浮窗 UI
-  [nvim-notify](https://github.com/rcarriga/nvim-notify) - notification UI
-  [todo-comments](https://github.com/folke/todo-comments.nvim) - TODO highlighting
-  [which-key](https://github.com/folke/which-key.nvim) - keybinding helper

</td>
<td valign="top" width="33%">

### 💻 C/C++, Lua & Markdown Development

-  C/C++, Lua, Markdown and daily engineering editing
-  [blink.cmp](https://github.com/Saghen/blink.cmp) - completion engine
-  [LuaSnip](https://github.com/L3MON4D3/LuaSnip) - snippet engine
-  [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - 语法高亮、文本对象和移动
-  [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) - 顶部显示当前函数/作用域上下文
-  [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) - Markdown 渲染增强
-  [vim-table-mode](https://github.com/dhruvasagar/vim-table-mode) - Markdown 表格自动格式化

</td>
</tr>
<tr>
<td valign="top" width="33%">

### 🛠️ DevOps & Tools

-  [Snacks.nvim](https://github.com/folke/snacks.nvim) - files, buffers, grep, notifications, scratch, terminal, Lazygit
-  [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - 补充 picker 和 yank history 集成
-  [flash.nvim](https://github.com/folke/flash.nvim) - 屏幕内快速跳转
-  [project.nvim](https://github.com/ahmedkhalf/project.nvim) - 工程根目录识别和切换
-  [harpoon](https://github.com/ThePrimeagen/harpoon) - quick file navigation
-  [navimark.nvim](https://github.com/ZWindLOR/navimark.nvim) - 持久化 bookmark
-  [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) - tree-style file explorer
-  [mini.files](https://github.com/echasnovski/mini.files) - lightweight file manager
-  [vim-visual-multi](https://github.com/mg979/vim-visual-multi) - multi-cursor editing

</td>
<td valign="top" width="33%">

### 🧹 Code Quality

-  Native LSP via [mason.nvim](https://github.com/williamboman/mason.nvim)
-  [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) - Mason and lspconfig integration
-  [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - native LSP client configuration
-  [lspsaga.nvim](https://github.com/nvimdev/lspsaga.nvim) - LSP 浮窗、签名、上下文 UI
-  [grug-far](https://github.com/MagicDuck/grug-far.nvim) - search & replace
-  [vim-illuminate](https://github.com/RRethy/vim-illuminate) - 当前符号引用高亮
-  [neogen](https://github.com/danymat/neogen) - Doxygen 风格注释生成
-  [ts-comments.nvim](https://github.com/folke/ts-comments.nvim) - Treesitter-aware comments

</td>
<td valign="top" width="33%">

### 🔀 Git Integration

-  [Lazygit](https://github.com/jesseduffield/lazygit) terminal UI
-  [gitsigns](https://github.com/lewis6991/gitsigns.nvim) - 行级变更标记和 hunk 跳转

</td>
</tr>
</table>

### ✏️ Editing Features

lip.nvim ships with editing helpers for daily C/C++, Lua and Markdown work:

| Feature | Plugin | Description |
|---------|--------|-------------|
|  **Delimiters** | [rainbow-delimiters.nvim](https://github.com/HiPhish/rainbow-delimiters.nvim) | 彩色括号层级 |
|  **Text objects** | [mini.ai](https://github.com/echasnovski/mini.ai) | 扩展 text object |
|  **Alignment** | [mini.align](https://github.com/echasnovski/mini.align) | 对齐文本块 |
|  **Surround** | [mini.surround](https://github.com/echasnovski/mini.surround) | Surround 操作 |
|  **Move selection** | [mini.move](https://github.com/echasnovski/mini.move) | 移动 visual 选区 |
|  **Operators** | [mini.operators](https://github.com/echasnovski/mini.operators) | 自定义 operator，包含表达式计算 |
|  **Autopairs** | [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | 自动补全括号和引号 |
|  **Word toggles** | [nvim-toggler](https://github.com/nguyenvukhang/nvim-toggler) | `true/false`、`on/off` 等词义切换 |
|  **Yank history** | [yanky.nvim](https://github.com/gbprod/yanky.nvim) | Yank 历史、智能粘贴和寄存器管理 |
|  **Tasks** | [overseer.nvim](https://github.com/stevearc/overseer.nvim) | Build, run, make task templates |
|  **Sessions** | [persisted.nvim](https://github.com/olimorris/persisted.nvim) | 工作区 session 保存和恢复 |

### ⚡ Performance

- **Lazy loaded**: All plugins via [lazy.nvim](https://github.com/folke/lazy.nvim)

## Requirements

- Neovim `0.11+`
- `git`
- `ripgrep`
- `fd`
- `make`
- `gcc` / `clang`
- `node` / `npm`
- `python3`
- Nerd Font

部分插件或语言工具可能还需要 `cargo`、`sqlite3`、`libsqlite3-dev`、`unzip`、`curl`。
进入 Neovim 后可用 `:checkhealth` 检查缺失项。

## Installation

备份原配置后克隆到 `~/.config/nvim`：

```bash
mv ~/.config/nvim ~/.config/nvim.bak
git clone https://github.com/qqliyunpeng/lip_nvim.git ~/.config/nvim
nvim
```

首次启动会自动 bootstrap `lazy.nvim`，并从配置中的镜像源拉取插件。

如果当前网络环境不能直接访问 GitHub，配置默认倾向使用 Gitee 镜像源。
`clangd` 也默认走自定义下载逻辑。

## Environment

| 变量 | 默认 | 作用 |
|------|------|------|
| `CLANGD_USE_GITHUB=1` | 关闭 | 使用 GitHub 官方 clangd 下载源 |
| `COPILOT_AUTO_TRIGGER=1` | 关闭 | 开启 Copilot 自动补全触发 |

示例：
在 ~/.bashrc 中 export
```bash
export COPILOT_AUTO_TRIGGER=1
bash ~/.bashrc
```


## Project Layout

```text
.
├── init.lua
├── lua
│   ├── configs
│   ├── overseer
│   ├── plugins
│   ├── mappings.lua
│   └── options.lua
└── snippets
```

| 路径 | 说明 |
|------|------|
| `init.lua` | 入口、leader、lazy bootstrap、全局高亮和命令 |
| `lua/mappings.lua` | 全局快捷键 |
| `lua/options.lua` | Neovim 基础选项 |
| `lua/plugins/` | 插件声明 |
| `lua/configs/` | 插件配置和本地工具函数 |
| `lua/overseer/` | 任务模板 |
| `snippets/` | LuaSnip 片段 |

## Quick Start

### C/C++ LSP

`clangd` 需要项目里有 `compile_commands.json`，否则代码理解会明显下降。

Makefile 项目可用：

```bash
compiledb make
```

CMake 项目可用：

```bash
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
```

### Root Detection

使用 `:Root` 切到当前工程根目录。根目录标记包括：

```text
.git
_darcs
.hg
.bzr
.svn
Makefile
package.json
```

### Generate Comments

```vim
:Neogen
```

### Window Placement

把当前窗口移动到指定方向：

```vim
<c-w> H
<c-w> J
<c-w> K
<c-w> L
```

### Clear Swap Files

```bash
rm ~/.local/state/nvim/swap/*
```

## Keybindings

`,` 是 leader key。

按 `<leader>?` 可以打开 which-key，查看当前 buffer 可用快捷键。

### General

| Key | Mode | Action |
|-----|------|--------|
| `Space` | n | 进入命令行 |
| `jk` / `kj` | i | 退出插入模式 |
| `<leader>q` | n | 关闭当前窗口 |
| `<leader>x` | n | 退出所有窗口 |
| `<C-s>` | n/i | 保存当前文件 |
| `<Esc>` | n | 清除搜索高亮 |
| `<A-q>` | n/x/c | 退出当前交互或清除高亮 |

### Movement & Windows

| Key                | Mode  | Action                              |
|--------------------|-------|-------------------------------------|
| `<C-h/j/k/l>`      | t     | 从终端切到相邻窗口                  |
| `H`                | n/x/o | 跳到行首非空字符                    |
| `L`                | n/x/o | 跳到行尾非空字符                    |
| `J` / `K`          | n/x/o | 向下/向上移动 5 行                  |
| `<C-h/j/k/l>`      | n     | 在窗口间移动                        |
| `<C-h/j/k/l>`      | i     | 插入模式移动光标                    |
| `<BS>`             | n     | SSH 终端里替代 `<C-h>` 切到左侧窗口 |
| `<C-S-Up/Down>`    | n     | 调整水平分屏高度                    |
| `<C-S-Left/Right>` | n     | 调整垂直分屏宽度                    |

### Files, Buffers & Pickers

| Key | Mode | Action |
|-----|------|--------|
| `<leader>p` | n | 查找文件 |
| `<leader>r` | n | 最近文件 |
| `<leader>ff` | n | 查找文件 |
| `<leader>fa` | n | 查找隐藏和 ignored 文件 |
| `<leader><Tab>` | n | buffer 列表 |
| `<leader>fw` | n | live grep |
| `<leader>fc` | n/x | 搜索当前词或视觉选择内容 |
| `<leader>fl` | n | 当前 buffer 行搜索 |
| `<leader>fz` | n | 当前 buffer 内 fuzzy find |
| `<leader>fu` | n | undo 历史 |
| `<leader>fh` | n | help tags |
| `<leader>fM` | n | man pages |
| `[b` / `]b` | n | 上一个/下一个 buffer |
| <code>&lt;leader&gt;`</code> / <code>&lt;A-`&gt;</code> | n | 切回上一个 buffer |
| `<leader>bd` | n | 删除当前 buffer |
| `<leader>bo` | n | 删除其它 buffer |
| `<F2>` | n | 打开/关闭 nvim-tree |

<details>
<summary><strong>各个插件的快捷键介绍</strong></summary>

### Search & Replace

| Key | Mode | Action |
|-----|------|--------|
| `<A-/>` | n/x | 搜索当前词或视觉选择内容 |
| `<leader>fc` | n/x | picker 搜索当前词或视觉选择内容 |
| `<leader>sr` | n/v | 打开 grug-far 查找替换 |
| `m` | n/x/o | Flash jump |
| `gl` | n/x/o | Flash 行首跳转 |
| `]]` / `[[` | n/t | 下一个/上一个引用 |

搜索当前光标下单词时：

- 默认不是全词匹配。
- 需要全词匹配时，可在搜索参数里把 `-F` 改成 `-w`。

### LSP

| Key | Mode | Action |
|-----|------|--------|
| `gd` | n | 跳到定义 |
| `gD` | n | 跳到声明 |
| `gr` | n | 查找引用 |
| `gf` | n | 当前关键字定义或引用列表 |
| `<leader>sh` | n | signature help |
| `<A-f>` | i | 插入模式查看函数参数 |
| `<leader>wa` | n | 添加 workspace folder |
| `<leader>wr` | n | 移除 workspace folder |
| `<leader>wl` | n | 列出 workspace folders |
| `<leader>ca` | n/v | code action |

### Git

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gg` | n | Lazygit |
| `<leader>gt` | n | Git status |
| `<leader>gc` | n | Git commits |
| `<leader>gb` | n | 当前行 blame |
| `<leader>gl` | n | 当前文件 Git log |
| `<leader>gL` | n | Git log |
| `]g` | n | 下一个 git change |
| `[g` | n | 上一个 git change |

### Harpoon & Marks

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ha` | n | 当前文件加入 Harpoon |
| `<leader>fe` | n | 打开 Harpoon 菜单 |
| `<A-1>` 到 `<A-5>` | n | 跳到 Harpoon 第 1 到第 5 个文件 |
| `<C-S-P>` / `<C-S-N>` | n | Harpoon 上一个/下一个 |
| `<leader>mc` | n | 删除 bookmark |
| `<leader>fm` | n | 打开 bookmark picker |

### Clipboard & Paste

| Key | Mode | Action |
|-----|------|--------|
| `p` / `P` | n | 智能粘贴 |
| `p` / `P` | x | 替换选择区但不污染默认寄存器 |
| `"0p` | n | 粘贴 yank 的内容，不受 delete 影响 |
| `<leader>y` | n | 打开 yank 历史 picker |
| `<C-x>` | yank picker insert | 删除一条 yank 记录 |
| `<C-r>` | yank picker insert | 设置当前 yank 到默认寄存器 |

普通模式下 `c`、`d`、`x` 默认不复制到剪贴板，避免删除动作覆盖 yank 内容。

### Text Objects

| Key           | Mode  | Action                  |
|---------------|-------|-------------------------|
| `vaq` / `viq` | n/o/x | 选择引号内容            |
| `vaj` / `vij` | n/o/x | 选择 `{[(` 等括号内容   |
| `var` / `vir` | n/o/x | 选择同缩进段落          |
| `vau` / `viu` | n/o/x | 选择到 `, . : ; ! ?`    |
| `vac` / `vic` | n/o/x | 选择 光标后边的 commits |
| `vai` / `vii` | n/o/x | 选择光标后的缩进块(indent-blankline)      |

### Comments

| Key | Mode | Action |
|-----|------|--------|
| `<leader>cc` | n/v | 切换注释 |
| `gco` | n | 在下方新增注释行 |
| `gcO` | n | 在上方新增注释行 |

### Terminal & Scratch

| Key | Mode | Action |
|-----|------|--------|
| `<A-b>` | n | 打开终端 |
| `<A-b>` | t | 隐藏终端 |
| `<leader>.` | n | 打开 scratch |
| `<leader>S` | n | 选择 scratch |

### Markdown & Todo

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ut` | n | 开关 table mode |
| `<leader>tr` | n | Markdown 表格整理 |
| `<leader>to` | n | 查找 TODO/NOTE/FIX/FIXME |
| `]t` / `[t` | n | 下一个/上一个 TODO/NOTE/FIX/FIXME |

### Toggles

| Key          | Mode | Action                      |
|--------------|------|-----------------------------|
| `<leader>ui` | n/v  | `True <-> False` 等词义切换 |
| `<leader>ua` | n    | 开关 autopairs              |
| `<leader>un` | n    | 关闭所有通知                |
| `<leader>us` | n    | 开关 spell                  |
| `<leader>uw` | n    | 开关 wrap                   |
| `<leader>uL` | n    | 开关 relativenumber         |
| `<leader>ud` | n    | 开关 diagnostics            |
| `<leader>ul` | n    | 开关 line number            |
| `<leader>uh` | n    | 开关 inlay hints            |

### Visual Multi

#### Basic Keys

| Key |jAction |
|-----|--------|
| `<C-n>` | 选择当前词，并继续选择下一个相同词 |
| `<C-Up>` / `<C-Down>` | 在上/下方创建光标 |
| `\\\` | 创建多光标后用方向键移动 |
| `<C-j>` / `<C-k>` | 在 `\\\` 后向下/向上扩展光标 |
| `<C-c>` / `<A-q>` | 退出 VM mode |

#### Pattern

- `\\w` 切换 whole word search。
- `\\c` 在 case sensitive、ignorecase、smartcase 间切换。

#### Select In Scope

1. 视觉模式选中内容。
2. 按 `<C-n>` 进入 multi mode。
3. 使用 `mii`、`mai`、`maq`、`maj` 等选择范围。
4. `8mj` 表示向下 8 行内查找相同选择。
5. 如果没有提前选择内容，先用 `\\\` 或 `<C-Down>` 创建选择，再用 `sii`、`sai`、`saq`、`saj`。

#### Work With `<C-n>`

1. `<C-n>` 选择当前光标所在词。
2. `<C-n>` / `n` / `N` 跳到下一个或上一个相同词。
3. `q` 取消当前跳转到的选择。
4. 重复选择和取消。
5. 用 `<A-[>` / `<A-]>` 在已选择项之间移动。

#### Align

1. 用 `<C-Down>` 创建多个光标。
2. 用 `w` / `e` 向后移动到需要对齐的位置。
3. `\\a` 对齐。

#### Numbering

1. 用 `<C-Down>` 创建多个光标。
2. `\\N` 打开编号窗口：`begin number`、`step`、`same text`。
3. `\\N` 在光标前插入编号，`\\n` 在光标后追加编号。

#### Join Alternating Lines

原始内容：

```text
123
145
156
178
```

目标：

```text
123 145
156 178
```

步骤：

1. 用 `<C-Down>` 选择每行开头。
2. 用 `\\R` 隔一行选择。
3. 按 `J` 合并。

#### Increment Numbers

把多行数字：

```text
1
1
1
```

变成：

```text
1
2
3
```

选中第二、三行的 `1`，按 `g<C-a>`。`<C-a>` 是增加数字，加 `g` 表示按序递增。
对应的减少操作是 `<C-x>`。

### Mini.nvim

#### mini.files

| Key | Action |
|-----|--------|
| `L` | go_in_plus |
| `H` | go_out_plus |
| `@` | reveal_cwd |
| `<BS>` | reset |
| `<` | 将当前窗口移动到最左侧 |
| `>` | 将窗口向右移动 |

#### mini.move

只在 visual 模式下生效。

| Key | Action |
|-----|--------|
| `<A-j>` | 选中块向下移动 |
| `<A-k>` | 选中块向上移动 |
| `<A-h>` | 选中块向左移动 |
| `<A-l>` | 选中块向右移动 |

#### mini.align

选中要操作的块后：

| Key                        | Action                             |
|----------------------------|------------------------------------|
| `ga`                       | 开始对齐                           |
| `gA`                       | 带预览开始对齐                     |
| `j`                        | 进入模式后选择对齐方式，默认左对齐 |
| `,` / `=` / `\|` / `space` | 常用分隔符                         |

### Calculator

选中表达式后按 `gz=` 可直接计算。

示例：

```c
#define OPE() (0x123f + 1)
```

</details>

## Known Issues

- persisted session 的 workspace select UI 里，`<C-c>` 可能不会关闭窗口，而是复制 session，需要手动关闭。
- CRLF 类型的大文件打开时可能因为 treesitter 加载变慢。例如 5000 行 `.c` 文件启动可能需要数秒。

## Notes

- README 里的快捷键只记录高频入口；完整映射以 `lua/mappings.lua` 和 `lua/plugins/` 为准。

