#import "/template/template.typ": *

=== 为什么要先谈环境

新队员的第一周通常消耗在同一批问题上：装不上 ROS、编译报缺库、`source` 之后另一个项目又跑不起来、终端里中文变成方块。这些问题单个都不难，但它们出现在最没有排错能力的时刻，并且每一届都会重来一次。

统一环境的意义不在于「大家用一样的东西比较整齐」，而在于三件具体的事。

第一，把「在我机器上能跑」变成可讨论的问题。当两个人的 Ubuntu 版本、ROS 版本、编译器版本一致时，一方复现不了另一方的故障，说明差异在代码或硬件，排查范围立刻缩小。版本各不相同时，任何故障都要先排除环境，成本成倍增加。

第二，让文档有效期变长。写死「Ubuntu 24.04 + ROS 2 Jazzy」的安装文档可以直接照抄；写「根据你的系统版本选择对应的 ROS 发行版」的文档，读者要先做一次自己做不了的判断。

第三，减少交接损耗。学生战队的成员每年更替一批，环境配置属于纯消耗性知识——它不产生任何比赛成绩，但每个人都必须付出。把它固化成一份可执行的清单，是回报率最高的工程投入之一。

需要说明范围：本节记录的是一台开发机上实际在用的配置，不是「唯一正确答案」。工具选择有个人偏好成分，团队内真正需要强制统一的只有系统版本、ROS 版本和编译工具链；终端、Shell 和编辑器可以各用各的。哪些必须统一、哪些可以自由，本节会逐项说明。

=== 基线：必须统一的部分

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    stroke: (x, y) => (
      top: if y == 0 or y == 1 { 1pt } else { 0pt },
      bottom: if y == 6 { 1pt } else { 0pt },
    ),
    inset: 5pt,
    table.header([*组件*], [*版本*], [*为什么锁这个版本*]),
    [Ubuntu], [24.04 LTS], [ROS 2 Jazzy 的官方目标平台；LTS 支持到 2029 年，覆盖多个赛季],
    [ROS 2], [Jazzy Jalisco], [与 24.04 一一对应，官方二进制包直接可用],
    [GCC], [13.x（24.04 默认）], [随系统，不单独升级；升级编译器会引入与 ROS 二进制包的 ABI 风险],
    [CMake], [3.28.3（24.04 默认）], [满足 ROS 2 与主流依赖要求],
    [Python], [3.12（24.04 默认）], [ROS 2 Jazzy 绑定的版本，不要用 conda 覆盖],
  ),
  caption: [团队必须统一的环境基线],
)

这五项属于「不商量」的部分。原因是它们彼此耦合：ROS 2 的发行版与 Ubuntu 版本、Python 版本是绑定的，任何一项偏离都会把二进制包变成源码编译，而源码编译 ROS 2 对新队员是一道不必要的关卡。

其余部分——终端模拟器、Shell、编辑器、输入法——不影响编译产物，可以自由选择。下文给出的是一套用了一个赛季、没出过问题的组合，可以整套照抄，也可以只取其中几件。

#note[
双系统还是虚拟机？建议双系统。视觉开发要接工业相机（USB3 带宽）、要用 GPU 跑推理、要串口连电控，这三件事在虚拟机里都会遇到额外问题。WSL2 可以用来写代码和看文档，但不要作为唯一环境——它的 USB 直通和实时性都不适合调车。
]

=== 终端：ghostty

终端是一天里打开时间最长的窗口，值得花二十分钟配好。这里用的是 ghostty 1.3.1，选它的原因是 GPU 渲染带来的滚动流畅度，以及配置文件足够简单。

配置文件路径固定为 `~/.config/ghostty/config`，注意#strong[没有扩展名]。这是一个实际踩过的坑：写成 `config.ghostty` 或 `config.toml` 都不会被加载，而且 ghostty 不会报错，只是静默使用默认配置。

```ini
# ~/.config/ghostty/config

# 配色
theme = Kanagawa Wave

# 字体：Maple Mono NF CN
#   - 中文严格 2:1 等宽，表格和 ASCII 图不会错位
#   - 自带 Nerd Font 图标，Shell 主题的图标不会变方块
#   - 支持连字（->、!= 等）
font-family = Maple Mono NF CN
font-size = 12
font-feature = calt
font-feature = liga

# 窗口
window-padding-x = 14
window-padding-y = 12
background-opacity = 0.93

# 光标：实心块，不闪（减少视觉噪音）
cursor-style = block
cursor-style-blink = false
mouse-hide-while-typing = true

# 行为
copy-on-select = clipboard
# 回滚缓冲区，单位是字节不是行（默认 10000000 即 10 MB）
scrollback-limit = 100000000
confirm-close-surface = false
```

字体值得单独说明。终端字体的选择标准和编辑器不同：终端里会大量出现「中文说明 + ASCII 表格 + 命令输出对齐」的混排，如果中文宽度不是英文的严格两倍，`ros2 topic list` 的输出、`htop` 的界面、以及任何带框线的中文表格都会错位。Maple Mono NF CN 与霞鹜文楷等宽都满足这个约束，安装方式：

```bash
# Maple Mono NF CN：从 GitHub Releases 下载后解压到用户字体目录
mkdir -p ~/.local/share/fonts
# 解压得到的 .ttf 放进上面这个目录后刷新缓存
fc-cache -fv

# 霞鹜文楷（apt 源里有，用于文档正文的楷体风格）
sudo apt install fonts-lxgw-wenkai
```

#attention[
`scrollback-limit` 的单位是字节而非行数，这一点在文档里容易看漏。调车时经常要回翻几千行日志，把它调大是有用的；但设成 100 MB 意味着终端可能占用这么多内存，内存紧张的车载计算单元上不要照抄这个值。
]

=== Shell：zsh 与 Zim

Ubuntu 默认是 bash。换 zsh 的实际收益集中在两点：路径补全更聪明（`cd /u/s/b` 可补全为 `/usr/share/bin`），以及生态里有成熟的补全与语法高亮插件。

框架选 Zim 而不是更知名的 Oh My Zsh，原因是启动速度。Oh My Zsh 默认加载大量模块，在配置较多时 shell 启动会有可感知的延迟；Zim 采用静态编译初始化脚本的方式，模块按需声明。日常要开几十个终端标签页时，这个差异是能察觉的。

安装与配置：

```bash
sudo apt install zsh
chsh -s $(which zsh)   # 注销后生效

# 安装 Zim（首次启动 zsh 时也会自动下载）
curl -fsSL https://raw.githubusercontent.com/zimfw/zimfw/master/scripts/install.zsh | zsh
```

模块声明写在 `~/.zimrc`，一行一个：

```zsh
# ~/.zimrc
zmodule environment          # 基础环境变量
zmodule git                  # git 别名
zmodule input                # 输入行为改进
zmodule termtitle            # 终端标题随目录变化
zmodule utility              # 常用工具别名
zmodule duration-info        # 显示上条命令耗时
zmodule git-info             # 提示符里的 git 状态
zmodule asciiship            # 提示符主题（无需 Nerd Font 也能用）

zmodule zsh-users/zsh-completions --fpath src
zmodule completion
zmodule zsh-users/zsh-syntax-highlighting        # 命令语法高亮
zmodule zsh-users/zsh-history-substring-search   # 上下键按前缀搜历史
zmodule zsh-users/zsh-autosuggestions            # 灰色历史建议
```

改完 `.zimrc` 后执行 `zimfw install` 生效。

其中 `duration-info` 在调车时意外地有用：编译和启动命令的耗时会直接显示在提示符旁，不需要手动 `time`，也就更容易注意到「今天 colcon build 怎么比昨天慢了一倍」这类信号。

`zsh-syntax-highlighting` 的价值在于命令未执行前就能看出拼错——命令名不存在时显示红色。对着车敲命令时，这可以拦下一部分低级错误。

#attention[
zsh 有一个默认关闭但常被开启的选项 `noclobber`：开启后用 `>` 重定向到#strong[已存在]的文件会静默失败，只打印一行 `file exists`，而命令本身不执行。写脚本时如果用 `>` 覆盖日志文件，可能拿到的是上一次的旧内容却毫无察觉，后台运行时尤其隐蔽。统一用 `>|` 强制覆盖可以避免这个问题。
]

=== 现代命令行工具

这一组工具替代或补充了传统 Unix 命令。它们不是必需品，但在日常检索代码和翻日志时节省的时间相当可观。

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    stroke: (x, y) => (
      top: if y == 0 or y == 1 { 1pt } else { 0pt },
      bottom: if y == 8 { 1pt } else { 0pt },
    ),
    inset: 5pt,
    table.header([*工具*], [*替代/补充*], [*在 RM 开发里的典型用途*]),
    [`ripgrep` (`rg`)], [`grep -r`], [在整个工作空间里找某个话题名、参数名的所有出现位置],
    [`fd`], [`find`], [按名字找文件，默认跳过 `.git` 和 `build/`],
    [`bat`], [`cat`], [带语法高亮看配置文件和源码],
    [`eza`], [`ls`], [`eza --tree` 快速看包结构],
    [`fzf`], [—], [`Ctrl+R` 模糊搜索历史命令，调车时找上次那条长命令],
    [`zoxide`], [`cd`], [`z sentry` 直接跳到常去的工作空间],
    [`delta`], [`diff` 输出], [Git 差异带语法高亮和行号，评审时可读性显著提升],
  ),
  caption: [常用现代命令行工具],
)

安装：

```bash
sudo apt install ripgrep fd-find bat eza fzf zoxide
# Ubuntu 上 fd 的可执行文件名是 fdfind，bat 是 batcat，按需建立别名
```

在 `~/.zshrc` 末尾接入：

```zsh
# fzf: Ctrl+R 模糊搜历史 / Ctrl+T 插入文件路径 / Alt+C 跳目录
source <(fzf --zsh)

# zoxide: z <关键词> 跳到常去的目录，zi 交互选择
eval "$(zoxide init zsh)"
```

`rg` 有一个值得记住的陷阱：`-r` 不是 recursive（`rg` 默认就递归），而是 `--replace`。写成 `rg -rn pattern` 会把匹配到的文本替换成 `n` 再输出，制造出「代码里怎么长这样」的假象。`rg` 只用 `-n`（行号）、`-l`（只列文件名）、`-i`（忽略大小写）就够了。

=== direnv：让 ROS 不再污染全局环境

这一节是本章最值得读的部分。

几乎所有 ROS 教程都会让你在 `~/.bashrc` 里加一行：

```bash
source /opt/ros/jazzy/setup.bash
```

这在只有一个项目时没问题。但战队的实际情况是同时存在多个工作空间：哨兵导航一个、自瞄一个、仿真一个，可能还有一个不用 ROS 的纯 Python 训练项目。全局 `source` 会带来三类问题：

- `PYTHONPATH` 和 `LD_LIBRARY_PATH` 被 ROS 塞满，非 ROS 的 Python 项目会莫名其妙加载到 ROS 的库；
- 两个工作空间的 `install/setup.bash` 叠加后，`ros2 run` 可能跑到另一个工作空间编译的旧版本节点；
- 排查环境问题时无法回到「干净」状态，只能重开终端。

正确做法是让环境按目录自动生效。`direnv` 在进入目录时加载环境变量、离开时精确还原：

```bash
sudo apt install direnv
```

在 `~/.zshrc` 里挂钩子：

```zsh
eval "$(direnv hook zsh)"
```

然后在 `~/.config/direnv/direnvrc` 里定义一个可复用的函数。下面这份是实际在用的版本：

```bash
# ~/.config/direnv/direnvrc
# direnv 全局函数库。项目 .envrc 里写 `use ros` 即可。

# use ros [distro]
#   进目录时加载 ROS，离开时 direnv 自动还原全部环境变量。
#   如果工作空间 colcon build 过，自动叠加 install/setup.bash。
use_ros() {
    local distro="${1:-jazzy}"
    local base="/opt/ros/${distro}/setup.bash"
    if [ ! -f "$base" ]; then
        log_error "ROS ${distro} 未安装: ${base}"
        return 1
    fi
    # ROS 的 setup 脚本引用了未定义变量，临时关掉 nounset
    set +u
    source "$base"
    local overlay="${PWD}/install/setup.bash"
    if [ -f "$overlay" ]; then
        source "$overlay"
        log_status "ROS ${distro} + workspace overlay"
    else
        log_status "ROS ${distro}"
    fi
    set -u
    export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"
    # 让 direnv 在 install/ 变化时提示重载
    watch_file "${PWD}/install/setup.bash"
}

# use venv [path] —— 顺手给 Python 项目用，默认 .venv
use_venv() {
    local d="${1:-.venv}"
    if [ -f "${PWD}/${d}/bin/activate" ]; then
        source "${PWD}/${d}/bin/activate"
        log_status "venv ${d}"
    else
        log_error "找不到 ${PWD}/${d}/bin/activate"
    fi
}
```

之后每个工作空间根目录放一个 `.envrc`：

```bash
# ~/sentry_nav_26/.envrc
use ros jazzy
```

首次进入目录时 direnv 会拒绝执行并提示，需要显式授权一次：

```bash
direnv allow
```

这个授权机制不是麻烦，而是安全设计：`.envrc` 是可执行脚本，克隆别人的仓库时如果自动执行会有风险，所以 direnv 要求每份 `.envrc` 内容变化后都重新确认。

有三个实现细节值得解释，它们都是踩出来的：

`set +u` / `set -u` 的包裹。ROS 的 `setup.bash` 内部引用了若干未定义变量，在开启 `nounset` 的严格模式下会直接报错退出。临时关闭再恢复，是兼容 ROS 脚本的通用做法。

overlay 的条件加载。工作空间没编译过时 `install/setup.bash` 不存在，直接 `source` 会失败。先判断存在性，让未编译的工作空间也能正常进入。

`watch_file` 的作用。colcon 重新编译后 `install/setup.bash` 会更新，但 direnv 默认只在 `.envrc` 变化时重载。声明 watch 之后，编译完成会自动提示重载环境，避免「编译完了但 `ros2 run` 还是旧的」这类困惑。

=== Git 的可读性配置

Git 的默认差异输出在读大改动时相当吃力。三项配置可以显著改善，而且不改变任何 Git 行为，只改变显示：

```bash
# delta：带语法高亮、行号和并排视图的差异查看器
sudo apt install git-delta   # 或从 GitHub Releases 下载 .deb

git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true        # n / N 在文件间跳转
git config --global delta.line-numbers true
git config --global delta.hyperlinks true
git config --global delta.syntax-theme Nord
```

第二项是冲突样式。默认的冲突标记只显示「我的」和「他的」两侧，看不到共同祖先，很多时候无法判断到底哪边动了什么：

```bash
git config --global merge.conflictstyle zdiff3
```

`zdiff3` 会额外显示共同祖先版本，冲突块变成三段。多花两行显示，换来的是能直接看出「这一行是我改的还是他改的」。

第三项是结构化差异。`difftastic` 理解语法树，重排代码、改缩进这类不改变语义的变动不会被当作大段差异：

```bash
sudo apt install difftastic   # 或 cargo install difftastic

git config --global difftool.difftastic.cmd 'difft "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
git config --global alias.dft 'difftool -t difftastic'
git config --global alias.dlog 'log -p --ext-diff'
```

配置后 `git dft` 看工作区差异，`git dlog` 看带结构化差异的历史。评审格式调整量大的提交时，这个差别很明显。

最后是 GitHub 认证。不要用密码或把 token 写进配置文件，用 `gh` 托管：

```bash
sudo apt install gh
gh auth login          # 按提示浏览器授权一次
gh auth setup-git      # 让 git 通过 gh 获取凭据
```

`gh` 同时也是后面几节要用的命令行工具：查 PR、看 CI 日志、开 Issue 都可以不离开终端。

=== 中文输入法

Ubuntu 24.04 自带的中文输入体验较弱，需要装 Fcitx5。这里用的是 Fcitx5 + Rime 组合。

```bash
sudo apt install fcitx5 fcitx5-chinese-addons fcitx5-rime \
                 fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 \
                 fcitx5-frontend-qt5 fcitx5-frontend-qt6 \
                 fcitx5-config-qt
```

装完需要重新登录，然后在「设置 → 键盘 → 输入源」里把 Fcitx5 设为默认，并在 `fcitx5-config-qt` 里把 Rime 加入输入法列表。

Rime 与开箱即用的拼音方案的区别在于它是一个输入法引擎而非一个输入法：词库、候选顺序、翻页键、中英切换逻辑都写在配置文件里，可以完全按自己的习惯改，配置文件本身也可以放进 Git 仓库跨机器同步。代价是初始配置成本更高。

如果只想快速可用，`fcitx5-pinyin` 装完即用，不需要配置。选 Rime 的理由是它的配置可以随仓库走——换机器、重装系统时不用重新调教输入法。这个取舍与「统一环境」的思路是一致的：把一次性投入换成可复现的配置文件。

#note[
安装 Fcitx5 后如果部分应用（尤其是 Electron 应用和 IDE）无法输入中文，通常是环境变量没设。在 `/etc/environment` 里加入以下三行并重新登录：

```
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
```
]

=== 环境清单

新机器从零配置时按下面顺序执行，全部完成约 1 到 2 小时（不含 ROS 2 下载时间）。

+ 装 Ubuntu 24.04 LTS，选「最小安装」，装完先 `sudo apt update && sudo apt upgrade`。
+ 装 ROS 2 Jazzy（按官方文档，`ros-jazzy-desktop`），#strong[不要]把 `source` 写进 `.bashrc`。
+ 装 git、gh、build-essential、cmake、python3-colcon-common-extensions。
+ 装 zsh，`chsh` 切换，安装 Zim，写 `.zimrc`。
+ 装 ghostty，写 `~/.config/ghostty/config`（注意无扩展名），装 Maple Mono NF CN 字体。
+ 装现代 CLI 工具组，在 `.zshrc` 里接入 fzf 和 zoxide。
+ 装 direnv，写 `~/.config/direnv/direnvrc`，在 `.zshrc` 挂钩子。
+ 配置 Git：delta、zdiff3、difftastic、`gh auth login`。
+ 装 Fcitx5 输入法，设 `/etc/environment` 三行环境变量，重新登录。
+ 克隆一个战队仓库，写 `.envrc`，`direnv allow`，`colcon build` 验证整套环境。

最后一步是验收：如果 `colcon build` 能过，并且离开目录后 `ros2` 命令消失、回到目录又恢复，说明 direnv 和 ROS 都配对了。

#note[
把这份清单维护成战队仓库里的一个脚本，比维护成一篇文档更有价值。文档会过期而没人发现，脚本跑不过会立刻暴露。建议放在 `Aurora-UJS` 组织下单独一个 `dev-setup` 仓库，每年赛季开始前由新一届跑一遍并提 PR 修正。
]
