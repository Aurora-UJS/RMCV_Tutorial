
=== 图形界面初探
// Ubuntu 桌面环境快速上手
// - GNOME 桌面基本操作
// - 文件管理器（Nautilus）
// - 系统设置
// - 应用程序安装（Software Center）
// - 截图、录屏等实用工具
// - 快捷键汇总
// - 但是...为什么我们要学命令行？

安装并登录 Ubuntu 后，首先看到的是 GNOME 桌面。它与 Windows 或 macOS 的布局不同，但仍由应用程序、文件管理器、系统设置和状态栏等熟悉的部分组成。先用图形界面完成几项日常操作，有助于建立对系统的直观认识；后面的终端命令并不是要取代图形界面，而是补充远程操作、批量处理和开发工作所需的能力。

按一下键盘上的 `Super` 键（多数键盘上带有 Windows 徽标），或单击左上角的“活动”，可以打开活动概览。在这里可以搜索应用、切换窗口，也可以把常用程序固定到侧边栏。GNOME 还提供多个工作区：例如把编辑器和终端放在一个工作区，把浏览器和文档放在另一个工作区，减少窗口互相遮挡。触控板手势和工作区快捷键可能随 Ubuntu 版本及设置而变化，可以在“设置 → 多任务”中查看当前配置。

Ubuntu 的文件管理器在界面中通常显示为“文件”（Files），其项目名是 Nautilus。左侧栏列出主目录、下载、文档、回收站以及已经挂载的磁盘；顶部路径栏显示当前位置。常见的复制、重命名和新建目录都可以通过右键菜单完成。按 `Ctrl+L` 可以把当前位置切换为可编辑的路径，按 `Ctrl+H` 可以显示或隐藏名称以 `.` 开头的文件。配置文件经常是隐藏文件，但“隐藏”只影响默认显示，并不提供访问保护。

删除到回收站的文件通常还能恢复，“清空回收站”或某些跨文件系统的删除操作则不能依赖这一点。连接 U 盘或移动硬盘后，应在侧边栏单击弹出按钮并等待写入完成，再拔出设备；仅仅关闭文件管理器窗口并不等于已经卸载设备。

“设置”应用集中管理网络、蓝牙、显示器、声音、键盘、用户与电源等选项。修改分辨率、缩放比例或输入设备前，可以先记住原配置；显卡驱动等系统级设置还可能要求管理员认证或重启。Ubuntu 的应用商店名称和界面会随发行版更新，在 Ubuntu 22.04 中可以用它搜索并安装常见桌面软件。商店中的软件可能来自 Ubuntu 的 APT 软件源，也可能采用 Snap 格式，两者的版本、磁盘占用、权限隔离和更新方式不完全相同。后文会分别介绍命令行下的软件包管理方法。

按 `Print Screen` 通常会打开 GNOME 的截图界面，可选择全屏、窗口或矩形区域；部分键盘需要同时按 `Fn`。Ubuntu 22.04 的 GNOME 也提供屏幕录制入口。具体按钮和快捷键可能因桌面版本而异，在“设置 → 键盘 → 查看及自定义快捷键”中核对最可靠。截图前注意清理终端里的令牌、主机地址和个人路径，分享日志时也应检查其中是否包含敏感信息。

图形界面适合浏览和一次性操作，终端则便于精确记录命令、批量处理文件，并能通过 SSH 操作没有显示器的车载计算机。实际开发中二者会交替使用：可以在文件管理器中找到项目目录，再从该目录打开终端；也可以在终端生成结果后，用图形程序查看图像或日志。接下来从这套文字交互方式的几个基本概念开始。

=== 终端与 Shell 基础
// 命令行界面入门
// - 什么是终端、Shell、Bash
// - 打开终端：Ctrl+Alt+T
// - 命令格式：命令 [选项] [参数]
// - 获取帮助：man, --help, tldr
// - 命令历史与自动补全（Tab, ↑↓, Ctrl+R）
// - 快捷键：Ctrl+C, Ctrl+D, Ctrl+Z, Ctrl+L
// - 通配符：* ? []
// - 输入输出重定向：> >> < 2>&1
// - 管道：|
// - 后台运行：&, nohup
// - 环境变量与 PATH
// === 终端与 Shell 基础

刚接触 Linux 时，终端里闪烁的光标可能显得不太友好。其实它只是另一种操作界面：你用文字输入命令，Shell 负责解释，系统再把结果显示出来。现代 Linux 发行版虽然提供完整的图形界面，但软件安装、文件管理、程序运行和系统配置仍经常通过终端完成。RoboMaster 开发中的工程编译、ROS 节点运行、日志查看和 SSH 远程维护也常在这里进行。本节从终端、Shell 与 Bash 的关系讲起，再介绍日常使用需要的基本操作。

==== 终端、Shell 与 Bash

在深入使用之前，让我们先理清几个容易混淆的概念：终端（Terminal）、Shell 和 Bash。

在 Ubuntu 桌面上，我们通常所说的终端是终端模拟器（Terminal Emulator）：它提供一个窗口，用来显示文字并接收键盘输入。早期的终端是通过线路连接到主机的物理设备，如今常见的桌面终端由软件实现；通过 SSH 登录远程机器时，还会用到伪终端。Ubuntu 22.04 默认提供 GNOME Terminal，也可以使用 Konsole、Terminator 或 Alacritty 等程序。它们的界面和附加功能不同，但都可以承载命令行会话。

Shell 是命令解释器。输入 `ls` 并按回车后，Shell 会解析命令和参数，按规则查找对应程序并启动它；程序的输出再由终端显示。Shell 还负责变量、通配符、重定向、管道和脚本等功能。它并不会把每条命令直接逐字“翻译”为系统调用，外部程序和 Shell 内置命令的执行路径也有所不同。

Bash（Bourne Again Shell）是常见的 Shell 之一，也是 Ubuntu 22.04 普通用户默认的交互式 Shell。除了 Bash，还有 Zsh、Fish、Dash 等；Ubuntu 的 `/bin/sh` 默认指向 Dash，并不等同于 Bash。不同 Shell 的基本用途相近，但脚本语法和配置文件可能不同。本章明确以 Bash 为例，遇到来自其他 Shell 的配置片段时不能直接假定兼容。

简单地说，桌面终端提供文字交互界面，Shell 读取并解释命令，而 Bash 是本章使用的具体 Shell。日常所说的“打开终端输入命令”，在本书环境中就是打开终端模拟器，在其中的 Bash 会话里操作。

==== 打开终端

在 Ubuntu 桌面环境中，最快捷的方式是按下 `Ctrl+Alt+T`，这会立即打开一个终端窗口。你也可以在应用程序菜单中搜索“Terminal”或“终端”来打开它。

打开终端后，你会看到一个提示符（prompt），类似于：

```
username@hostname:~$
```

这个示例提示符包含几项信息：`username` 是当前用户名，`hostname` 是计算机名，`~` 表示当前位于用户主目录。按照常见约定，普通用户的提示符以 `$` 结尾，root 用户以 `#` 结尾；这不是权限检测机制，主题和配置可以任意改变提示符的外观。执行敏感命令前，应以当前用户和实际权限为准，不能只看最后一个字符。

现在你可以输入命令了。试着输入 `echo "Hello, Linux!"` 并按回车：

```bash
echo "Hello, Linux!"
Hello, Linux!
```

`echo` 会把给定文字写到标准输出。看到下一行结果，说明当前终端会话已经能够读取并执行这条简单命令。

==== 命令的格式

许多命令可以用下面的通用形式来理解：

```
命令 [选项] [参数]
```

命令名指出要运行的程序或 Shell 内置命令，选项（options）调整行为，其他参数（arguments）提供文件名、数值或操作对象。这是一种常见约定，不是所有程序都严格采用同一种解析规则；具体用法仍以该命令的帮助文档为准。

让我们以 `ls` 命令为例。`ls` 用于列出目录内容，是最常用的命令之一：

```bash
# 最简单的形式，列出当前目录的内容
ls
Desktop  Documents  Downloads  Music  Pictures  Videos

# 带选项：-l 表示详细列表格式
ls -l
total 24
drwxr-xr-x 2 user user 4096 Jan 15 10:00 Desktop
drwxr-xr-x 2 user user 4096 Jan 15 10:00 Documents
...

# 带参数：指定要列出的目录
ls /usr/bin
[大量程序名]

# 同时带选项和参数
ls -l /usr/bin
[详细列表]
```

GNU/Linux 中的许多程序支持两种选项形式：短选项以单个连字符开头，后跟一个字母；长选项以两个连字符开头，后跟完整单词。例如 GNU `ls` 的 `-a` 与 `--all` 等价，`ls -la` 也等价于 `ls -l -a`。短选项能否组合、选项能否放在参数之后，以及是否支持长选项，都由程序自己决定。常见的 `--` 表示后续内容不再按选项解析，在处理以 `-` 开头的文件名时尤其有用。

不同的命令有不同的选项和参数规则。记住所有命令的所有选项是不现实的，关键是知道如何查找帮助信息——这正是下一节要讲的内容。

==== 获取帮助

Linux 命令和选项很多，实际使用时经常需要查阅文档。系统手册、命令自带帮助和示例摘要各有用途。

系统安装的手册页（man pages）通常提供较完整的参考。许多外部命令都有对应页面，可以用 `man` 查看：

```bash
man ls
```

这会打开 `ls` 的手册页，其中包含命令说明、选项和相关信息。手册页通常由 `less` 显示，可以用方向键或 `j`/`k` 滚动，用 `/` 搜索，按 `q` 退出。并非每个命令都有独立手册页；查询 Bash 内置命令时还可以使用 `help cd`、`help history` 等形式。遇到同名主题，可用 `man -f 名称` 查看所在的手册章节。

需要快速查看用法时，许多 GNU 命令支持 `--help`：

```bash
ls --help
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
...
```

这类输出通常比手册页短，适合快速参考，但 `--help` 并不是所有程序都遵守的统一接口。

对于完全不熟悉的命令，`tldr`（Too Long; Didn't Read）提供由社区维护的常见用法示例：

```bash
# 首先安装 tldr
sudo apt install tldr

# 查看命令的简明帮助
tldr tar
tar

Archiving utility.
...

- Create an archive from files:
    tar cvf target.tar file1 file2 file3

- Extract an archive in the current directory:
    tar xvf source.tar
...
```

`tldr` 适合先了解典型操作，但它只覆盖常见情形，不能替代程序的正式文档。软件包中的客户端和页面缓存行为可能随 Ubuntu 软件源版本而异，安装后若没有页面，可先查看 `tldr --help` 中的更新方法。

还有一个有用的命令是 `type`，它告诉你某个命令是什么：

```bash
type ls
ls is aliased to `ls --color=auto'

type cd
cd is a shell builtin

type python3
python3 is /usr/bin/python3
```

这可以帮助你判断一个名称当前会被解析为内置命令、外部程序、函数还是别名。

==== 命令历史与自动补全

Shell 的历史记录和补全功能可以减少重复输入，也能降低长路径的拼写错误概率。

输入命令或路径的一部分后按 Tab，Shell 会尝试补全。如果只有一个匹配项，通常会直接补全；存在多个匹配项时，可以再次按 Tab 查看候选项。具体按键反馈取决于 Bash 和 readline 配置：

```bash
# 输入 "cd Doc" 然后按 Tab
cd Doc<Tab>
cd Documents/  # 自动补全

# 输入 "ls /usr/l" 然后按 Tab Tab
ls /usr/l<Tab><Tab>
lib/    lib64/  local/  # 显示所有可能的选项
```

命令和路径的基础补全由 Shell 提供；安装并加载 `bash-completion` 后，许多命令还可以补全选项、Git 分支名或已知 SSH 主机名。补全结果仍应在执行前检查，尤其是删除、覆盖和远程操作。

命令历史让你可以重用之前输入过的命令。按上箭头 `↑` 可以回溯到上一条命令，继续按可以查看更早的命令；下箭头 `↓` 可以向前浏览。找到想要的命令后，可以直接按回车执行，也可以编辑后再执行。

反向搜索适合寻找较早的命令。按 `Ctrl+R` 后输入关键词，Bash 会搜索历史中包含该关键词的记录：

```bash
# 按 Ctrl+R，然后输入 "git"
(reverse-i-search)`git': git push origin main
```

继续按 `Ctrl+R` 可以查看更早的匹配项。找到想要的命令后，按回车执行，或按右箭头将其放到命令行上编辑。这个功能在你想重复执行某个复杂命令但记不清完整内容时非常有用。

Bash 通常会把历史写入 `~/.bash_history`，内存中和文件中保留的条数由 `HISTSIZE`、`HISTFILESIZE` 等配置决定。`history` 可以列出记录；`!n` 和 `!!` 会进行历史展开，并可能在按下回车后立即执行展开出的命令。对含有删除、覆盖或提权操作的记录，先用上箭头或 `fc -ln n n` 查看和编辑，比直接展开执行更稳妥。命令行中的令牌和密码还可能进入历史，因此敏感信息不应直接写在参数中。

==== 常用快捷键

掌握终端快捷键可以让你的操作更加流畅。以下是最重要的几个：

`Ctrl+C` 常用于请求中断当前前台任务。终端通常会让 Shell 向前台进程组发送 `SIGINT` 信号，大多数命令收到后退出；程序也可以捕获或忽略该信号，所以它不等同于无条件“强制终止”。

```bash
# 运行一个长时间的命令
sleep 1000
^C  # 按 Ctrl+C 中断
  # 回到提示符
```

`Ctrl+D` 不是信号，而是让终端输入层在当前没有待传数据时报告文件结束（EOF）。在空的 Bash 提示符下，它通常会使当前 Shell 退出，效果类似 `exit`；在有待编辑文字时，或在其他交互式程序中，具体行为取决于程序如何读取输入。

在支持作业控制的交互式 Shell 中，`Ctrl+Z` 通常向前台进程组发送 `SIGTSTP`，使任务暂停并回到 Shell 提示符。任务此时并未继续在后台运行；可以用 `fg` 恢复到前台，或用 `bg` 让它在后台继续。某些程序会处理该信号，非交互式 Shell 也不一定启用作业控制。

`Ctrl+L` 清屏，相当于 `clear` 命令。当终端内容太多变得混乱时，这个快捷键可以让你获得一个干净的屏幕，但不会影响命令历史或当前正在输入的内容。

编辑命令行时，以下快捷键也很有用：

- `Ctrl+A`：移动光标到行首
- `Ctrl+E`：移动光标到行尾
- `Ctrl+U`：删除光标前的所有内容
- `Ctrl+K`：删除光标后的所有内容
- `Ctrl+W`：删除光标前的一个单词
- `Alt+B`：向后移动一个单词
- `Alt+F`：向前移动一个单词

这些是 Bash 默认 readline 配置中常见的 Emacs 风格键绑定，用户可以切换或重新配置。开始时记住 `Ctrl+C`、`Ctrl+R` 和行首行尾操作即可，其余按需要逐步使用。

==== 通配符

通配符（wildcards）可以用模式选择多个路径。Bash 会在启动外部命令之前进行路径名展开，所以接收参数的程序通常看到的是已经展开的文件列表，而不是 `*` 本身。

星号 `*` 在一个路径组件内匹配任意数量的字符（包括零个字符），但不会跨过 `/` 进入下一层目录；需要匹配子目录时，要在模式中明确写出 `/`，或在谨慎评估范围后使用 `globstar`、`find` 等机制。这是最常用的通配符：

```bash
# 列出所有 .cpp 文件
ls *.cpp
main.cpp  detector.cpp  tracker.cpp

# 列出所有以 test 开头的文件
ls test*
test_detector.cpp  test_tracker.cpp  test_results.txt

# 向 rm 传入当前目录中所有名称以 .o 结尾的非隐藏路径
rm -- *.o
```

问号 `?` 匹配恰好一个任意字符：

```bash
# 匹配 file1.txt, file2.txt, ... 但不匹配 file10.txt
ls file?.txt
file1.txt  file2.txt  file3.txt
```

方括号 `[]` 匹配其中的任意一个字符：

```bash
# 匹配 file1.txt 或 file2.txt
ls file[12].txt
file1.txt  file2.txt

# 匹配任意数字
ls file[0-9].txt
file0.txt  file1.txt  ...

# 在当前区域设置的排序规则下匹配 a 到 z 的范围
ls file[a-z].txt
filea.txt  fileb.txt  ...
```

默认情况下，开头的 `*` 不匹配名称以 `.` 开头的隐藏文件，字符范围的含义还会受到区域设置影响。通配符与 `rm` 等命令组合时，应先让不会修改文件的命令展开同一模式，核对参数列表；`--` 可以防止匹配结果中以 `-` 开头的名称被当成选项：

```bash
# 先逐行显示将要传入的路径
printf '%s\n' *.tmp
cache1.tmp
cache2.tmp
temp.tmp

# 确认后再删除
rm -- *.tmp
```

在 Bash 的默认设置下，如果通配符没有匹配任何路径，模式会原样保留；`nullglob`、`failglob` 等选项可以改变这一行为。因此不能仅凭模式的写法断定实际参数：

```bash
# 如果没有 .xyz 文件
ls *.xyz
ls: cannot access '*.xyz': No such file or directory
```

==== 输入输出重定向

程序启动时通常会继承三个约定的文件描述符：标准输入（stdin）、标准输出（stdout）和标准错误（stderr）。在普通交互式终端中，输入来自终端，两个输出也显示在终端；程序、Shell 或调用者都可以关闭或改接这些描述符。重定向就是 Shell 在启动命令前改变这些连接。

`>` 将标准输出重定向到文件。如果文件存在，会被覆盖；如果不存在，会被创建：

```bash
# 将 ls 的输出保存到文件
ls -l > filelist.txt

# 查看文件内容
cat filelist.txt
total 24
drwxr-xr-x 2 user user 4096 Jan 15 10:00 Desktop
...
```

`>>` 将标准输出追加到文件末尾，不会覆盖原有内容：

```bash
# 追加内容到文件
echo "New line" >> filelist.txt
```

`<` 将文件内容作为标准输入：

```bash
# 从文件读取输入
sort < unsorted.txt
```

标准错误（错误信息）默认不会被 `>` 重定向。要重定向标准错误，使用 `2>`：

```bash
# 将错误信息重定向到文件
ls nonexistent 2> error.log

# 将标准输出和标准错误分别重定向
command > output.log 2> error.log

# 将标准错误重定向到标准输出（常用于日志记录）
command > all.log 2>&1

# 更简洁的写法（Bash 4+）
command &> all.log
```

`2>&1` 的含义是“让文件描述符 2（标准错误）指向文件描述符 1（标准输出）在这一刻所指的位置”。重定向按从左到右的顺序处理：`> file 2>&1` 会把两者都写入文件；`2>&1 > file` 则先让标准错误指向原来的标准输出，再把标准输出改到文件，因此错误仍会显示在终端。这后一种写法并非语法错误，只是结果通常不符合“全部写入文件”的意图。

如果确实不需要某项输出，可以把它重定向到 `/dev/null`；写入这个特殊设备的数据会被丢弃：

```bash
# 丢弃标准输出
command > /dev/null

# 丢弃所有输出
command > /dev/null 2>&1
```

==== 管道

管道（pipe）用 `|` 表示，它把左侧命令的标准输出连接到右侧命令的标准输入。许多命令可以因此分工处理同一份数据，这也是 Unix 命令行常见的组合方式。

```bash
# 列出文件并统计行数
ls -l | wc -l
15

# 查找包含特定文本的行；grep 也可以直接读取文件
grep "error" log.txt
[所有包含 error 的行]

# 排序并去重
cat names.txt | sort | uniq
```

管道可以连接多个命令，形成处理流水线：

```bash
# 在 Ubuntu 的 GNU find 中列出当前目录最大的 5 个普通文件
find . -maxdepth 1 -type f -printf '%s\t%f\n' | sort -nr | head -n 5
512000  bigfile.dat
256000  medium.dat
...
```

这里的 `find` 输出文件字节数和名称，`sort -nr` 按第一列作数值降序排列，`head -n 5` 只保留前五行。该写法使用 GNU `find` 的 `-printf`，适用于本书的 Ubuntu 环境，不是所有 Unix 系统都支持。若文件名包含换行符，这种按行处理的展示方式也会失真；批量修改文件时需要改用以 NUL 分隔的接口。

管道可以把多个小工具组合成数据处理流程。一些常用的管道组件包括：

- `grep`：过滤包含特定模式的行
- `sort`：排序
- `uniq`：去除相邻的重复行（通常与 sort 配合使用）
- `wc`：统计行数、单词数、字符数
- `head` / `tail`：只保留开头/结尾的几行
- `cut`：提取列
- `awk` / `sed`：按字段或规则处理文本

掌握这些工具的输入输出约定后，就能通过管道完成不少文本处理任务。默认情况下，Bash 返回管道中最后一条命令的退出状态；脚本若需要发现前面命令的失败，还要结合后文介绍的 `pipefail`。因此，管道输出看起来合理，并不代表其中每一步都成功。

==== 后台运行

在交互式 Shell 中，前台命令运行时，Shell 通常会等待它结束才再次显示提示符。把任务放到后台后，可以在同一终端继续输入命令，但后台任务仍可能向终端输出内容。

在命令末尾加上 `&`，命令会在后台启动：

```bash
long_running_command &
[1] 12345
 # 立即返回提示符
```

`[1]` 是当前 Shell 分配的作业编号，`12345` 是它报告的进程 ID。作业编号只对当前 Shell 的作业控制有意义，不能当作系统范围内稳定的任务标识。

`jobs` 命令列出当前 Shell 的后台作业：

```bash
jobs
[1]+  Running                 long_running_command &
```

`fg` 把后台作业带回前台，`bg` 让暂停的作业在后台继续运行：

```bash
# 把作业 1 带到前台
fg %1

# 让作业 1 在后台继续
bg %1
```

前面提到的 `Ctrl+Z` 可以暂停当前前台程序，然后用 `bg` 让它在后台继续：

```bash
long_command
^Z  # 按 Ctrl+Z 暂停
[1]+  Stopped                 long_command
bg
[1]+ long_command &
 # 命令在后台继续运行
```

单独使用 `&` 不会让任务脱离当前会话。关闭终端或断开 SSH 后，Shell 或终端通常会向相关作业发送挂起信号，但具体行为还取决于 Shell 配置、程序是否处理信号以及会话如何结束。需要让简单的非交互命令在挂起信号后继续时，可以使用 `nohup` 并明确安排输入输出：

```bash
nohup long_command </dev/null >long_command.log 2>&1 &
[1] 12345
```

`nohup` 会让它启动的命令忽略 `SIGHUP`；上例还断开了标准输入，并把两类输出写入日志。它并不提供自动重启、资源限制或日志轮转，也不能保证机器重启后恢复任务。

需要保留交互现场时，可以使用 `screen` 或 `tmux` 这样的终端复用器，断开后再连接原会话。需要长期运行并在失败或开机后自动恢复的服务，则更适合由后文介绍的 systemd 管理。三者解决的问题不同。

==== 环境变量与 PATH

环境变量是由进程携带并可传给子进程的字符串键值对，程序常用它们读取配置。Shell 自己还有未导出的 Shell 变量，两者需要区分。查看变量时最好给展开加引号，避免空格和通配符再次参与拆分：

```bash
printf '%s\n' "$HOME"
/home/username

printf '%s\n' "$USER"
username

printf '%s\n' "$SHELL"
/bin/bash
```

`SHELL` 通常记录账户配置的登录 Shell，并由父进程传入环境；它不保证等于当前正在解释命令的程序。例如，从 Bash 中临时启动 Zsh 后，`$SHELL` 仍可能是 `/bin/bash`。因此它适合说明默认登录设置，不应单独用于判断脚本当前运行在哪种 Shell 中。

不带参数的 `env` 会显示当前命令继承到的环境，`export` 可以设置变量并标记它应传给之后启动的子进程：

```bash
# 设置环境变量
export MY_VAR="hello"

# 验证
printf '%s\n' "$MY_VAR"
hello
```

如果只写 `MY_VAR="hello"` 而不 `export`，它是当前 Shell 的变量，默认不会出现在随后启动程序的环境中。子进程可以继承环境，却不能反过来直接修改父 Shell 的环境，这也是某些环境设置脚本必须用 `source` 执行的原因。

最重要的环境变量之一是 `PATH`。它决定了 Shell 在哪些目录中搜索可执行程序。当你输入一个命令时，Shell 会按 PATH 中列出的目录顺序查找同名的可执行文件：

```bash
printf '%s\n' "$PATH"
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
```

PATH 中的目录用冒号分隔。这就解释了为什么你可以直接输入 `ls` 而不是 `/bin/ls`——因为 `/bin` 在 PATH 中。

如果程序安装在非标准位置，可以在确认目录可信后把其可执行文件目录加入 PATH：

```bash
# 临时添加到 PATH（当前 Shell 有效）
export PATH="/opt/myprogram/bin:$PATH"

# 需要长期使用时，在 ~/.bashrc 中只添加一次同样的 export 行
# 保存后打开新终端，或确认文件内容后再在当前 Bash 中执行：
source ~/.bashrc
```

`~/.bashrc` 通常在交互式非登录 Bash 启动时读取；登录方式和发行版配置还可能经过 `~/.profile` 等文件。把目录放在 PATH 前面会优先使用其中的同名程序，放在后面则保留系统程序的优先级。不要把当前目录 `.` 或来源不可信、其他用户可写的目录放到 PATH 前部，否则输入常见命令时可能运行意外文件。反复追加同一行还会使配置膨胀，因此应编辑并检查配置文件，而不是每次都盲目追加。

某些手工安装的软件会要求临时指定共享库搜索路径。若确实需要，可以把变量只作用于一次命令：

```bash
LD_LIBRARY_PATH="/opt/myprogram/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" myprogram
```

长期、全局设置 `LD_LIBRARY_PATH` 可能让其他程序加载到不匹配的同名库。优先使用发行版软件包、程序自身的运行时路径或经过维护的链接器配置；只有理解目标软件文档的前提后再修改该变量。

RoboMaster 开发还会用环境脚本设置 ROS 2 的包搜索路径和其他变量。本书采用 ROS 2 Humble，因此新会话中常见的命令是 `source /opt/ros/humble/setup.bash`；只有已经安装对应发行版且文件存在时这条命令才会成功。后续叠加工作空间时，`source` 的顺序也会影响找到哪个包。

至此，终端、Shell、命令格式和数据流之间的关系已经建立起来。下一节转向 Linux 的目录树；理解路径和文件类型后，前面出现的补全、通配符、重定向与 PATH 会有更具体的操作对象。


=== 文件系统与目录结构
// Linux 的文件组织方式
// - 根目录 / 与目录树
// - 重要目录详解：/home, /etc, /usr, /opt, /var, /tmp, /dev, /proc
// - 绝对路径与相对路径
// - 特殊路径：. .. ~ -
// - 文件类型：普通文件、目录、链接、设备
// - 隐藏文件（.开头）
// === 文件系统与目录结构

Linux 把当前可见的文件系统组织成一棵目录树，起点是根目录 `/`。磁盘分区、移动设备和部分由内核动态生成的信息，都可以挂载到这棵树的某个目录下，因此不会像 Windows 那样为每个卷固定使用独立盘符。理解常用目录、路径写法和文件类型后，才能准确判断命令正在读取或修改什么。

==== 根目录与目录树

根目录用单个斜杠 `/` 表示，是一个进程所见目录树的顶层。系统可以把其他文件系统挂载到其中的目录；容器、挂载命名空间和 `chroot` 还可能让不同进程看到不同的根和挂载集合。本章先讨论普通 Ubuntu 会话中的常见布局。

让我们从根目录开始探索。打开终端，输入 `ls /` 可以看到根目录下的内容：

```bash
ls /
bin   dev  home  lib64       media  opt   root  sbin  srv  tmp  var
boot  etc  lib   lost+found  mnt    proc  run   snap  sys  usr
```

许多核心目录遵循文件系统层次标准（Filesystem Hierarchy Standard，FHS），但发行版、安装方式和系统角色会带来差异。例如 `/snap` 是 Ubuntu 的扩展，有些系统没有单独的 `/home` 分区，也不是每台机器都会出现示例中的所有目录。目录标准提供的是常见约定，不是逐项完全相同的清单。

由发行版软件包安装的一个程序，文件通常按用途分布：可执行文件可能在 `/usr/bin`，库在 `/usr/lib`，系统配置在 `/etc`，共享数据在 `/usr/share`，运行时状态则在 `/var`。自包含的第三方软件也可能集中在 `/opt`，用户程序还会把配置和数据放在家目录。因此，知道软件名称并不总能直接推出文件位置，后文会介绍用包管理器和查找命令核对实际路径。

==== 重要目录详解

下面按用途介绍常见目录，并同时说明这些约定的边界。

`/home` 是普通用户的家目录所在地。每个用户都有一个以用户名命名的子目录，如 `/home/alice`、`/home/bob`。用户的个人文件、配置、下载、文档都存放在这里。当你在终端中看到 `~` 符号，它就代表当前用户的家目录。对于用户 `alice` 来说，`~` 等价于 `/home/alice`。

普通用户通常拥有自己的家目录，可以在权限和磁盘配额允许的范围内创建、修改文件。它不自动保证“只有本人可读”：实际访问能力由目录权限、访问控制列表和挂载方式决定。系统级目录（如 `/usr`、`/etc`）通常只有管理员可以修改。RoboMaster 项目的代码、编译产物和个人配置可以放在家目录的子目录中，如 `~/ros2_ws`（ROS 2 工作空间）或 `~/projects`，并根据队伍的备份方式安排重要数据。

```bash
ls ~
Desktop  Documents  Downloads  Music  Pictures  Public  Templates  Videos
ros2_ws  projects   .bashrc    .config  .local
```

注意那些以点开头的文件和目录（如 `.bashrc`、`.config`），它们是隐藏文件，普通的 `ls` 不会显示它们，需要加 `-a` 选项。这些隐藏文件通常存储配置信息，我们稍后会详细讨论。

`/etc` 主要存放本机的系统级配置。目录名来自早期 Unix 中的 “et cetera”；“Editable Text Configuration”是后来便于记忆的展开，并非其历史来源。许多服务在这里放文本配置，但程序也可能使用其他位置或由工具生成文件，不能把 `/etc` 理解为所有配置的唯一来源。

```bash
ls /etc
apt           hostname    passwd      ssh
bash.bashrc   hosts       profile     sudoers
default       network     resolv.conf systemd
fstab         nginx       shadow      ...
```

例如，`/etc/passwd` 保存账户名称、用户 ID、主目录和登录 Shell 等字段，密码散列通常在权限更严格的 `/etc/shadow`；`/etc/hosts` 提供本地主机名映射，`/etc/fstab` 描述静态挂载配置，安装 OpenSSH 服务端后可通过 `/etc/ssh/sshd_config` 及其包含文件配置服务。修改前应先查对应程序的文档、备份原文件并使用其配置检查命令；并非看到 `/etc` 下的文件就应直接用 `sudo` 编辑。

`/usr` 在现代系统中保存大部分可共享、通常只由软件管理工具修改的程序、库和数据。其名称历史上与早期 Unix 的用户目录有关，“Unix System Resources”是后来的解释，不是可靠的词源。它包含与根目录相似的若干子目录：

```bash
ls /usr
bin  games  include  lib  lib64  local  sbin  share  src
```

`/usr/bin` 存放大量用户命令（如 `gcc`、`python3`、`git`），`/usr/lib` 存放库和程序私有数据，`/usr/include` 存放开发头文件，`/usr/share` 存放文档、图标、翻译等与处理器架构无关的数据。Ubuntu 22.04 采用合并的 `/usr` 布局时，根下的 `/bin`、`/sbin`、`/lib` 可能是指向 `/usr` 对应位置的符号链接；脚本不应根据示例输出假定它们一定是独立目录。

`/usr/local` 预留给本机管理员维护的软件，其结构也包含 `bin`、`lib`、`include` 等。许多源码项目把 `/usr/local` 作为默认安装前缀，但具体位置由构建配置决定。把文件放在这里可以与发行版管理的 `/usr` 分开，却不能自动避免版本遮蔽、同名文件或共享库搜索冲突；安装前仍应检查文件清单，并优先选择可卸载、可复现的安装方式。普通用户写入 `/usr/local` 通常需要管理员权限，也可以改用家目录中的用户前缀。

```bash
# 查看本地安装的程序
ls /usr/local/bin

# 查看本地安装的库
ls /usr/local/lib
```

`/opt` 是 "optional" 的缩写，常用于安装附加软件包。与 `/usr/local` 的分散层次不同，`/opt` 下的软件主要文件往往集中在一个专用子目录中，如 `/opt/google/chrome`、`/opt/ros/humble`；安装器仍可能在其他位置登记配置、桌面入口或服务。ROS 2 的 Ubuntu 二进制包默认把各发行版的主要前缀放在 `/opt/ros/<distro>` 下。

```bash
ls /opt
google  ros  cuda

ls /opt/ros
humble  iron
```

这种布局把一个附加软件包的文件集中在专用子目录中，但卸载方式仍取决于它如何安装：通过 APT、Snap 或厂商安装器安装的软件，应使用相应工具卸载，不能直接删除 `/opt` 子目录并假定没有其他注册文件。可执行文件也不一定自动进入 PATH；ROS 2 提供 `setup.bash`，执行 `source /opt/ros/humble/setup.bash` 后会为当前 Shell 设置所需环境。

`/var` 存放可变的数据文件，即运行时会改变的内容。“var”代表“variable”。最重要的子目录包括：

- `/var/log`：许多系统和程序的日志文件；采用 systemd journal 的服务还要用 `journalctl` 查询。
- `/var/cache`：应用程序的缓存数据。包管理器的下载缓存通常在这里。
- `/var/lib`：程序的状态信息。数据库文件、包管理器的数据库等。
- `/var/tmp`：比 `/tmp` 更持久的临时文件，重启后可能保留。

```bash
# 查看系统日志
ls /var/log
syslog  auth.log  kern.log  apt  nginx  ...

# Ubuntu 22.04 安装并启用 rsyslog 时，可查看传统 syslog
tail /var/log/syslog
```

并非每台系统都会生成 `/var/log/syslog`，服务也可能把日志写入 journal、专用目录或标准输出。排查时先确认目标服务采用哪种日志后端。

`/tmp` 供程序和用户存放短期临时文件，通常允许所有用户创建条目，并通过粘滞位限制普通用户删除他人的条目。系统可能在启动时或按保留期限清理它，但清理策略可以配置，因此既不能把 `/tmp` 当作持久存储，也不能假定每次重启一定清空。

```bash
ls /tmp
systemd-private-xxx  ssh-xxx  ...
```

因为其他用户也能在 `/tmp` 中创建名称，脚本不应使用可预测文件名后直接覆盖。`mktemp` 可以原子地创建当前用户拥有的临时文件或目录：

```bash
tmp_dir=$(mktemp -d) || exit 1
printf '%s\n' "$tmp_dir"
/tmp/tmp.A1b2C3d4
```

敏感数据还要设置合适权限，并在使用完后清理；仅仅调用 `mktemp` 不会自动删除内容。

`/dev` 是 “devices” 的缩写，包含由内核和设备管理器提供的设备节点及相关链接。程序可以通过文件描述符接口访问许多设备，但并非所有硬件能力都能用普通文件读写概括。磁盘名称还取决于总线和驱动：SATA 盘可能是 `/dev/sda`，NVMe 盘常见 `/dev/nvme0n1`，稳定引用磁盘时通常要查看 `/dev/disk/by-*` 下的链接。

```bash
ls /dev
sda  sda1  sda2  tty  null  zero  random  urandom  ...
```

几个常见的特殊设备节点是：

- `/dev/null`：丢弃写入的数据，读取时立即返回文件结束，常用于舍弃不需要的输出。
- `/dev/zero`：每次读取都返回零字节流，可用于需要确定填充值的测试。它生成的是零填充数据，不是“空内容”。
- `/dev/random` 和 `/dev/urandom`：Linux 内核随机数接口；现代 Linux 上的阻塞细节与旧资料可能不同，应用通常应优先使用语言或密码学库提供的安全接口。
- `/dev/ttyUSB0`：USB 转串口设备可能采用的名称；编号会随识别顺序变化，访问还受设备权限和 udev 规则约束。

```bash
# 丢弃命令的输出
command > /dev/null

# 创建一个 1 MiB 的零填充文件；若文件已存在会覆盖其开头并截断
dd if=/dev/zero of=zero-filled.bin bs=1M count=1 status=progress
```

`/proc` 是一个虚拟文件系统，不占用磁盘空间，而是提供了进程和内核信息的接口。每个运行中的进程在 `/proc` 下都有一个以进程 ID 命名的目录，包含该进程的各种信息。

```bash
ls /proc
1  2  3  ...  12345  ...  cpuinfo  meminfo  version  ...

# 查看 CPU 信息
cat /proc/cpuinfo
processor   : 0
vendor_id   : GenuineIntel
model name  : Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
...

# 查看内存信息
cat /proc/meminfo
MemTotal:       16384000 kB
MemFree:         8192000 kB
...

# cmdline 的字段以 NUL 分隔，转换后更便于阅读
tr '\0' ' ' < /proc/12345/cmdline
/usr/bin/python3 my_script.py
```

`/proc` 是 `top`、`ps` 等工具在 Linux 上使用的信息接口之一。进程可能在读取期间退出，权限设置也会隐藏部分字段，因此脚本应处理文件瞬间消失或无法读取的情况。通常先使用稳定的高层命令；只有需要相应字段时再直接读取 `/proc`。

类似地，`/sys` 是 sysfs 的常见挂载点，以较结构化的目录暴露内核对象、设备和驱动属性。部分属性只读，部分写入会立即改变设备状态；接口是否存在、可接受什么值都取决于内核和驱动。

```bash
# 查看 CPU 的在线状态
cat /sys/devices/system/cpu/online
0-7

# 查看某个背光设备当前的亮度原始值（名称因硬件而异）
cat /sys/class/backlight/intel_backlight/brightness
500
```

==== 绝对路径与相对路径

在 Linux 中定位文件有两种方式：绝对路径和相对路径。理解它们的区别对于正确使用命令行和编写脚本至关重要。

绝对路径从当前进程所见的根目录 `/` 开始，不依赖当前工作目录来解析：

```bash
/home/alice/projects/rm_vision/src/main.cpp
/etc/ssh/sshd_config
/opt/ros/humble/setup.bash
```

绝对路径能消除“相对于哪个工作目录”的歧义，但它仍可能经过符号链接，也可能因为挂载、容器或文件替换而在不同时刻指向不同对象。

相对路径从当前工作目录出发，描述如何到达目标文件。它不以 `/` 开头。

```bash
# 假设当前目录是 /home/alice/projects/rm_vision
ls src/main.cpp          # 相对路径
ls ./src/main.cpp        # 同上，./ 表示当前目录
ls ../rm_control/        # 上级目录的 rm_control
```

相对路径更简短，但它的含义取决于当前目录。同样是 `src/main.cpp`，在不同的目录下指向不同的文件。

脚本不能默认调用者总在某个目录中运行。解决方法可以是接收路径参数、明确切换到工作目录，或根据脚本自身位置构造资源路径；把开发机上的绝对路径写死到脚本中虽然避开了当前目录问题，却会降低可迁移性。采用哪种方式取决于路径是系统固定位置、用户输入，还是项目内资源。

==== 特殊路径符号

Shell 提供了几个特殊的路径符号，让路径表示更加简洁。

`.`（单个点）表示当前目录。作为普通路径参数时，`./file` 和 `file` 通常解析到同一条目；但它们位于命令名位置时规则不同。命令名不含斜杠，Shell 就按函数、内置命令和 PATH 等规则查找；包含斜杠的 `./my_program` 则明确按路径执行：

```bash
# 执行当前目录下的程序
./my_program

# 默认 PATH 通常不含当前目录，因此这里一般找不到 ./my_program
my_program
```

不把 `.` 放入 PATH 前部，可以降低当前目录中的同名文件抢先覆盖常用命令的风险；这也是 Ubuntu 默认要求显式写 `./` 的主要背景。如果用户自行把当前目录加入 PATH，`my_program` 仍可能被找到，所以“必须”并不是语法层面的绝对规则。

`..`（两个点）表示父目录（上级目录）。可以链式使用：

```bash
pwd
/home/alice/projects/rm_vision/src

cd ..
pwd
/home/alice/projects/rm_vision

cd ../..
pwd
/home/alice/projects
```

位于一个 Shell 单词开头且未被引号抑制时，`~` 会由 Bash 展开为当前用户的家目录：

```bash
echo ~
/home/alice

cd ~/projects
pwd
/home/alice/projects

# 存在该账户时，也可以展开其他用户的家目录位置
echo ~bob
/home/bob
```

展开出路径不代表当前用户一定有权进入。写成 `"~"` 时波浪号不会展开，而变量形式通常写作 `"$HOME"`。

`-` 作为 `cd` 的参数时会使用 `OLDPWD`，通常表示上一个工作目录，因而可以在两个位置之间切换：

```bash
cd /var/log
cd ~/projects
cd -         # 回到 /var/log
cd -         # 回到 ~/projects
```

这些符号可以组合使用：

```bash
ls ~/projects/../Documents    # 等价于 ls /home/alice/Documents
cd ~/.config                  # 进入配置目录
```

==== 文件类型

Linux 文件系统中不只有普通文件和目录。下面是几类条目的示意输出；`ls -l` 权限字段的第一个字符表示这里讨论的类型：

```text
drwxr-xr-x   2 user user  4096 Jan 15 10:00 example-dir
-rw-r--r--   1 user user   220 Jan 15 10:00 example.txt
lrwxrwxrwx   1 user user    11 Jan 15 10:00 example-link -> example.txt
crw-rw-rw-   1 root root 1,  3 Jan 15 10:00 /dev/null
brw-rw----   1 root disk 8,  0 Jan 15 10:00 /dev/sda
srwxrwxrwx   1 root root     0 Jan 15 10:00 /run/docker.sock
prw-r--r--   1 root root     0 Jan 15 10:00 /tmp/mypipe
```

这只是把不同类型放在一起展示；实际机器上的磁盘、套接字和命名管道名称可能不同。

让我们逐一了解每种类型。

普通文件（`-`）可以保存文本、机器码、图片或其他字节。Linux 上的文件扩展名主要是命名约定，桌面应用仍可能用它选择打开方式；内核执行程序时会识别 ELF 格式或脚本的 shebang，并不是由一个统一机制替所有文件判型。`file` 命令会结合内容特征、魔数数据库和其他规则给出推测：

```bash
# file 命令可以检测文件的实际类型
file main.cpp
main.cpp: C++ source, ASCII text

file /bin/ls
/bin/ls: ELF 64-bit LSB pie executable, x86-64, ...

file photo.jpg
photo.jpg: JPEG image data, JFIF standard 1.01, ...
```

目录（`d`）保存名称与文件系统对象之间的关联，使路径可以逐级解析。inode 是常见 Unix 文件系统采用的数据结构，但具体磁盘格式由文件系统实现决定；应用不应把目录当作普通字节文件直接读写。

符号链接（`l`），也叫软链接，保存另一个路径。路径解析通常会继续访问它的目标，因此可以用短名称引用文件或目录，也可以跨文件系统。它与 Windows 快捷方式有便于跳转的相似之处，但解析机制和支持它的程序行为并不完全相同。

```bash
# 仅在 ~/ros 尚不存在时创建符号链接
ln -s /opt/ros/humble ~/ros

# 现在 ~/ros 指向 /opt/ros/humble
ls -l ~/ros
lrwxrwxrwx 1 alice alice 15 Jan 15 10:00 /home/alice/ros -> /opt/ros/humble

# 访问链接就像访问原始目录
ls ~/ros/setup.bash
/home/alice/ros/setup.bash
```

符号链接可以为常用长路径提供短名称，也可以让一个约定位置指向当前使用的版本。如果目标移动或删除，链接会变成悬空链接；相对链接还要以链接所在目录为基准解析。修改或删除链接时需分清操作针对链接本身还是其目标，尤其不要在未核对路径的情况下把递归删除命令与目录链接组合。

硬链接是在同一文件系统中为同一文件对象增加另一个目录项。创建后不存在由系统标记的“原文件名”和“副本名”；删除其中一个名称，只要仍有其他硬链接或进程打开该文件，文件内容就不会因此消失。普通用户通常不能为目录创建硬链接，硬链接也不能跨文件系统。

```bash
# 创建硬链接（不带 -s 选项）
ln original.txt hardlink.txt

# 两个名称指向同一个 inode
ls -li original.txt hardlink.txt
12345678 -rw-r--r-- 2 alice alice 100 Jan 15 10:00 original.txt
12345678 -rw-r--r-- 2 alice alice 100 Jan 15 10:00 hardlink.txt
```

注意 inode 号（12345678）相同，链接计数（第三列的 2）表示有两个名称指向这个文件。

字符设备（`c`）和块设备（`b`）是设备节点。字符设备提供字节流式接口，如终端和串口；块设备支持按块访问，如磁盘。它们通常位于 `/dev` 并由系统管理，读写仍受权限、驱动语义和设备状态约束。

Unix 域套接字（`s`）和命名管道（`p`）可为本机进程间通信提供文件系统名称。套接字可以采用流式或数据报等语义，命名管道传输先进先出的字节流；能否连接和发送数据也由目录及节点权限控制。`/run/docker.sock` 是常见套接字示例，获得其访问权通常等同于能够向 Docker 守护进程发出高权限操作，不能把它当作普通共享文件随意放宽权限。

==== 隐藏文件

在 Linux 中，文件名以点（`.`）开头的文件被视为隐藏文件。这不是一个特殊的文件属性，仅仅是命名约定——`ls` 默认不显示这些文件，但加上 `-a` 选项就会显示。

```bash
ls
Documents  Downloads  Pictures

ls -a
.  ..  .bashrc  .config  .local  .ssh  Documents  Downloads  Pictures
```

隐藏文件主要用于存储配置和状态信息，避免在日常浏览时造成视觉干扰。用户家目录下通常有大量隐藏文件和目录，每个应用程序都可能创建自己的配置目录。

一些重要的隐藏文件和目录包括：

`~/.bashrc` 是 Bash 的用户配置文件，通常由交互式非登录 Bash 读取，可以在其中设置交互环境变量、别名和提示符。登录 Shell、非交互脚本及其他 Shell 读取的文件不同，因此不能假定任何 Bash 进程都会自动执行它。

```bash
# 查看 .bashrc 的内容
cat ~/.bashrc

# 常见的自定义内容
export PATH="/opt/myprogram/bin:$PATH"
alias ll='ls -alF'
alias gs='git status'
```

修改 `.bashrc` 后，可以打开新终端验证；也可以先检查语法和内容，再用 `source ~/.bashrc` 在当前 Bash 中执行。`source` 会运行文件里的所有命令，不应对来源不明的配置文件直接使用。

`~/.bash_history` 通常保存 Bash 写入磁盘的部分命令历史。是否记录、何时写入、忽略哪些命令以及保留多少条都可以配置；当前会话用上箭头看到的记录还不一定已经写进文件。

`~/.ssh/` 常用于保存 SSH 的用户配置、主机密钥记录和密钥对。新生成的密钥可能名为 `id_ed25519`，也可能按用途使用自定义名称；`known_hosts` 记录服务器主机密钥，`config` 可以定义连接参数。私钥不得分享，公钥则用于部署到需要登录的账户。

```bash
ls -la ~/.ssh
-rw-------  1 alice alice  411 Jan 15 10:00 id_ed25519       # 私钥，必须保密
-rw-r--r--  1 alice alice   99 Jan 15 10:00 id_ed25519.pub   # 公钥，按用途分发
-rw-r--r--  1 alice alice 1234 Jan 15 10:00 known_hosts
-rw-r--r--  1 alice alice  200 Jan 15 10:00 config
```

`~/.config/` 是现代应用程序存放配置的标准位置，遵循 XDG Base Directory 规范。很多程序会在这里创建自己的子目录，如 `~/.config/Code/`（VS Code）、`~/.config/nvim/`（Neovim）。

`~/.local/` 存储用户级的数据和程序。`~/.local/bin/` 可以放置用户自己的可执行文件，很多用户会把这个目录加入 PATH。`~/.local/share/` 存储应用程序的数据。

```bash
# ~/.local/bin 存在时，在 .bashrc 中加入一次
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
```

`~/.cache/` 按 XDG 约定存放非必要缓存，规范上应用应能在缓存丢失后继续运行。不过正在运行的程序、权限错误或不遵守约定的软件仍可能带来例外。空间不足时，应先用磁盘占用工具确认具体子目录，关闭相关程序，并按应用文档清理，而不是把“cache”名称视为无条件递归删除的许可。

现在可以把常见路径与用途联系起来：系统配置通常在 `/etc`，用户项目在家目录，许多日志位于 `/var/log` 或 journal，设备节点位于 `/dev`，ROS 2 Humble 的发行版环境位于 `/opt/ros/humble`。这些是定位问题的起点，而不是无需核对的固定答案。下一节将在这套目录结构上练习导航、查看、复制、移动和查找，并把每条命令的实际作用范围说清楚。


=== 文件与目录操作
// 日常文件管理命令
// - 导航：pwd, cd
// - 查看：ls, ls -la, tree
// - 创建：touch, mkdir, mkdir -p
// - 复制移动删除：cp, mv, rm（rm -rf 的危险）
// - 查看文件内容：cat, less, head, tail, tail -f
// - 查找文件：find, locate, which
// - 文件信息：file, stat, du, df
// - 链接：ln, ln -s
// - 压缩解压：tar, gzip, zip
// === 文件与目录操作

知道常见目录的用途后，下一步是准确地导航和操作。本节按“确认位置 → 查看内容 → 创建与复制 → 查找与归档”的顺序展开。示例既说明正常结果，也会标出覆盖、递归和路径展开等风险；练习修改性命令时，请使用自己新建的测试目录，不要直接套用到项目或系统目录。

==== 目录导航

在命令行中工作，首先要知道自己在哪里，然后才能去想去的地方。

`pwd`（print working directory）显示当前工作目录。默认输出通常保留 Shell 维护的逻辑路径；若路径经过符号链接，`pwd -P` 可以显示解析链接后的物理路径：

```bash
pwd
/home/alice/projects/rm_vision
```

在复制、移动或删除前执行一次 `pwd`，可以避免把相对路径作用到错误目录；还应继续核对目标参数，不能把位置确认等同于操作安全。

`cd`（change directory）用于切换当前工作目录。它是最常用的命令之一：

```bash
# 切换到指定目录（绝对路径）
cd /usr/local/bin

# 切换到指定目录（相对路径）
cd src/detector

# 回到家目录
cd ~
cd          # 不带参数也会回到家目录

# 回到上级目录
cd ..

# 回到上两级目录
cd ../..

# 回到上一个工作目录
cd -
/home/alice/projects  # 显示切换到的目录
```

RoboMaster 开发中经常要在 ROS 2 工作空间、源码目录和构建目录之间切换。例如下面每一步都以前一步成功为前提；交互使用时若 `cd` 报错，应先停止并检查，脚本中则要显式处理失败：

```bash
cd ~/ros2_ws           # 进入工作空间
cd src/rm_vision       # 进入包的源码
cd ../../build         # 去构建目录查看编译产物
cd -                   # 回到刚才的 src/rm_vision
```

Tab 补全可以减少长目录名的输入量。例如输入 `cd ~/pro<Tab>`，在只有一个匹配项时可能补全为 `cd ~/projects/`。有多个候选项时先查看列表，不能假定补全一定选择预期目录。

==== 查看目录内容

`ls`（list）面向人类列出目录内容。其颜色、时间格式和排序会受选项、别名、终端与区域设置影响，脚本需要稳定处理文件名时不应解析 `ls` 的显示文本。

```bash
# 列出当前目录的内容
ls
CMakeLists.txt  include  src  test  README.md

# 列出指定目录的内容
ls /usr/bin

# 列出多个目录的内容
ls src include
```

最常用的选项组合是 `-la`，它显示详细信息（`-l`）并包含隐藏文件（`-a`）：

```bash
ls -la
total 32
drwxr-xr-x  6 alice alice 4096 Jan 15 10:00 .
drwxr-xr-x 12 alice alice 4096 Jan 15 09:00 ..
-rw-r--r--  1 alice alice 1234 Jan 15 10:00 CMakeLists.txt
drwxr-xr-x  2 alice alice 4096 Jan 15 10:00 .git
-rw-r--r--  1 alice alice  567 Jan 15 10:00 .gitignore
drwxr-xr-x  3 alice alice 4096 Jan 15 10:00 include
-rw-r--r--  1 alice alice  890 Jan 15 10:00 README.md
drwxr-xr-x  4 alice alice 4096 Jan 15 10:00 src
drwxr-xr-x  2 alice alice 4096 Jan 15 10:00 test
```

让我们解读这个输出。每行代表一个文件或目录，列的含义是：

1. 文件类型和权限（`drwxr-xr-x`）：第一个字符是类型（`d` 目录，`-` 普通文件，`l` 链接），后面九个字符是权限
2. 硬链接数（`6`）
3. 所有者（`alice`）
4. 所属组（`alice`）
5. 条目本身的大小（字节）（`4096`）；目录这一列不是其全部内容占用
6. 最后修改时间（`Jan 15 10:00`）
7. 文件名（`src`）

其他有用的 `ls` 选项：

```bash
# -h 人类可读的文件大小（KB、MB、GB）
ls -lh
-rw-r--r-- 1 alice alice 1.2K Jan 15 10:00 CMakeLists.txt
-rw-r--r-- 1 alice alice 156M Jan 15 10:00 model.onnx

# -t 按修改时间排序（最新的在前）
ls -lt

# -S 按文件大小排序（最大的在前）
ls -lS

# -r 反向排序
ls -ltr   # 按时间排序，最旧的在前

# -R 递归列出子目录
ls -R

# --color=auto 仅在输出到终端时添加颜色（Ubuntu 常通过别名启用）
ls --color=auto
```

很多用户会在 `.bashrc` 中定义别名来简化常用的 `ls` 命令：

```bash
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
```

`tree` 命令按层级显示目录，适合浏览项目结构。Ubuntu 的最小安装不一定包含它，可以通过已配置的软件源安装：

```bash
sudo apt install tree

tree
.
├── CMakeLists.txt
├── include
│   └── rm_vision
│       ├── detector.hpp
│       └── tracker.hpp
├── README.md
├── src
│   ├── detector.cpp
│   ├── main.cpp
│   └── tracker.cpp
└── test
    └── test_detector.cpp

4 directories, 8 files
```

`tree` 的一些有用选项：

```bash
# -L 限制显示深度
tree -L 2

# -d 只显示目录
tree -d

# -I 排除匹配模式的文件
tree -I 'build|__pycache__'

# --dirsfirst 目录排在前面
tree --dirsfirst
```

==== 创建文件与目录

`touch` 在目标不存在时创建空的普通文件；目标已经存在时默认更新访问和修改时间，不会清空原内容：

```bash
# 创建空文件
touch newfile.txt
ls -l newfile.txt
-rw-r--r-- 1 alice alice 0 Jan 15 10:00 newfile.txt

# 创建多个文件
touch file1.txt file2.txt file3.txt

# 如果文件已存在，更新其修改时间
touch existingfile.txt
```

`touch` 主要用于快速创建空文件。如果你需要创建有内容的文件，通常会用重定向或编辑器：

```bash
# 用重定向创建有内容的文件
echo "Hello, World!" > hello.txt

# 用 cat 和带引号的 heredoc 创建字面量多行文件
cat > config.txt <<'EOF'
setting1=value1
setting2=value2
EOF
```

这里的 `>` 会覆盖已有 `config.txt`。`<<'EOF'` 中给定界定词加引号，可以阻止正文里的变量、命令替换和反斜杠被 Shell 展开；需要有意展开时再使用未加引号的形式。

`mkdir`（make directory）创建目录：

```bash
# 创建单个目录
mkdir myproject

# 创建多个目录
mkdir dir1 dir2 dir3

# -p 创建多级目录（父目录不存在时自动创建）
mkdir -p projects/rm_vision/src/detector

# 不加 -p 时，如果父目录不存在会报错
mkdir projects/newproject/src
mkdir: cannot create directory 'projects/newproject/src': No such file or directory
```

`-p` 可以一次创建缺失的父目录；目标目录已经存在时也不把“已存在”作为错误。它仍可能因同名普通文件、权限不足或只读文件系统而失败，脚本必须检查退出状态，不能把静默处理已有目录理解为无条件成功。

创建 RoboMaster 项目的典型目录结构：

```bash
mkdir -p rm_vision/{include/rm_vision,src,test,config,launch,models}
tree rm_vision
rm_vision
├── config
├── include
│   └── rm_vision
├── launch
├── models
├── src
└── test
```

这里使用了 Bash 的花括号展开功能，`{a,b,c}` 会展开为 `a b c`。

==== 复制、移动与删除

`cp`（copy）复制文件或目录：

```bash
# 复制文件
cp source.txt destination.txt

# 复制文件到目录
cp file.txt /path/to/directory/

# 复制多个文件到目录
cp file1.txt file2.txt file3.txt /path/to/directory/

# -r 或 -R 递归复制目录（复制目录必须加此选项）
cp -r src_dir dest_dir

# -i 覆盖前询问确认
cp -i source.txt existing.txt
cp: overwrite 'existing.txt'? 

# -v 显示复制过程（verbose）
cp -rv project/ backup/
'project/src/main.cpp' -> 'backup/src/main.cpp'
'project/include/header.h' -> 'backup/include/header.h'
...

# -p 保留文件属性（时间戳、权限等）
cp -p important.txt backup.txt

# GNU cp 的 -a 归档模式会递归复制并尽量保留链接和属性
cp -a project/ project_backup/
```

如果目标文件已经存在，`cp` 默认会覆盖其内容；目标是目录时，源文件会复制到目录内部。`-i` 只在交互会话中提供逐次确认，不适合当作脚本的唯一保护。`-p` 和 `-a` 对所有者、扩展属性等信息的保留还会受当前权限和目标文件系统能力限制。重要复制完成后，应检查退出状态，并按目的核对文件清单、大小或校验值。

`mv`（move）移动文件或目录，也用于重命名：

```bash
# 移动文件
mv file.txt /path/to/directory/

# 移动并重命名
mv oldname.txt /path/to/newname.txt

# 重命名（同一目录内移动）
mv oldname.txt newname.txt

# 移动目录（不需要 -r）
mv mydir /path/to/destination/

# -i 覆盖前询问
mv -i source.txt existing.txt

# -v 显示移动过程
mv -v *.cpp src/
'main.cpp' -> 'src/main.cpp'
'detector.cpp' -> 'src/detector.cpp'
```

同一文件系统内的常规移动通常可由重命名目录项完成，不需要复制文件内容，并可在相应条件下原子替换目标名称。跨文件系统时，GNU `mv` 通常退化为复制后删除源文件，耗时、空间需求和中断后的状态都不同。无论哪种情况，目标同名文件都可能被替换；重要操作可先使用 `-i`，或把新名称放到尚不存在的位置再核对。

`rm`（remove）从文件系统中移除名称，默认不会经过桌面回收站。若文件仍被进程打开，其存储可能在最后一个引用关闭后才释放；这不构成可依赖的恢复方法。下面只在专门创建的练习目录中演示：

```bash
# 建立可丢弃的练习数据
mkdir practice-delete
touch practice-delete/old.log practice-delete/debug.log

# 先显示同一模式实际匹配的路径
printf '%s\n' practice-delete/*.log

# -i 删除前询问确认
rm -i -- practice-delete/*.log
rm: remove regular empty file 'practice-delete/old.log'? y
rm: remove regular empty file 'practice-delete/debug.log'? y

# 目录为空后，用受限的 rmdir 删除它
rmdir -- practice-delete
```

`-r` 会递归处理目录，`-f` 会忽略不存在的目标并取消大部分确认；两者组合后，一处路径、变量或通配符错误就可能扩大到整棵目录。常见事故不是命令“随机失控”，而是当前目录与预期不同、变量为空或未加引号、模式展开范围过大、把根或家目录当成目标，以及不必要地用管理员权限执行。GNU `rm` 的部分保护只能拦住少数根目录写法，不能验证你的业务意图。

执行不可恢复的递归删除前，至少完成以下检查：

1. 用 `pwd` 和 `realpath` 核对起点及目标，不只看目标名称。
2. 先用 `printf`、`find` 或其他只读命令显示完全相同的参数集合；注意 `*` 默认不含隐藏条目。
3. 给变量展开加双引号，在脚本中拒绝空值，并验证解析后的目标确实位于允许的专用目录下。
4. 去掉不必要的 `sudo` 和 `-f`，优先使用 `-i`、空目录专用的 `rmdir`，或工具自身提供的清理子命令。
5. 确认重要内容已有可恢复且验证过的备份；“我应该没有选错”不能替代恢复方案。

桌面环境中还可以使用 `gio trash -- 文件名`，或安装 `trash-cli` 后使用其命令，把支持该机制的文件系统上的条目移入回收站。远程文件系统、容器和某些挂载点不一定支持回收站，回收站也会被清空，因此它只是额外缓冲，不是备份。

`rmdir` 只删除空目录，作用范围比递归删除窄：

```bash
rmdir empty_dir             # 成功删除空目录
rmdir non_empty_dir
rmdir: failed to remove 'non_empty_dir': Directory not empty
```

==== 查看文件内容

有多种命令可以查看文件内容，适用于不同的场景。

`cat`（concatenate）将文件内容输出到终端，适合查看小文件：

```bash
# 查看文件内容
cat config.yaml
setting1: value1
setting2: value2

# 查看多个文件（连接输出）
cat file1.txt file2.txt

# -n 显示行号
cat -n script.sh
     1  #!/bin/bash
     2  echo "Hello"
     3  exit 0

# 将多个文件合并为一个
cat part1.txt part2.txt part3.txt > combined.txt
```

对较大的文本文件，`cat` 会持续输出直到结束，不便于停留查看；对二进制文件还可能向终端写入控制字节。这时应使用分页器或针对格式的查看工具。

`less` 是一个分页查看器，可以前后滚动浏览大文件：

```bash
less largefile.log
```

在 `less` 中的操作：
- 空格或 `f`：向下翻页
- `b`：向上翻页
- `j` 或 ↓：向下一行
- `k` 或 ↑：向上一行
- `g`：跳到文件开头
- `G`：跳到文件末尾
- `/pattern`：向下搜索 pattern
- `?pattern`：向上搜索 pattern
- `n`：跳到下一个搜索结果
- `N`：跳到上一个搜索结果
- `q`：退出

读取普通文件时，`less` 可以按需定位和显示内容，不要求先把整个文件载入内存，因此适合浏览较大日志。若输入来自管道，它可能需要缓存已经读取的数据，行为和资源需求与直接打开普通文件不同。

`more` 是另一种分页器，功能通常少于 `less`，但某些精简系统可能只提供它。具体按键和实现差异可查看本机手册。

`head` 显示文件的开头部分，默认前 10 行：

```bash
# 显示前 10 行
head file.txt

# 显示前 20 行
head -n 20 file.txt

# 显示前 n 个字节
head -c 100 file.txt
```

`tail` 显示文件的末尾部分，默认最后 10 行：

```bash
# 显示最后 10 行
tail file.txt

# 显示最后 20 行
tail -n 20 file.txt

# -f 实时追踪文件更新（follow）
tail -f /var/log/syslog
```

`tail -f` 会保持运行并显示随后追加的内容，适合观察正在写入的日志：

```bash
# 在一个终端中运行程序
./my_program

# 在另一个终端中监控日志
tail -f ~/my_program.log
```

按 `Ctrl+C` 停止 `tail -f`。

日志轮转后，原路径可能指向一个新文件；GNU `tail -F` 会按名称重试并处理常见的文件替换情形。它仍不保证日志完整到达，也不能代替检查程序和管道的退出状态。

组合使用这些命令可以完成更复杂的任务：

```bash
# 查看文件的第 11-20 行
head -n 20 file.txt | tail -n 10

# 实时监控日志，只显示包含 "error" 的行
tail -f app.log | grep error
```

最后一种“从 `ls` 取第一个名称再交给 `xargs`”的常见写法没有列在示例中，因为空目录、空格和换行文件名都会让它产生歧义。需要脚本化选择文件时，应使用能提供 NUL 分隔输出的查找接口，并明确无结果时的行为。

==== 查找文件

不知道路径或需要按条件筛选一批文件时，可以使用 `find` 或基于索引的 `locate`。查找本身是只读操作，把结果继续交给删除或修改命令则需要单独核对。

`find` 可以遍历指定起点，并按名称、类型、大小、时间等条件筛选路径：

```bash
# 按名称查找（在当前目录及子目录中）
find . -name "*.cpp"
./src/main.cpp
./src/detector.cpp
./test/test_detector.cpp

# 在指定目录中查找
find /home/alice/projects -name "CMakeLists.txt"

# -iname 忽略大小写
find . -iname "readme*"

# 按类型查找：f 文件，d 目录，l 链接
find . -type f -name "*.hpp"    # 只找文件
find . -type d -name "build"    # 只找目录

# 按大小查找；c 表示字节，M 以 MiB 为单位并按单位向上取整
find . -size +100M              # 按 find 的 MiB 单位计数大于 100
find . -size -1024c             # 小于 1024 字节的文件

# 按时间查找：-mtime 修改时间，-atime 访问时间
find . -mtime -7                # 以整 24 小时区间计算，匹配值小于 7
find . -mtime +30               # 匹配值大于 30，不等于精确日历日期

# 组合条件
find . -name "*.log" -size +10M -mtime +7

# -exec 对找到的文件执行命令；-- 防止以连字符开头的名称成为选项
find . -type f -name "*.cpp" -exec wc -l -- {} \;
```

多个条件默认按逻辑“与”组合，所以类型、名称和大小条件的顺序虽不一定改变集合，却可能影响求值和副作用。`-exec` 中的 `{}` 是当前路径占位符，`\;` 结束这项动作并为每个结果调用一次命令。用 `+` 结束时，`find` 会在参数长度允许范围内批量传入多个路径，减少进程启动次数：

```bash
find . -name "*.cpp" -exec wc -l -- {} +
```

GNU `find` 还有 `-delete`，但它会在遍历时立即修改目录树，并影响遍历深度。不要把只读预览中的 `-print` 机械替换为 `-delete`；应先固定搜索根、加入 `-type` 等约束、检查完整结果，再决定是否用项目构建工具的清理命令或受控删除。

`locate` 使用预建的数据库来查找文件，比 `find` 快得多，但可能不是最新的：

```bash
# Ubuntu 22.04 可安装 plocate，它提供 locate 与 updatedb
sudo apt install plocate

# 更新数据库（需要 sudo）
sudo updatedb

# 查找文件
locate opencv.hpp
/usr/include/opencv4/opencv2/opencv.hpp

# -i 忽略大小写
locate -i readme

# 只计数，不显示结果
locate -c "*.py"
```

`locate` 适合快速查找索引中已有的路径，但索引的更新时间由本机定时任务和配置决定，刚创建或已经删除的路径都可能与结果不一致。需要时可运行 `sudo updatedb` 重建系统数据库，但大型文件系统会消耗时间和 I/O；查找当前项目通常直接用 `find` 更合适。共享机器上还要注意索引工具的隐私与权限配置。

`command -v` 可以按当前 Shell 的解析规则查看一个命令名：

```bash
command -v python3
/usr/bin/python3

command -v gcc
/usr/bin/gcc

command -v ros2
/opt/ros/humble/bin/ros2
```

外部 `which` 主要搜索 PATH，不一定反映别名、函数、内置命令和 Shell 的其他解析细节。Bash 的 `type -a 名称` 可以列出多种候选，`command -v` 适合脚本检查名称是否可解析；若名称被哈希或运行环境随后改变，检查结果也不构成未来执行目标不变的保证。`whereis` 则按自己的数据库和固定位置查找二进制、源码或手册。

==== 文件信息

有时你需要了解文件的更多信息，而不仅仅是内容。

`file` 根据内容特征、魔数数据库和部分上下文推测文件类型，不只看扩展名：

```bash
file main.cpp
main.cpp: C++ source, UTF-8 Unicode text

file /bin/ls
/bin/ls: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, ...

file image.png
image.png: PNG image data, 1920 x 1080, 8-bit/color RGBA, non-interlaced

file model.onnx
model.onnx: data

file archive.tar.gz
archive.tar.gz: gzip compressed data, ...
```

这在处理没有扩展名或扩展名错误的文件时很有用，但输出可能只是宽泛的 `data`，也不能证明文件内容安全或格式完全有效。

`stat` 显示文件的详细元数据：

```bash
stat README.md
  File: README.md
  Size: 1234            Blocks: 8          IO Block: 4096   regular file
Device: 801h/2049d      Inode: 1234567     Links: 1
Access: (0644/-rw-r--r--)  Uid: ( 1000/   alice)   Gid: ( 1000/   alice)
Access: 2024-01-15 10:00:00.000000000 +0800
Modify: 2024-01-15 09:30:00.000000000 +0800
Change: 2024-01-15 09:30:00.000000000 +0800
 Birth: 2024-01-10 08:00:00.000000000 +0800
```

这显示了逻辑大小、已分配块、inode 号、权限、所有者以及访问、内容修改和元数据改变时间。`Change` 不是文件内容的“创建时间”；单独的 `Birth` 字段才表示创建时间，而且文件系统、内核或工具不支持时可能为空。挂载选项还可能延迟或省略访问时间更新。

`du`（disk usage）汇总路径在文件系统中已分配的空间。稀疏文件、压缩、硬链接、权限不足和文件系统元数据都会使它与文件逻辑大小或 `df` 的数字不同：

```bash
# 显示当前目录的大小
du -sh .
256M    .

# 显示通配符匹配到的非隐藏子目录大小
du -sh */
12M     build/
4.0K    config/
8.0K    include/
200M    models/
32M     src/

# 显示所有文件和目录的大小
du -ah

# 找出最大的目录
du -sh */ | sort -rh | head -5

# -d 限制深度
du -h -d 1
```

`-s` 表示汇总（summary），只显示总大小；`-h` 表示人类可读格式。

`df`（disk free）显示文件系统的磁盘空间使用情况：

```bash
df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   45G   50G  48% /
/dev/sda2       500G  200G  275G  43% /home
tmpfs           7.8G     0  7.8G   0% /dev/shm
```

`df` 报告文件系统整体的块和 inode 使用情况，`du` 从可遍历的目录项累计特定路径。已删除但仍被进程打开的文件、保留块、快照和不可访问目录都可能造成两者不一致。空间不足时，可以先用 `df -h /目标路径` 和 `df -i /目标路径` 确认对应文件系统及 inode，再在有权限的明确目录中用 `du` 缩小范围；不要从根目录无差别扫描并删除最大的条目。

==== 创建链接

链接让一个文件可以有多个名称或路径。我们在上一节介绍了链接的概念，这里讲解如何创建它们。

`ln`（link）命令创建链接，默认创建硬链接，加 `-s` 选项创建符号链接（软链接）：

```bash
# 目标名称 ~/ros 必须尚不存在
ln -s /opt/ros/humble ~/ros

# 验证链接
ls -l ~/ros
lrwxrwxrwx 1 alice alice 15 Jan 15 10:00 /home/alice/ros -> /opt/ros/humble

# 现在可以用 ~/ros 代替 /opt/ros/humble
source ~/ros/setup.bash
```

符号链接的常见用途：

```bash
# 为常用的长路径创建短名称
ln -s ~/projects/robomaster_vision_2024 ~/rmv

# 为当前配置建立符号链接
ln -s config_competition.yaml config.yaml
```

切换链接前，先用 `readlink -- config.yaml` 和 `ls -l -- config.yaml` 确认它确实是允许替换的链接，再删除该链接名称并创建新的目标。`ln -sf` 会强制处理已存在目标，遇到真实配置文件或指向目录的链接时容易掩盖意图，因此不把它作为初学者的快捷切换方案。系统级库和 CUDA 路径应按发行版或厂商的安装方法配置，也不应为“让程序找到库”随意在 `/usr/local` 建立带 `sudo` 的链接。

创建硬链接（不常用，但有时有用）：

```bash
# 创建硬链接
ln original.txt hardlink.txt

# 两个文件共享相同的内容
echo "new content" >> original.txt
cat hardlink.txt
... 新内容也出现 ...
```

普通用户通常不能为目录建立硬链接，硬链接也不能跨文件系统；符号链接没有这两项限制，但会受到目标移动、相对路径基准和悬空链接的影响。选择链接类型应依据是否需要共享同一个文件对象，不能只按哪一种“更方便”决定。

==== 压缩与解压

下载源码、传递数据和制作阶段性备份时，经常会遇到归档与压缩。归档负责把多条路径及部分元数据放进一个文件，压缩负责减少字节数；两者可以组合，但不是同一个概念。

`tar`（tape archive）创建或读取归档，并可调用 gzip、bzip2、xz 等压缩方式：

```bash
# 创建归档（不压缩）
tar cvf archive.tar dir/
# c = create 创建
# v = verbose 显示过程
# f = file 指定文件名

# 创建 gzip 压缩的归档
tar cvzf archive.tar.gz dir/
# z = gzip 压缩

# 创建 bzip2 压缩的归档
tar cvjf archive.tar.bz2 dir/
# j = bzip2 压缩

# 创建 xz 压缩的归档
tar cvJf archive.tar.xz dir/
# J = xz 压缩
```

解压归档：

```bash
# 解压 tar.gz
tar xvzf archive.tar.gz
# x = extract 解压

# 解压 tar.bz2
tar xvjf archive.tar.bz2

# 解压 tar.xz
tar xvJf archive.tar.xz

# 查看归档内容（不解压）
tar tvf archive.tar.gz
# t = list 列出内容

# 在确认清单后，解压到新建的专用目录
mkdir extracted
tar xvf archive.tar.gz -C extracted/
```

本书 Ubuntu 上的 GNU tar 解压时可以根据归档识别常见压缩格式，所以读取时通常可省略 `z`、`j`、`J`：

```bash
tar xvf archive.tar.gz      # 自动检测 gzip
tar xvf archive.tar.xz      # 自动检测 xz
```

归档中的路径、符号链接、权限和同名文件都可能影响解压结果。对外部归档，应先用 `tar tf` 查看清单，在普通用户拥有的新目录中解压，避免对不可信归档使用 `sudo`，并在运行其中的程序前继续检查来源和内容。列出清单能发现明显的绝对路径或越级路径，但本身不是恶意归档安全性的完整证明。

`gzip` 和 `gunzip` 用于压缩和解压单个文件：

```bash
# 压缩文件（原文件会被替换为 .gz 文件）
gzip largefile.log
ls
largefile.log.gz

# 解压
gunzip largefile.log.gz
# 或
gzip -d largefile.log.gz

# 保留原文件
gzip -k largefile.log

# 查看压缩文件内容（不解压）
zcat largefile.log.gz
zless largefile.log.gz     # 分页查看
zgrep "error" largefile.log.gz  # 在压缩文件中搜索
```

`zip` 和 `unzip` 处理跨平台常见的 ZIP 格式：

```bash
# 创建 zip 归档
zip -r archive.zip dir/
# -r = recursive 递归

# 解压 zip
unzip archive.zip

# 解压到指定目录
unzip archive.zip -d /path/to/destination/

# 查看 zip 内容
unzip -l archive.zip
```

不同格式可以先按生态兼容性选择，再针对实际数据测试大小与耗时：

- `.tar.gz` 或 `.tgz`：Unix/Linux 项目中常见，gzip 通常有较快的压缩与解压速度。
- `.tar.bz2` 或 `.tbz2`：使用 bzip2；对某些数据压缩得更小，但不能保证总优于 gzip。
- `.tar.xz`：使用 xz；发行包中常见，较高压缩级别可能消耗更多时间和内存。
- `.zip`：许多桌面系统原生支持，每个条目可独立压缩，便于跨平台交换。

算法、压缩级别、文件内容和实现版本都会影响结果，因此“压缩率最高”“速度最快”都不能脱离测试对象作为绝对结论。ZIP 也应先查看清单并解压到专用目录，不要直接覆盖项目文件。

在 RoboMaster 开发中，你会经常下载 `.tar.gz` 格式的源码包，备份项目时也通常用这个格式：

```bash
# 下载 OpenCV 4.8.0 源码归档并先查看清单
wget -O opencv-4.8.0.tar.gz https://github.com/opencv/opencv/archive/refs/tags/4.8.0.tar.gz
tar tf opencv-4.8.0.tar.gz | less

# 备份项目
tar czf rm_vision_backup_$(date +%Y%m%d).tar.gz rm_vision/
```

最后一个命令使用命令替换 `$(date +%Y%m%d)` 生成日期，如 `rm_vision_backup_20240115.tar.gz`。文件名相同会被覆盖，日期也不区分同一天内的多次备份；实际备份应写到独立目标，加入时间或唯一编号，检查 `tar` 的退出状态，并至少做一次清单或恢复演练。归档存在不等于备份已经可恢复。

本节把路径定位、查看、创建、复制、删除、查找和归档连成了一套基本流程。无需一次记住全部选项，但要优先记住三件事：修改前确认当前目录和展开后的目标，遇到覆盖与递归操作先做只读预览，完成复制或备份后验证结果。下一节继续处理文件内容，重点是搜索、转换与比较文本，而不是再扩大文件操作范围。


=== 文本编辑与处理
// 命令行下的文本操作
// - nano：新手友好的编辑器
// - vim：模式化终端编辑器（基础操作）
// - 文本搜索：grep, grep -r, grep -E
// - 文本处理：sed, awk 入门
// - 排序去重统计：sort, uniq, wc
// - 文本比较：diff
// === 文本编辑与处理

Linux 开发中的配置、源代码、脚本和许多日志都以文本形式保存。本节先介绍 nano 与 Vim 的基本编辑流程，再学习 grep、sed、awk、sort 和 diff。重点不是背下所有语法，而是分清哪些命令只输出结果、哪些会原地修改文件，以及正则表达式、字段分隔和文件名等输入假设。

==== nano：新手友好的编辑器

如果刚接触命令行编辑器，nano 的操作方式与常见文本框较接近，屏幕底部还会显示快捷键提示，适合完成小范围修改。

启动 nano 编辑文件：

```bash
nano filename.txt
```

如果文件不存在，nano 会创建一个新文件。打开后，你会看到一个简洁的界面：文件内容在中央，底部是快捷键提示。`^` 符号表示 Ctrl 键，所以 `^X` 表示 `Ctrl+X`。

在 nano 中，你可以直接开始输入文本，就像在普通的文本编辑器中一样。方向键移动光标，Backspace 删除字符，一切都很直观。

最常用的快捷键包括：

- `Ctrl+O`：保存文件（Write Out）。按下后会提示确认文件名，按 Enter 确认。
- `Ctrl+X`：退出 nano。如果文件有未保存的修改，会提示是否保存。
- `Ctrl+K`：剪切当前行。
- `Ctrl+U`：粘贴剪切的内容。
- `Ctrl+W`：输入文本并搜索；找到一处后，常用 `Alt+W` 重复上一次搜索。快捷键会随 nano 版本和配置略有差异，以底部提示或 `Ctrl+G` 帮助为准。
- `Ctrl+\`：搜索并替换。
- `Ctrl+G`：显示帮助信息。

一个典型的编辑流程是：打开文件，进行修改，`Ctrl+O` 保存，`Ctrl+X` 退出。如果修改后想放弃更改，直接 `Ctrl+X`，在提示保存时选择 `N`。

nano 的界面直接，适合快速修改配置或少量代码；批量重构、跨文件导航等工作则通常需要其他编辑器或 IDE。通过 SSH 修改系统配置时，编辑器本身只是一步，还要考虑权限、备份、语法检查和服务重载。

```bash
# 先在自己的练习文件上熟悉保存与退出
cp /etc/ssh/sshd_config ~/sshd_config.practice
nano ~/sshd_config.practice

# 编辑 bashrc
nano ~/.bashrc

# 快速创建并编辑新文件
nano notes.txt
```

练习副本不会改变 SSH 服务。真正修改系统配置时，应先确认服务读取的主文件和包含目录，使用 `sudoedit` 等受控方式编辑，并在重载前执行对应的配置检查；SSH 配置错误还可能切断远程连接，因此需要保留另一个已验证的登录会话或恢复入口。

==== vim：模式化终端编辑器

Vim（Vi IMproved）是采用模式化操作的文本编辑器。许多 Unix-like 环境会提供 `vi` 或某种精简实现，但不保证完整 Vim 已安装；先用 `vim --version` 或 `vi --version` 查看本机实现。掌握打开、插入、保存和退出，足以应对远程或无图形环境中的基础编辑。

vim 与其他编辑器最大的不同是它的“模式”设计。vim 有多种模式，每种模式下按键的含义不同：

- *普通模式（Normal mode）*：默认模式，用于导航和执行命令。按键是命令而不是输入字符。
- *插入模式（Insert mode）*：用于输入文本，此时 vim 表现得像普通编辑器。
- *命令行模式（Command-line mode）*：从普通模式输入 `:` 等前缀进入，用于保存、退出、替换和设置选项。
- *可视模式（Visual mode）*：用于选择文本。

启动 vim：

```bash
vim filename.txt
```

打开文件后，你处于普通模式。此时按字母键不会输入字符，而是执行命令。这是新手最困惑的地方——“我怎么什么都输入不了？”

要输入文本，需要先进入插入模式。最常用的方式是按 `i`（在光标前插入）。进入插入模式后，左下角会显示 `-- INSERT --`，此时可以正常输入文本。编辑完成后，按 `Esc` 返回普通模式。

保存和退出需要进入命令模式。在普通模式下按 `:`，左下角会出现冒号等待输入命令：

- `:w`：保存（write）
- `:q`：退出（quit）
- `:wq` 或 `:x`：保存并退出
- `:q!`：不保存强制退出（放弃所有修改）
- `:wq!`：忽略 Vim 的部分保护并尝试写入后退出；它不能绕过操作系统文件权限，也不应作为处理只读文件的通用办法。

一个最基本的 vim 使用流程：

```
vim file.txt    → 打开文件，处于普通模式
i               → 进入插入模式
(输入文本)
Esc             → 返回普通模式
:wq             → 保存并退出
```

这几个操作足以完成基本编辑。普通模式还提供移动、复制、删除与组合操作：

普通模式下的移动命令：

- `h`、`j`、`k`、`l`：左、下、上、右；多数终端也可使用方向键
- `w`：移动到下一个单词开头
- `b`：移动到上一个单词开头
- `0`：移动到行首
- `$`：移动到行尾
- `gg`：移动到文件开头
- `G`：移动到文件末尾
- `数字G`：移动到指定行，如 `10G` 跳到第 10 行

普通模式下的编辑命令：

- `x`：删除光标处的字符
- `dd`：删除（剪切）整行
- `yy`：复制整行
- `p`：粘贴到光标后
- `u`：撤销
- `Ctrl+R`：重做
- `数字+命令`：重复命令，如 `5dd` 删除 5 行

进入插入模式的多种方式：

- `i`：在光标前插入
- `a`：在光标后插入（append）
- `I`：在行首插入
- `A`：在行尾插入
- `o`：在下方新建一行并插入
- `O`：在上方新建一行并插入

搜索：

- `/pattern`：向下搜索 pattern
- `?pattern`：向上搜索
- `n`：跳到下一个匹配
- `N`：跳到上一个匹配

替换（在命令模式下）：

```vim
:s/old/new/           " 替换当前行第一个匹配
:s/old/new/g          " 替换当前行所有匹配
:%s/old/new/g         " 替换文件中所有匹配
:%s/old/new/gc        " 替换所有，每次询问确认
```

vim 的配置文件是 `~/.vimrc`，可以在这里设置各种选项：

```vim
" 显示行号
set number

" 语法高亮
syntax on

" 搜索高亮
set hlsearch

" 自动缩进
set autoindent

" Tab 宽度
set tabstop=4
set shiftwidth=4
set expandtab

" 显示光标位置
set ruler
```

Vim 的操作可以组合。例如 `d2w` 大致表示从当前位置执行两次单词移动范围的删除，`y$` 复制到行尾，`ci"` 修改双引号包围的内容。实际范围会受光标位置、`iskeyword` 等设置和文本结构影响，先在可恢复文件中练习比机械记忆结果更可靠。

即使主要使用 VS Code 或其他 IDE，掌握一种终端编辑器仍有助于处理无图形环境。Git 等工具调用哪个编辑器取决于 `GIT_EDITOR`、`core.editor`、`VISUAL`、`EDITOR` 和系统配置，不能假定一定是 Vim；需要时应提前配置并验证。

如果你想深入学习 vim，可以运行 `vimtutor` 命令，它提供了一个交互式的教程：

```bash
vimtutor
```

==== grep：按模式搜索文本

`grep` 按模式筛选输入行。其名称源自早期 ed 编辑器中用于全局搜索正则并打印的命令形式 `g/re/p`；使用时最重要的是分清字面字符串与正则表达式，并检查文件、编码和递归范围。

基本用法：

```bash
# 在文件中搜索字符串
grep "error" logfile.txt
[所有包含 error 的行]

# 在多个文件中搜索
grep "TODO" *.cpp
main.cpp:42:    // TODO: implement this
detector.cpp:100:    // TODO: optimize performance

# -i 忽略大小写
grep -i "error" logfile.txt
Error: connection failed
ERROR: timeout
error: invalid input

# -n 显示行号
grep -n "error" logfile.txt
42:error: connection failed
157:error: timeout

# -F 把模式当作普通字符串，点号、方括号等不再具有正则含义
grep -Fn "camera[0]" config.yaml
```

`-r` 让 GNU grep 递归读取目录中的文件。大型仓库中应限制文件类型并排除构建产物和版本库，以减少二进制文件提示、权限错误和无关结果：

```bash
# 在当前目录及子目录中搜索
grep -r "ArmorDetector" .
./src/detector.cpp:class ArmorDetector {
./include/detector.hpp:class ArmorDetector;
./test/test_detector.cpp:TEST(ArmorDetector, Basic) {

# -r 配合其他选项
grep -rn "ArmorDetector" src/
src/detector.cpp:15:class ArmorDetector {
src/main.cpp:42:    ArmorDetector detector;

# --include 只搜索特定类型的文件
grep -rn "TODO" --include="*.cpp" --include="*.hpp" .

# --exclude 排除特定文件
grep -rn "password" --exclude="*.log" .

# --exclude-dir 排除目录
grep -rn "config" --exclude-dir=build --exclude-dir=.git .
```

上下文显示让你能看到匹配行的周围内容：

```bash
# -B 显示匹配行之前的 n 行（Before）
grep -B 2 "error" logfile.txt

# -A 显示匹配行之后的 n 行（After）
grep -A 3 "error" logfile.txt

# -C 显示前后各 n 行（Context）
grep -C 2 "error" logfile.txt
```

反向匹配显示不包含模式的行：

```bash
# -v 反向匹配
grep -v "debug" logfile.txt      # 显示不含 debug 的行

# 排除注释行
grep -v "^#" config.txt          # ^ 表示行首
grep -v "^//" code.cpp
```

grep 默认使用基本正则表达式，`-E` 启用扩展正则表达式。旧资料中的 `egrep` 等价形式已经不建议用于新脚本：

```bash
# 基本正则表达式
grep "error.*failed" logfile.txt   # . 匹配任意字符，* 匹配零个或多个

# -E 扩展正则表达式
grep -E "error|warning|fatal" logfile.txt  # | 表示或
grep -E "[0-9]{3}\.[0-9]{3}" data.txt      # 匹配 xxx.xxx 格式的数字

# 常用正则模式
grep "^#" config.txt       # 以 # 开头的行
grep "\.cpp$" filelist     # 以 .cpp 结尾的行
grep "^$" file.txt         # 空行
grep -v "^$" file.txt      # 非空行
```

grep 经常与其他命令通过管道组合使用：

```bash
# 按完整命令行查找名称或参数中含 python 的进程
pgrep -af python
12345 python3 app.py

# 在当前可见历史中搜索；输出可能包含敏感参数
history | grep "git push"

# 统计至少匹配一次的行数，不是总匹配次数
grep -c "error" logfile.txt
42

# 只显示匹配的文件名
grep -l "main" *.cpp
main.cpp
app.cpp

# 实时监控日志中的错误
tail -f app.log | grep --line-buffered "error"
```

GNU grep 的 `--line-buffered` 会让每个输出行及时刷新，适合观察持续输入，但可能降低吞吐量。它只改变 grep 的输出缓冲，不解决上游日志轮转、模式大小写、二进制输入或管道前序命令失败等问题。

==== sed：流式文本编辑

`sed`（Stream Editor）按脚本逐行转换文本，默认把结果写到标准输出。它适合规则清晰的行式处理；对 C++ 语法树、带引用与转义的结构化配置或真正的 CSV，仅靠文本替换可能改到注释、字符串或错误字段。

基本替换语法：

```bash
# 替换每行第一个匹配
sed 's/old/new/' file.txt
# s = substitute 替换命令
# old = 要查找的模式
# new = 替换成的内容

# 替换所有匹配（g = global）
sed 's/old/new/g' file.txt

# GNU sed 中 I/i 标志可忽略大小写
sed 's/error/ERROR/gi' file.txt
```

上面三条命令都不修改原文件。准备落盘时，可以先把结果写到新文件并比较：

```bash
sed 's/old/new/g' file.txt > file.txt.new
diff -u file.txt file.txt.new
```

确认差异后再用 `mv -i -- file.txt.new file.txt` 替换；还要保留版本控制或其他可恢复副本。GNU sed 也支持 `-i` 原地编辑：

```bash
# 修改前把原内容改名为 file.txt.bak；已有同名备份可能被替换
sed -i.bak 's/old/new/g' file.txt
```

`-i` 的语法和备份后缀行为在不同 sed 实现间有差异。它会实际修改目标，不应在没有预览时与通配符、`sudo` 或来源不明的模式组合。

sed 使用正则表达式，可以进行复杂的模式匹配：

```bash
# 删除行首的空格和制表符
sed 's/^[[:blank:]]*//' file.txt

# 删除行尾的空格和制表符
sed 's/[[:blank:]]*$//' file.txt

# 删除空行
sed '/^$/d' file.txt
# d = delete 删除命令

# 删除包含特定模式的行
sed '/pattern/d' file.txt

# 删除注释行
sed '/^#/d' config.txt
sed '/^\/\//d' code.cpp
```

限定替换范围：

```bash
# 只替换第 3 行
sed '3s/old/new/' file.txt

# 替换第 3 到第 5 行
sed '3,5s/old/new/g' file.txt

# 替换第 10 行到最后一行
sed '10,$s/old/new/g' file.txt

# 替换匹配某模式的行
sed '/error/s/old/new/g' file.txt
```

sed 的实际应用场景：

```bash
# 先预览一个文件中的字面文本替换
sed 's/oldFunction/newFunction/g' detector.cpp

# 只输出键名严格匹配的一行修改结果
sed 's/^port=8080$/port=9090/' config.ini

# 给每行添加前缀
sed 's/^/PREFIX: /' file.txt

# 给每行添加后缀
sed 's/$/ SUFFIX/' file.txt

# 在第 10 行后插入新行
sed '10a\This is a new line' file.txt
# a = append 追加

# 在第 10 行前插入新行
sed '10i\This is a new line' file.txt
# i = insert 插入

# 路径中含 / 时可换用其他分隔符；这里仍只输出预览
sed 's|/old/path|/new/path|g' config.txt
# 使用 | 作为分隔符，避免与路径中的 / 冲突
```

搜索模式仍是正则，替换文本中的 `&` 表示整个匹配，反斜杠也有特殊含义。分隔符换成 `|` 只减少了斜杠转义，并没有把任意输入自动变安全。批量重命名 C++ 标识符时，优先使用能理解语法的重构工具；修改 YAML、JSON 等结构化数据时优先使用对应解析器。

sed 脚本可以包含多个命令：

```bash
# 多个命令用 -e 分隔
sed -e 's/foo/bar/g' -e 's/baz/qux/g' file.txt

# 或用分号分隔
sed 's/foo/bar/g; s/baz/qux/g' file.txt

# 从文件读取 sed 命令
sed -f script.sed file.txt
```

==== awk：按字段处理文本

`awk` 是面向记录和字段的文本处理语言。默认一行是一条记录，连续空白分隔字段；通过设置 `FS` 可以处理结构固定的简单表格和日志。它并不会自动理解带引号、嵌入逗号或跨行字段的完整 CSV 语法，这类文件应使用 CSV 解析器。

awk 的基本语法是 `awk 'pattern { action }' file`。如果某行匹配 pattern，就执行 action。

```bash
# 打印每行（相当于 cat）
awk '{ print }' file.txt

# 打印第一个字段（默认以空白分隔）
awk '{ print $1 }' file.txt

# 打印第一和第三个字段
awk '{ print $1, $3 }' file.txt

# $0 表示整行，$1, $2, ... 表示各个字段，$NF 表示最后一个字段
awk '{ print $NF }' file.txt      # 打印最后一个字段
awk '{ print $(NF-1) }' file.txt  # 打印倒数第二个字段
```

处理 CSV 或其他分隔符的文件：

```bash
# -F 指定字段分隔符
awk -F',' '{ print $1, $3 }' data.csv

# 冒号分隔（如 /etc/passwd）
awk -F':' '{ print $1, $7 }' /etc/passwd
# 输出用户名和 shell

# 多字符 FS 按正则表达式解释
awk -F'::' '{ print $1 }' file.txt
```

以上逗号示例只适用于字段本身不含带引号逗号、换行等情况；`/etc/passwd` 的字段结构则由该系统文件格式定义。

条件过滤：

```bash
# 只打印匹配模式的行
awk '/error/ { print }' logfile.txt

# 条件判断
awk '$3 > 100 { print $1, $3 }' data.txt  # 第三字段大于 100 的行

# 组合条件
awk '$3 > 100 && $2 == "active" { print }' data.txt

# 打印行号
awk '{ print NR, $0 }' file.txt  # NR = Number of Records（行号）
```

awk 内置变量：

- `$0`：整行内容
- `$1`, `$2`, ...：各字段
- `NR`：当前行号
- `NF`：当前行的字段数
- `FS`：字段分隔符
- `OFS`：输出字段分隔符

格式化输出：

```bash
# printf 格式化
awk '{ printf "%-10s %5d\n", $1, $2 }' data.txt

# 添加表头
awk 'BEGIN { print "Name\tScore" } { print $1 "\t" $2 }' data.txt
# BEGIN 在处理任何行之前执行

# 添加表尾/汇总
awk '{ sum += $2 } END { print "Total:", sum }' data.txt
# END 在处理完所有行之后执行
```

实际应用示例：

```bash
# 统计日志中各类错误的数量
awk '/error/ { count[$4]++ } END { for (type in count) print type, count[type] }' app.log

# 在“每个非空行第一列均为有效数字”的前提下计算平均值
awk 'NF { sum += $1; count++ } END { if (count) print sum/count; else exit 1 }' numbers.txt

# 对无引号、首行为表头、第三列均为数字的简单逗号表计算平均值
awk -F',' 'NR > 1 { sum += $3; count++ } END { if (count) print "Average:", sum/count; else exit 1 }' data.csv

# 过滤并格式化 ps 输出
ps aux | awk '$3 > 1.0 { printf "%-10s %5.1f%%\n", $11, $3 }'
# 显示 CPU 使用率超过 1% 的进程

# 分析 ROS 2 日志
awk '/\[ERROR\]/ { print $1, $2, $0 }' ros2.log
```

这些例子都依赖输入字段位置稳定；例如错误类型未必总在 `$4`，`ps aux` 的列和命令文本也不适合作为跨平台协议。先查看样本并验证字段数，再解释统计结果。awk 支持变量、数组、循环、条件和函数，一段 awk 程序有时比多级管道更集中，但可读性和性能仍取决于任务与实现；结构复杂时应改用有解析库和测试的脚本语言。

==== 排序、去重与统计

`sort` 对文本行排序。默认次序受当前区域设置影响；需要可复现的逐字节顺序时，可以只对该命令设置 `LC_ALL=C`：

```bash
# 默认按字母顺序排序
sort names.txt

# -n 按数字排序
sort -n numbers.txt

# -r 反向排序
sort -r names.txt
sort -rn numbers.txt  # 数字降序

# -k 按指定字段排序
sort -k 2,2 data.txt      # 只以第二字段为主键排序
sort -k 2,2n data.txt     # 第二字段按数字排序
sort -k 2,2 -k 1,1 data.txt  # 先按第二字段，相同则按第一字段

# -t 指定字段分隔符
sort -t',' -k 3,3n data.csv  # 仅适用于不含带引号逗号的简单表格

# -u 排序并去重
sort -u names.txt

# 查找最大的几个文件
du -sh -- * | sort -rh | head -n 5
```

最后一例只包含 `*` 匹配到的非隐藏条目，`du` 数字也受硬链接、权限和文件系统特性影响，适合初步定位而不是精确审计。

`uniq` 去除相邻的重复行（通常与 sort 配合使用）：

```bash
# 排序后，相同内容相邻，因此可做不保留原顺序的全局去重
sort names.txt | uniq

# -c 统计每行出现的次数
sort names.txt | uniq -c
      3 Alice
      1 Bob
      2 Charlie

# -d 只显示重复的行
sort names.txt | uniq -d

# -u 只显示不重复的行
sort names.txt | uniq -u

# 统计最常出现的项
sort items.txt | uniq -c | sort -rn | head -n 10
```

`uniq` 本身只合并相邻的相同行，并不要求输入必须排序。如果原顺序有意义，可以先采用其他方式把重复项相邻，或使用能保留首次出现顺序的工具；直接 `sort` 会改变原顺序。`uniq -u` 显示的是相邻分组中只出现一次的行。

`wc`（word count）统计行数、单词数、字符数：

```bash
# 默认显示行数、单词数、字节数
wc file.txt
  100   500  3000 file.txt

# -l 只显示行数
wc -l file.txt
100 file.txt

# -w 只显示单词数
wc -w file.txt

# -c 只显示字节数
wc -c file.txt

# -m 按当前区域设置统计字符数
wc -m file.txt

# 统计多个文件
wc -l *.cpp
  100 main.cpp
  200 detector.cpp
  150 tracker.cpp
  450 total

# GNU find 每找到一个当前层普通文件就输出一个字符，避免解析 ls
find . -maxdepth 1 -type f -printf x | wc -c

# 分文件统计文本行；总数是否出现取决于 wc 收到的文件数量
find . -type f -name "*.cpp" -exec wc -l -- {} +
```

`wc -l` 统计换行符，不是抽象语法中的“代码行”；最后一行没有换行时结果也会与直觉不同。`wc -w` 的单词边界和 `wc -m` 的字符解码受区域设置影响。

组合使用这些工具可以完成复杂的分析任务：

```bash
# 统计日志中各 IP 的访问次数
awk '{ print $1 }' access.log | sort | uniq -c | sort -rn | head -n 10

# 找出代码中使用最多的函数
grep -Eoh '\b[a-zA-Z_][a-zA-Z0-9_]*\(' -- *.cpp | sort | uniq -c | sort -rn | head -n 20

# 统计各类型文件的数量
find . -type f -name '*.*' -printf '%f\n' | sed 's/.*\.//' | sort | uniq -c | sort -rn
```

这些是建立在输入格式上的快速统计：访问日志第一列不一定是客户端 IP，正则找到的是“看起来像调用的标识符”而不是真正解析出的 C++ 函数，扩展名示例还假定文件名不含换行。它们可以生成检查线索，不能直接当作代码语义或日志来源的结论。

==== diff：文件比较

`diff` 按行比较两个文件或目录，适合查看文本配置和未纳入版本控制的文件。它报告“哪里不同”，并不知道哪一份在业务上正确。

```bash
# 基本比较
diff file1.txt file2.txt
2c2
< old line
---
> new line
5a6
> added line
```

输出格式说明：`<` 表示第一个文件的内容，`>` 表示第二个文件的内容。`2c2` 表示第 2 行有变化（change），`5a6` 表示在第 5 行后添加了内容（add），`3d2` 表示第 3 行被删除（delete）。

`diff` 的退出状态有专门含义：`0` 表示在所选比较规则下没有差异，`1` 表示发现差异，值大于 `1` 通常表示读取或调用错误。因此在脚本中不能把退出码 `1` 一概写成“命令失败”。

更友好的输出格式：

```bash
# -u 统一格式（unified diff），更易读，也是 Git 使用的格式
diff -u file1.txt file2.txt
--- file1.txt   2024-01-15 10:00:00
+++ file2.txt   2024-01-15 11:00:00
@@ -1,5 +1,6 @@
 line 1
-old line
+new line
 line 3
 line 4
 line 5
+added line

# -y 并排显示
diff -y file1.txt file2.txt
line 1                line 1
old line            | new line
line 3                line 3

# --color 彩色显示（需要较新版本）
diff --color -u file1.txt file2.txt
```

比较目录：

```bash
# -r 递归比较目录
diff -r dir1/ dir2/

# -q 只显示哪些文件不同，不显示具体差异
diff -rq dir1/ dir2/
Files dir1/file.txt and dir2/file.txt differ
Only in dir1/: extra.txt
```

忽略某些差异：

```bash
# -w 忽略所有空白差异
diff -w file1.txt file2.txt

# -b 忽略空白数量变化
diff -b file1.txt file2.txt

# -B 忽略空行差异
diff -B file1.txt file2.txt

# -i 忽略大小写
diff -i file1.txt file2.txt
```

忽略空白、空行或大小写会有意隐藏一部分变化，而这些变化在 Python、Makefile、字符串数据或大小写敏感标识符中可能具有语义。只应在确认对应差异无关时使用，并保留一次未忽略的比较供核对。

实际应用：

```bash
# 比较配置文件的变化
diff -u config.old config.new > changes.patch

# 在正确的工作目录中先检查补丁能否应用，不修改文件
patch --dry-run -p0 < changes.patch

# 比较两个版本的代码
diff -ru old_version/ new_version/ > upgrade.patch

# 查看 Git 工作区尚未暂存的变化
git diff

# 比较 HEAD 提交与其第一父提交（仓库必须存在相应历史）
git diff HEAD~1..HEAD
```

正式执行 `patch` 前还要审阅目标路径、保留可恢复状态并确定正确的 `-p` 层级；dry-run 只验证当前文件状态下的适用性，不证明补丁内容可信或修改结果正确。目录 diff 也未必完整表达符号链接、权限、重命名和二进制文件变化，代码项目通常优先使用版本控制系统提供的差异。

`colordiff` 可以为常见 diff 输出添加颜色，是否更便于阅读取决于终端和无障碍需求：

```bash
sudo apt install colordiff
colordiff -u file1.txt file2.txt
```

本节覆盖了交互编辑、按行搜索、文本转换、字段统计和差异比较。实际使用时先确认输入格式，再用只输出结果的命令预览，最后才选择原地编辑或应用补丁。对于 C++、YAML、JSON 和完整 CSV 等有明确语法的内容，专用解析或重构工具通常比正则替换更可靠。下一节进入用户与权限管理，重点将从“文本写了什么”转到“哪个身份能对哪个对象执行什么操作”。


=== 用户与权限管理
// 多用户系统的安全基础
// - 用户与用户组
// - root 与 sudo
// - 文件权限：rwx 与数字表示（755, 644）
// - ls -l 输出解读
// - chmod, chown
// - 为什么脚本需要 chmod +x
// === 用户与权限管理

Linux 沿用了 Unix 的多用户模型：进程带有用户和组身份，文件对象带有所有者、组与权限，内核据此参与访问检查。同一台机器可以有交互用户、系统服务账户和远程会话，它们并不会天然完全隔离；实际边界还受到目录权限、ACL、Linux capabilities、安全模块、容器与服务配置影响。本节先掌握最常见的 owner/group/others 模型，再说明 `sudo`、脚本执行位和特殊权限的适用范围。

==== 用户与用户组

Linux 内核主要使用数字 UID 标识进程和文件所有者，用户名是用户空间提供的可读映射。在一台普通主机的身份命名空间内，账户名和 UID 映射应保持一致；复制磁盘、网络身份源和用户命名空间会让“全世界唯一”这种说法失效。本地账户的一部分信息记录在 `/etc/passwd`，LDAP 等外部身份源还可通过 NSS 提供账户：

```bash
cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
...
alice:x:1000:1000:Alice:/home/alice:/bin/bash
bob:x:1001:1001:Bob:/home/bob:/bin/bash
```

每行代表一个用户，字段用冒号分隔：用户名、密码占位符（实际密码在 `/etc/shadow`）、UID、GID（主组 ID）、用户描述、家目录、登录 Shell。

主机初始用户命名空间中的 UID 0 通常映射为 root，并拥有广泛权限，但仍受内核、只读介质、能力集、安全模块、命名空间和硬件边界约束。Ubuntu 默认往往从 1000 开始分配普通用户 UID，具体范围由系统配置决定。系统服务账户常使用较小 UID，并把登录 Shell 设为 `/usr/sbin/nologin` 或 `/bin/false` 以拒绝常规 Shell 登录；服务仍可以由管理器以该身份启动。

用户组是用户的集合，用于简化权限管理。每个用户属于一个主组（primary group），还可以属于多个附加组（supplementary groups）。组信息存储在 `/etc/group` 中：

```bash
cat /etc/group
root:x:0:
sudo:x:27:alice
audio:x:29:alice,bob
video:x:44:alice,bob
alice:x:1000:
bob:x:1001:
```

用户组可以把同一类访问权授予多个账户。例如管理员可以创建 `robomaster` 组，将确实需要访问共享目录的队员加入其中，再结合目录权限、SGID 和默认 ACL 管理协作。仅仅“加入组”不会自动让目录可写，也不能保证组外用户没有其他 ACL 或提权途径。

查看当前用户和组信息：

```bash
# 查看当前用户
whoami
alice

# 查看当前用户的 UID 和所属组
id
uid=1000(alice) gid=1000(alice) groups=1000(alice),27(sudo),29(audio),44(video)

# 查看其他用户的信息
id bob
uid=1001(bob) gid=1001(bob) groups=1001(bob),29(audio),44(video)

# 查看当前用户所属的所有组
groups
alice sudo audio video
```

账户和组管理会影响登录、文件所有权和服务，应由机器管理员在确认名称、UID、家目录和数据保留策略后执行。Ubuntu 上交互创建普通用户通常优先使用 `adduser`：

```bash
# 交互创建账户、家目录并设置密码
sudo adduser newuser

# 创建组
sudo groupadd robomaster

# 将用户添加到组
sudo usermod -aG robomaster alice
# -a 追加（不覆盖现有组）
# -G 指定附加组

# 从组中移除用户
sudo gpasswd -d alice robomaster
```

`usermod -aG` 中的 `-a` 很重要：省略它会把附加组列表替换为给定集合。删除账户及家目录属于数据删除操作，本章不提供可直接复制的命令；执行前需要盘点该 UID 拥有的其他文件、运行任务、计划任务和备份，不能只检查家目录。

进程的附加组在会话建立时设置。修改组数据库不会回溯改变已经运行的终端、IDE 或服务；通常应结束相关会话并重新登录，再用 `id` 验证。`newgrp` 可以启动采用新组的子 Shell，但也会改变当前工作流中的凭据和环境，不等同于更新所有既有进程。

==== root 与 sudo

root 通常是 UID 0 对应的管理账户，能够绕过许多普通文件权限并执行系统级操作。它不是超越内核和所有安全机制的“无限权限”，但足以让路径错误、错误配置或不可信脚本造成大范围影响。因此日常开发使用普通账户，只把经过核对的单项管理操作交给提权机制。

`sudo` 根据管理员策略让获授权用户以 root 或通过 `-u` 指定的其他用户身份执行命令。常见策略会要求输入调用者自己的密码，并在一段可配置时间内缓存认证；密码提示验证的是账户凭据，不会判断即将执行的命令是否正确：

```bash
# 以 root 身份执行命令
sudo apt update

# 第一次使用会提示输入密码
[sudo] password for alice: 
...

# 在策略允许的认证缓存期内，可能不会再次提示
sudo apt upgrade
```

sudo 策略可以限制用户、目标身份、主机和命令，并记录调用事件。Ubuntu 日志可能写入 `/var/log/auth.log` 或 systemd journal，具体取决于日志配置；启动一个 Shell 或脚本后，普通命令日志未必记录其内部每一步，因此 sudo 记录不能单独构成完整审计。策略位于 `/etc/sudoers` 及 `/etc/sudoers.d/`，必须使用 `visudo` 或等价语法检查流程修改，避免语法错误锁死管理入口。

标准 Ubuntu 安装通常通过 `sudo` 组授予默认管理权限，安装时创建的用户通常会加入该组；管理员可以改写策略，所以组成员关系只是检查线索。`sudo -l` 可以列出当前策略允许的命令：

```bash
# 检查用户是否在 sudo 组
groups alice
alice sudo audio video

# 让 sudo 按当前策略列出授权范围
sudo -l

# 将用户加入 sudo 组（需要已有 sudo 权限的用户执行）
sudo usermod -aG sudo newuser
```

`sudo -i` 或 `sudo -s` 可以启动高权限 Shell，但这会扩大误操作范围，并使后续每条命令不再显式标出提权边界。普通配置任务优先逐条使用 sudo；只有确实需要连续管理操作且已有恢复路径时才进入高权限 Shell，并在完成后立即退出。提示符中的 `#` 只是约定，不能代替 `id` 对当前身份的确认：

```bash
# 启动 root shell
sudo -i
root@hostname:~# 
# 常见主题会显示 #；仍用 id 确认有效身份
root@hostname:~# id
uid=0(root) gid=0(root) groups=0(root)

# 完成后退出
root@hostname:~# exit
$
```

不要把“少输入几次 sudo”作为进入 root Shell 的理由。sudo 默认还会按策略处理环境变量；`sudo -s` 也不是原样保留整个当前环境，具体行为要以 `sudoers` 配置为准。

编辑系统文件时，优先使用 `sudoedit`：它把临时副本交给普通用户身份下的编辑器，保存后再按策略写回，减少编辑器插件、配置和临时文件以 root 身份运行的范围。

```bash
# 明确为本次 sudoedit 选择 nano
SUDO_EDITOR=nano sudoedit /etc/hosts
```

保存后还要运行目标服务或工具提供的语法检查，再决定是否重载。直接用 sudo 启动编辑器或图形程序会让插件、配置读取和辅助文件创建都处在高权限上下文中；在家目录中产生 root 所有的文件只是可能后果之一，并非每次写入都必然改变所有者。

```bash
# 家目录文件通常直接以普通用户编辑
vim ~/my_script.sh
```

==== 文件权限：rwx 模型

经典 Unix 文件模式为每个对象保存所有者、所属组，以及 owner、group、others 三组权限位；每组包含读、写、执行。内核会先确定请求进程匹配所有者、组还是其他人，并使用对应一组，而不是把三组权限简单相加。ACL、capabilities、挂载选项和安全模块还可能进一步改变结果，因此 `rwx` 是基础模型，不是全部授权机制。

用 `ls -l` 查看文件权限：

```bash
ls -l
-rw-r--r-- 1 alice alice  1234 Jan 15 10:00 document.txt
-rwxr-xr-x 1 alice alice  5678 Jan 15 10:00 script.sh
drwxr-xr-x 2 alice alice  4096 Jan 15 10:00 mydir
lrwxrwxrwx 1 alice alice    10 Jan 15 10:00 link -> target
```

符号链接显示的 `rwxrwxrwx` 在 Linux 上通常不是访问目标时采用的权限；路径中目录和最终目标的权限更关键。修改链接目标还是链接本身，也要看具体命令是否跟随符号链接。

第一列就是权限字符串，让我们详细解读 `-rwxr-xr-x`：

- 第 1 个字符：文件类型。`-` 普通文件，`d` 目录，`l` 符号链接，`c` 字符设备，`b` 块设备。
- 第 2-4 个字符（`rwx`）：所有者权限。这里是 `rwx`，表示所有者可以读、写、执行。
- 第 5-7 个字符（`r-x`）：所属组权限。这里是 `r-x`，表示组成员可以读、执行，但不能写。
- 第 8-10 个字符（`r-x`）：其他人权限。这里也是 `r-x`，表示其他人可以读、执行，但不能写。

权限字符的含义：

- `r`（read，值为 4）：
  - 对于文件：可以读取内容
  - 对于目录：可以读取目录中的名称列表；若没有 `x`，通常无法继续取得条目元数据或访问内容
- `w`（write，值为 2）：
  - 对于文件：可以修改内容
  - 对于目录：通常与 `x` 配合，允许创建、删除、重命名目录项；sticky bit 等规则还会限制删除
- `x`（execute，值为 1）：
  - 对于文件：允许尝试直接执行；文件格式、解释器、架构和 `noexec` 挂载等条件仍需满足
  - 对于目录：允许按已知名称搜索和穿过该目录，不只是能否 `cd`
- `-`：没有该权限

访问一个路径需要对沿途目录具有搜索权限。删除普通文件主要修改父目录中的名称映射，因此即使文件本身不可写，只要父目录权限和 sticky bit 等检查允许，仍可能删除该名称；反过来，有文件写权限却没有父目录搜索权限，也无法通过该路径打开它。这一区别解释了为什么排查 “Permission denied” 时要检查整条路径，而不只看最后一个文件。

==== 数字表示法

除了 `rwx` 字符表示，权限还可以用数字表示。每种权限对应一个数值：r=4，w=2，x=1。一组权限的数字是各权限值的和：

- `rwx` = 4+2+1 = 7
- `rw-` = 4+2+0 = 6
- `r-x` = 4+0+1 = 5
- `r--` = 4+0+0 = 4
- `---` = 0+0+0 = 0

三组权限组成三位数：

- `rwxr-xr-x` = 755
- `rw-r--r--` = 644
- `rwx------` = 700
- `rw-rw-r--` = 664

下面是常见起点，不是按扩展名机械套用的固定答案：

- *755*：所有者可读写执行，其他人可读执行；常见于需要所有用户搜索的目录或公开程序。
- *644*：所有者可读写，其他人只读；可用于确实允许本机其他用户读取的普通文件。
- *700*：只有所有者可访问。用于私密目录，如 `~/.ssh`。
- *600*：只有所有者可读写。用于私密文件，如 SSH 私钥。
- *777*：任何本地身份都获得三类权限，通常掩盖了所有权或组设计问题。
- *666*：任何本地身份都可读写普通文件，也很少是合理默认值。

这些数字只表达基础模式位，不说明 ACL、文件所有者、父目录和挂载策略。看到“设为 755”时，还要问目标是文件还是目录、谁需要访问，以及是否真的允许所有本地用户读取或执行。

==== chmod：修改权限

`chmod`（change mode）命令用于修改文件权限。它有两种语法：符号模式和数字模式。

数字模式直接指定完整的权限：

```bash
# 设置权限为 755（rwxr-xr-x）
chmod 755 script.sh

# 设置权限为 644（rw-r--r--）
chmod 644 document.txt

# 设置目录权限为 700（只有所有者可访问）
chmod 700 private_dir

# X 只给目录以及原本已有执行位的文件添加执行权限
chmod -R u=rwX,g=rX,o= public_snapshot
```

递归把整棵目录设为 `755` 会把普通数据文件也标成可执行，并覆盖原有的私密或组写权限。即使使用 `X`，递归修改仍会重写每个后代对象；应先用 `find` 或 `getfacl` 查看范围，并确认符号链接、挂载点和协作 ACL。项目只需修复少数条目时，逐项修改比全树覆盖更容易验证。

符号模式更灵活，可以增加或删除特定权限：

```bash
# 语法：chmod [ugoa][+-=][rwx] file
# u=user(所有者), g=group(组), o=others(其他), a=all(所有)
# +=添加, -=删除, ==设置

# 给所有者添加执行权限
chmod u+x script.sh

# 给所有人添加读权限
chmod a+r document.txt

# 删除其他人的写权限
chmod o-w file.txt

# 给组添加读写权限
chmod g+rw shared_file.txt

# 组合操作
chmod u+x,g+r,o-w file.txt

# 设置精确权限（覆盖现有）
chmod u=rwx,g=rx,o=rx script.sh  # 等同于 755
```

符号模式的优势是可以只修改需要改变的部分，而不影响其他权限。比如 `chmod u+x` 只添加所有者的执行权限，不会改变其他权限位。

==== chown：修改所有者

`chown`（change owner）修改所有者和所属组。普通用户能否改变组受到自身组成员关系等限制，改变所有者通常需要相应管理权限。

```bash
# 修改所有者
sudo chown bob file.txt

# 修改所有者和组
sudo chown bob:developers file.txt

# 只修改组（注意冒号在前）
sudo chown :developers file.txt
# 或者用 chgrp
sudo chgrp developers file.txt

# 递归修改目录及其内容
sudo chown -R alice:robomaster project/
```

递归 `chown` 会越过项目中每个匹配条目，可能破坏容器卷、构建缓存或有意属于其他服务账户的文件。执行前先确认 `project/` 的规范路径和文件清单，并判断是否只需修复单个意外文件；不要为了消除一条权限错误就对整个家目录使用递归所有权修改。

下面演示如何修复一个明确知道来源、且本应属于 `alice` 的单个练习文件：

```bash
# 误用 sudo 创建了文件
sudo touch important.txt
ls -l important.txt
-rw-r--r-- 1 root root 0 Jan 15 10:00 important.txt

# 现在普通用户无法修改
echo "content" >> important.txt
bash: important.txt: Permission denied

# 修复所有权
sudo chown alice:alice important.txt
echo "content" >> important.txt  # 现在可以了
```

==== 为什么脚本需要 chmod +x

当你写了一个 Shell 脚本，尝试运行时可能会遇到这样的错误：

```bash
./my_script.sh
bash: ./my_script.sh: Permission denied
```

普通文件创建时通常以不含执行位的请求模式开始，再受 umask 等规则过滤，因此新脚本常没有执行权限：

```bash
ls -l my_script.sh
-rw-r--r-- 1 alice alice 100 Jan 15 10:00 my_script.sh
```

示例权限 `rw-r--r--`（644）没有 `x`，所以不能通过 `./my_script.sh` 请求直接执行。执行位表达“允许把它作为可执行对象使用”的策略，但仍要配合有效 shebang、解释器权限、文件内容和挂载选项。

解决方法就是添加执行权限：

```bash
chmod u+x my_script.sh
ls -l my_script.sh
-rwxr--r-- 1 alice alice 100 Jan 15 10:00 my_script.sh

./my_script.sh
Hello, World!
```

这里明确使用 `u+x`，只给所有者增加执行位。省略 `u/g/o/a` 的 `chmod +x` 会按当前 umask 影响所选类别，并不能简单视为永远等同于 `a+x`；教程和脚本中写清目标类别更容易审查。

也可以显式启动解释器并把可读脚本作为参数：

```bash
bash my_script.sh    # 不需要执行权限
python3 script.py    # 同样不需要
```

这种方式执行的是 `bash` 或 `python3`，脚本本身只需满足解释器读取所需的权限。它不是安全机制的“绕过”，也不必然是错误做法：临时脚本、由特定解释器管理的任务常会这样运行；需要像程序一样用 `./脚本` 启动时，再设置最小执行权限并提供正确 shebang。用 `bash` 强行运行原本面向其他 Shell 的脚本仍可能失败。

编译器或链接器创建新的本地可执行文件时通常会请求执行权限，再由 umask 过滤；目标路径、已有文件和文件系统挂载方式仍会影响结果：

```bash
g++ main.cpp -o program
ls -l program
-rwxr-xr-x 1 alice alice 12345 Jan 15 10:00 program

./program  # 直接可以运行
```

==== 特殊权限位

基础模式之外还有 SUID、SGID 和 sticky bit。它们的含义随对象类型而异，并受 `nosuid` 挂载、内核策略等条件限制。普通开发者应以识别和排查为主，不要为了消除权限报错给自编程序增加 SUID/SGID。

*SUID（Set User ID）*：对受支持的可执行文件，SUID 可以让新进程获得文件所有者对应的有效身份，而真实用户身份仍保留。程序必须自行严格限制可执行操作。Ubuntu 上的 `passwd` 是常见示例之一：

```bash
ls -l /usr/bin/passwd
-rwsr-xr-x 1 root root 68208 Jan 15 10:00 /usr/bin/passwd
```

所有者执行位位置显示 `s`。该程序借助受控的高权限路径更新密码数据库，同时还会进行身份、旧密码和策略检查；这不表示调用者获得了任意 root 操作能力。不同发行版也可能采用 capabilities、特权辅助服务或其他实现。

数字模式的高位 `4` 表示 SUID，例如查看资料时会见到 `4755`。Linux 通常忽略脚本文件上的 SUID 语义，自编 SUID 二进制则需要专门的安全设计与审计，本教程不提供直接设置命令。

*SGID（Set Group ID）*：用于可执行文件时可影响有效组身份；用于目录时，新建条目通常继承目录所属组，而不是创建者主组。这有助于团队目录保持统一组，但新条目的组写权限仍取决于请求模式、umask 和默认 ACL：

```bash
# 假定管理员已经确认 /srv/robomaster/project 的用途和 robomaster 组
sudo install -d -o root -g robomaster -m 2770 /srv/robomaster/project

# 现在在这个目录下创建的文件都属于 robomaster 组
touch /srv/robomaster/project/newfile.txt
ls -l /srv/robomaster/project/newfile.txt
-rw-r--r-- 1 alice robomaster 0 Jan 15 10:00 newfile.txt
```

示例中的 `2770` 把 SGID、所有者和组的目录访问权放在一起，并拒绝 others。输出中的新文件仍是 `0644`，说明 SGID 只解决组归属，并未自动提供组写权限；团队可再评估 `umask 002` 或默认 ACL，而不是把目录放宽到所有用户可写。

*Sticky Bit*：对目录设置后，即使用户拥有目录写权限，删除或重命名其中条目通常仍限于条目所有者、目录所有者或具备相应特权的进程。`/tmp` 常用它保护多用户共享临时目录：

```bash
ls -ld /tmp
drwxrwxrwt 10 root root 4096 Jan 15 10:00 /tmp
```

其他人执行位位置显示 `t`。能否创建条目仍要满足目录写入和搜索权限；sticky bit 主要增加删除与重命名检查，不保护文件内容不被其现有权限允许的用户读取或修改。

```bash
# 设置 Sticky Bit
chmod +t directory
chmod 1777 directory  # 1 表示 Sticky Bit
```

==== umask：默认权限

进程创建文件时会请求一个初始模式，内核再清除当前 umask 中对应的权限位。常见程序为普通文件请求 `0666`、为目录请求 `0777`，但应用可以请求更严格的模式，默认 ACL 也会参与结果。

```bash
umask
0022

# 常见普通文件请求 0666，按位清除 0022 后得到 0644
# 0666 & ~0022 = 0644

# 常见目录请求 0777，按位清除 0022 后得到 0755
# 0777 & ~0022 = 0755
```

常见的 umask 值：

- *022*：在上述常见请求模式下得到文件 644、目录 755；许多系统会采用，但并非统一默认。
- *077*：文件 600，目录 700。更私密，其他用户无法访问。
- *002*：文件 664，目录 775。同组用户可写，适合团队协作。

修改 umask：

```bash
# 临时修改
umask 077

# 需要长期调整时，编辑一次合适的登录或 Shell 配置并新开会话验证
```

umask 属于进程状态，子进程继承当前值；systemd 服务、登录会话、IDE 和容器可能从不同配置获得它。把 `umask` 写进 `.bashrc` 只影响读取该文件的 Shell，不会自动修改已经运行的进程或所有服务。团队共享目录若既要继承组又要稳定提供组写权限，默认 ACL 往往比依赖每个人的 umask 更明确。

==== 实际场景中的权限管理

让我们看一些 RoboMaster 开发中常见的权限相关场景。

*访问串口设备*：USB 转串口在当前机器上可能显示为 `/dev/ttyUSB0`、`/dev/ttyACM0` 或稳定的 udev 链接，所属组也由发行版和设备规则决定。先检查实际节点：

```bash
ls -l /dev/ttyUSB0
crw-rw---- 1 root dialout 188, 0 Jan 15 10:00 /dev/ttyUSB0

# 只检查当前用户是否具备读写权限，不消费串口数据
test -r /dev/ttyUSB0 && test -w /dev/ttyUSB0
printf '%s\n' "$?"  # 0 表示两项检查都通过，非 0 表示至少一项未通过

# 解决方法：将用户加入 dialout 组
sudo usermod -aG dialout alice
# 重新登录后生效

groups
alice dialout ...
id
```

加入 `dialout` 会授予该组覆盖的所有设备访问权，并非只授权这一只串口。共享机器或固定产品中，可以由管理员为匹配的 VID/PID 或序列号编写更窄的 udev 规则；设备重新插拔后名称和临时 ACL 也可能改变。权限检查通过只说明模式允许打开，不证明波特率、协议或设备状态正确。

*共享项目目录*：团队成员需要共同编辑项目文件：

```bash
# 假定 robomaster 组已创建，管理员建立仅 owner/group 可访问的目录
sudo install -d -o root -g robomaster -m 2770 /srv/robomaster/rm_vision

# 确保团队成员都在 robomaster 组
sudo usermod -aG robomaster alice
sudo usermod -aG robomaster bob
```

成员重新登录并用 `id` 验证后，还要通过 `umask 002` 或目录默认 ACL 确保新文件对组可写。SGID 只保证组继承，不能修复已有文件权限，也不能处理两名成员同时编辑同一文件的冲突；项目内容仍应使用版本控制和备份。

*保护 SSH 密钥*：SSH 对私钥权限有严格要求：

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/known_hosts
chmod 600 ~/.ssh/config

# 如果权限不对，SSH 会拒绝使用密钥
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/home/alice/.ssh/id_ed25519' are too open.
```

这些是常见的保守模式。OpenSSH 实际检查还涉及所有者、父目录、`StrictModes` 和平台实现；不要用放宽到 `777` 的方式消除警告。私钥泄露后仅修权限不够，还应撤销对应公钥并更换密钥。

*脚本和程序*：

```bash
# 创建脚本后添加执行权限
vim run_vision.sh
chmod u+x run_vision.sh
./run_vision.sh

# 安装自己的程序到 ~/.local/bin
mkdir -p ~/.local/bin
install -m 0700 my_tool ~/.local/bin/my_tool
```

用户、组、目录权限和提权策略共同决定一项访问是否被允许。遇到权限错误时，按“当前进程身份 → 路径沿途目录 → 最终对象模式与 ACL → 设备或服务策略”的顺序检查，比直接加 `sudo` 或 `chmod 777` 更容易定位且更少引入新风险。为任务授予最小必要范围，完成后验证实际身份和访问结果；下一节的软件包管理同样遵循这一原则，因为安装与卸载会修改系统级状态。


=== 软件包管理
// 安装和管理软件
// - APT 包管理器
//   apt update / upgrade
//   apt install / remove / purge
//   apt search / show
// - dpkg 底层工具
// - 软件源与 PPA
// - 从源码编译安装
// - RoboMaster 常用软件安装
// === 软件包管理

Ubuntu 主要通过软件包管理器分发系统软件：仓库提供版本化的软件包和签名元数据，APT 计算依赖与变更方案，dpkg 负责解包、配置并记录状态。它能让安装和安全更新更一致，但不会保证所有依赖冲突都可解，也不会在卸载时自动清除全部用户数据。本节先学习查看方案和使用官方仓库，再讨论第三方来源与源码安装带来的信任、版本和卸载成本。

==== 包管理器的概念

软件包（package）包含程序、库、文档、元数据，也可能包含在安装、升级和卸载阶段运行的维护脚本。Debian/Ubuntu 的二进制包通常使用 `.deb` 格式。APT 和 dpkg 共同维护已安装状态、依赖关系和由包管理的系统配置文件；家目录内容、外部数据库及程序运行后生成的数据不一定在这份清单中。

依赖描述软件运行、配置或构建所需的其他包，此外还有冲突、替代、推荐等关系。APT 会根据当前软件源、架构、版本约束、pin 优先级和已安装状态求解方案；若约束互相冲突，它可能保留包、提出删除方案或直接失败。安装前阅读方案，仍是确认影响范围的必要步骤。

软件源（repository）提供包索引和软件包文件。APT 会验证仓库元数据的签名，并按索引校验下载内容；这验证的是内容来自已信任的仓库且传输后未被篡改，不等于每个包都适合当前项目。软件源配置决定可见版本和信任边界，镜像还应考虑同步及时性、HTTPS、运营方和网络稳定性，而不只比较瞬时速度。

==== APT 基础操作

APT（Advanced Package Tool）是 Ubuntu 和其他 Debian 系发行版的高级包管理工具。它提供了友好的命令行界面，是日常软件管理的主要工具。

*更新软件包列表*

在安装或升级软件之前，应该先更新本地的软件包列表。这个列表记录了软件源中有哪些软件、什么版本：

```bash
sudo apt update
Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
Get:2 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [119 kB]
...
Reading package lists... Done
Building dependency tree... Done
42 packages can be upgraded. Run 'apt list --upgradable' to see them.
```

`apt update` 只是更新列表，不会安装或升级任何软件。它告诉你有多少包可以升级。

*升级已安装的软件*

更新列表后，可以让 APT 计算可用升级：

```bash
sudo apt upgrade
Reading package lists... Done
Building dependency tree... Done
Calculating upgrade... Done
The following packages will be upgraded:
  package1 package2 package3 ...
42 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
Need to get 50.0 MB of archives.
Do you want to continue? [Y/n] y
...
```

APT 会显示将要升级哪些包、下载量、磁盘空间变化，并询问确认。按 `Y` 或直接回车确认。

当前 Ubuntu 中的 `apt upgrade` 可以为升级安装新的依赖，但不会为完成升级而删除已安装包，因此部分包可能保留。`apt full-upgrade` 允许求解器删除包，执行前必须逐项检查 `REMOVED`、新装包、内核/驱动和磁盘变化：

```bash
sudo apt full-upgrade
```

`full-upgrade` 仍是在当前发行版的软件源集合内升级，不负责把 Ubuntu 22.04 迁移到下一个发行版；发行版升级使用单独的 `do-release-upgrade` 流程，并需要兼容性检查、备份和维护窗口。

*安装软件*

安装软件是最常用的操作：

```bash
# 安装单个软件
sudo apt install vim

# 安装多个软件
sudo apt install git cmake build-essential

# 重新安装已安装的软件
sudo apt reinstall package_name
```

`-y` 会自动接受提示，不能替代方案审阅。自动化环境若确实需要非交互安装，应固定软件源与目标版本、先模拟或记录计划，并处理配置提示、失败和重启要求，而不是给任意安装命令追加 `-y`。

`build-essential` 是一个元包（metapackage），通过依赖拉取 Debian 包构建所需的一组基础工具，包括 GCC/G++ 和 make 等。具体项目还可能要求 Clang、CMake、Ninja、特定库或特定版本，因此安装该元包不代表构建环境已经完整。

*卸载软件*

卸载软件有两种方式：

```bash
# 卸载软件，保留配置文件
sudo apt remove package_name

# 完全卸载，包括配置文件
sudo apt purge package_name

# 卸载后清理不再需要的依赖
sudo apt autoremove
```

`remove` 通常保留 dpkg 管理的 conffile，`purge` 还删除这些已登记的系统配置。二者都可能保留家目录配置、日志、数据库和其他运行时数据；维护脚本也可能有自己的处理。因此 `purge` 不等于“系统上与该软件有关的一切都彻底消失”。

`autoremove` 根据 APT 的自动/手动安装标记提出不再需要的依赖。标记可能与用户当前用途不一致，每次都应审阅删除清单，尤其关注内核、驱动、桌面和开发库；不要把它设为不看输出的定期清理动作。

*搜索软件*

不确定软件包的确切名称？用 `apt search`：

```bash
apt search opencv
Sorting... Done
Full Text Search... Done
libopencv-dev/jammy 4.5.4+dfsg-9ubuntu4 amd64
  development files for opencv

python3-opencv/jammy 4.5.4+dfsg-9ubuntu4 amd64
  Python 3 bindings for OpenCV
...
```

搜索结果可能很多，可以用 grep 过滤：

```bash
apt search opencv | grep -i "dev"
```

*查看软件包信息*

安装前想了解软件包的详细信息：

```bash
apt show libopencv-dev
Package: libopencv-dev
Version: 4.5.4+dfsg-9ubuntu4
Priority: optional
Section: universe/libdevel
Source: opencv
Origin: Ubuntu
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Bugs: https://bugs.launchpad.net/ubuntu/+filebug
Installed-Size: 5,391 kB
Depends: libopencv-calib3d-dev, libopencv-contrib-dev, ...
Suggests: opencv-doc
Homepage: https://opencv.org/
Description: development files for opencv
...
```

这显示了软件版本、大小、依赖关系、描述等信息。

*列出已安装的软件*

```bash
# 列出所有已安装的软件
apt list --installed

# 过滤特定软件
apt list --installed | grep opencv

# 列出可升级的软件
apt list --upgradable
```

*清理缓存*

APT 会缓存下载的 `.deb` 文件在 `/var/cache/apt/archives/`。时间长了可能占用大量空间：

```bash
# 查看缓存大小
du -sh /var/cache/apt/archives/
500M    /var/cache/apt/archives/

# 删除缓存中已无法从当前软件源下载的包
sudo apt autoclean

# 清理所有缓存
sudo apt clean
```

==== dpkg：底层工具

`dpkg` 维护 Debian 包数据库并负责解包、配置和运行维护脚本，本身不从仓库求解完整依赖方案。APT 在更高层读取软件源、计算依赖并调用 dpkg 等组件。日常安装优先使用 APT；dpkg 的查询命令则适合确认文件归属和包状态。

*安装本地 .deb 文件*

外部 `.deb` 会以管理员权限安装文件并可能运行维护脚本，下载到一个文件并不等于来源可信。先从软件供应方的正式渠道获取，核对适用的 Ubuntu 版本、架构、散列或签名，再检查元数据：

```bash
# 查看控制信息与文件清单，不执行安装脚本
dpkg-deb --info ./software.deb
dpkg-deb --contents ./software.deb | less

# 认可来源和计划后，让 APT 安装本地包并求解仓库依赖
sudo apt install ./software.deb
```

路径前的 `./` 告诉 APT 这是本地文件而不是软件源中的包名。若此前用 `dpkg -i` 留下未配置状态，`apt --fix-broken install` 可能安装、升级或删除包以恢复一致性；先用模拟模式查看计划，不能把它理解为只会补齐缺失依赖：

```bash
apt --simulate --fix-broken install
```

*查询已安装的包*

```bash
# 精确查询包的登记状态和版本
dpkg-query -W -f='${binary:Package}\t${db:Status-Abbrev}\t${Version}\n' package_name

# 查看包安装了哪些文件
dpkg -L package_name
/usr/bin/program
/usr/lib/libsomething.so
/usr/share/doc/package_name/README
...

# 查看某个文件属于哪个包
dpkg -S /usr/bin/vim
vim: /usr/bin/vim
```

这些查询能确认 dpkg 记录的包状态和文件清单，但“文件属于哪个包”不能解释命令失败的全部原因；还要检查 PATH、配置、动态库、架构和实际错误。重新安装是可能动作之一，不应在诊断前自动执行。

`dpkg --audit` 可报告部分未完整安装的包，`dpkg --get-selections` 可导出选择状态。卸载仍优先通过 APT 计算依赖影响，而不是直接使用 `dpkg -r/-P` 绕过高层方案。

==== 软件源与 PPA

Ubuntu 官方仓库的版本会围绕发行版稳定性维护，不一定等于上游最新版本。需要仓库外软件时，可以评估供应方仓库、容器、用户级安装或源码构建；添加第三方 APT 源会扩大能够向系统投递高权限软件包的信任边界，应先确认是否真的必要。

*软件源配置*

Ubuntu 22.04 常在 `/etc/apt/sources.list` 和 `/etc/apt/sources.list.d/` 中保存 `.list` 条目，新式配置也可能使用 deb822 `.sources` 文件。先用 `apt-cache policy` 和只读查看确认本机实际来源：

```bash
cat /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
```

每行定义一个软件源：`deb` 表示二进制包源，URL 是服务器地址，后面是发行版代号和组件。组件的含义：

- `main`：Ubuntu 发行版主要维护范围内的开源软件。
- `restricted`：因许可等原因不能完全按自由软件方式提供、但 Ubuntu 为特定用途提供支持的软件。
- `universe`：由 Ubuntu 社区维护的大量软件，安全维护承诺与 `main` 不完全相同。
- `multiverse`：受许可或其他分发限制的软件，用户需自行核对法律与维护条件。

具体安全支持范围会随发行版、Ubuntu Pro/ESM 状态和包来源变化，应以 `ubuntu-security-status`、包元数据及官方支持说明为准。

*选择镜像源*

当默认镜像延迟高或连接不稳定时，可以从 Ubuntu 官方镜像列表、学校或组织维护的可信镜像中选择与当前发行版匹配的站点。镜像必须及时同步 `jammy`、`jammy-updates` 和 `jammy-security` 等已启用套件；只替换域名而遗漏组件或安全更新会改变可获得的软件集合。

```bash
# 先备份当前主配置并记录 APT 看见的来源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
apt-cache policy

# 使用 Ubuntu 的“软件和更新”图形工具选择下载服务器
software-properties-gtk

# 修改后检查签名、发行版代号和错误，再考虑升级
sudo apt update
```

服务器环境可按镜像方针对 Ubuntu 22.04 的说明使用 `sudoedit` 修改对应 `.list`/`.sources` 文件，但不要把另一个 Ubuntu 版本的完整配置覆盖过来。保留原会话，确认 `apt update` 没有签名、Release 文件或套件错误后再继续。

*PPA：个人软件包存档*

PPA（Personal Package Archive）让 Launchpad 用户为特定 Ubuntu 发行版发布软件包。PPA 不是 Ubuntu 官方仓库的自动审核延伸，其包可能覆盖官方同名包、引入额外依赖，也可能停止维护。

```bash
# 添加 PPA
sudo add-apt-repository ppa:user/ppa-name
sudo apt update

# 移除 PPA
sudo add-apt-repository --remove ppa:user/ppa-name
```

添加前应在 Launchpad 页面核对维护者、目标 Ubuntu 版本、最近构建、源码和签名指纹，并用 `apt-cache policy 包名` 查看候选版本。移除源只阻止未来从该源获取索引，不会自动降级或卸载已经安装的 PPA 包；回退需要单独计划。即使信任维护者，也要考虑账户被接管、密钥轮换和供应链风险。

*手动添加软件源*

有些项目提供自己的软件源。下面只展示组成部分，不是可复制的真实仓库配置；实际 URL、suite、component、架构和密钥指纹必须从目标项目针对 Ubuntu 22.04 的官方文档逐项核对：

```bash
# 1. 以普通用户下载到临时文件，独立核对文档公布的指纹
curl -fL https://packages.example.invalid/repository-key.asc -o repository-key.asc
gpg --show-keys --fingerprint repository-key.asc

# 2. 核对后转换并由管理员安装到专用 keyring；名称仅为示意
gpg --dearmor --output repository-key.gpg repository-key.asc
sudo install -d -m 0755 /etc/apt/keyrings
sudo install -m 0644 repository-key.gpg /etc/apt/keyrings/example.gpg

# 3. 用 signed-by 将该源限制到专用 keyring，再更新索引
# deb [arch=目标架构 signed-by=/etc/apt/keyrings/example.gpg] https://真实仓库 发行版 组件
sudo apt update
```

密钥指纹必须通过独立可信渠道核对，不能只因为密钥与软件来自同一个下载页面就形成自证。不要把网络下载直接管道给高权限命令，也不要无审阅地整段复制文档命令；仓库说明可能已更新、遭到篡改，或针对不同发行版。`signed-by` 缩小了密钥可验证的源范围，但该仓库中的包仍能通过安装脚本修改系统。

==== 从源码编译安装

软件源没有所需版本或构建选项时，可以从源码构建。源码来源、提交或发布标签、依赖版本与配置选项都要记录；“能够编译”只证明当前环境中的这次构建完成，不证明上游代码可信、功能正确或适合部署。

*典型的编译安装流程*

不同项目使用的构建系统和依赖获取方式不同。下面以现代 CMake 项目的隔离构建为示意，真实命令必须以该版本项目文档为准：

```bash
# 1. 获取并核对源码发布包后，解压到专用目录
tar tf software-1.0.tar.gz | less
mkdir software-1.0-source
tar xf software-1.0.tar.gz -C software-1.0-source --strip-components=1

# 2. 安装编译依赖
sudo apt install build-essential cmake  # 基本工具
sudo apt install libxxx-dev             # 项目特定的依赖

# 3. 在源码外配置；用户级前缀便于检查且不需要 root
cmake -S software-1.0-source -B software-1.0-build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$HOME/.local/opt/software-1.0"

# 4. 先按机器内存与负载选择适度并行度
cmake --build software-1.0-build --parallel 4

# 5. 安装到隔离的用户前缀，随后检查该目录中的文件布局
cmake --install software-1.0-build
```

Autotools、Meson、Cargo 等项目有不同命令，不能把 `cmake` 流程套用过去。并行任务数等于 CPU 线程数可能耗尽内存或影响正在运行的机器人进程，应根据实测资源调整。发布版、调试版与项目自定义选项也会改变产物，配置时要保存完整命令和 CMake 输出中的实际取值。

*安装编译依赖*

编译软件通常需要开发版本的库（带 `-dev` 后缀）：

```bash
# 例如，编译使用 OpenCV 的程序
sudo apt install libopencv-dev

# 编译使用 Eigen 的程序
sudo apt install libeigen3-dev

# 编译使用 Qt 的程序
sudo apt install qtbase5-dev
```

开发包通常提供头文件、CMake/pkg-config 元数据、未版本化链接名，有时也包含静态库；具体内容用 `dpkg -L` 核对。运行时包通常提供共享库或程序，但部署究竟需要哪些包应由实际链接、插件加载和包依赖决定，不能只按是否带 `-dev` 后缀推断。

*管理源码安装的软件*

直接从源码安装到某个前缀时，dpkg 不会自动记录这些文件，常见维护成本包括：

- 卸载依赖项目是否生成可靠清单或 uninstall 目标；许多项目没有该目标
- 升级麻烦：需要重新下载、编译、安装
- 可能与系统软件冲突

实验构建优先使用版本化的用户前缀、容器或打包工具的 staging 目录，并保存安装清单。团队部署若要纳入 APT 管理，应编写和审查正式 Debian 包，而不是假定 `checkinstall` 对任意安装过程都能生成完整、可升级的软件包。不要在不清楚安装清单时对 `/usr` 或 `/usr/local` 执行高权限安装。

*编译 OpenCV（示例）*

Ubuntu 仓库提供的 OpenCV 最便于获得安全更新和一致依赖。只有项目确实需要仓库版本未启用的模块或特定补丁时，才值得维护源码构建。下面固定 OpenCV 与 opencv_contrib 的相同标签，并安装到用户前缀；它没有启用 CUDA，CUDA 构建还需单独核对 GPU 架构、工具链和 OpenCV 支持矩阵：

```bash
# 安装依赖
sudo apt install build-essential cmake ninja-build git
sudo apt install libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev
sudo apt install libtbb-dev libjpeg-dev libpng-dev libtiff-dev
sudo apt install libv4l-dev libxvidcore-dev libx264-dev

# 下载固定标签；发布标签仍应通过项目发布信息核对
git clone --branch 4.8.0 --depth 1 https://github.com/opencv/opencv.git opencv-4.8.0
git clone --branch 4.8.0 --depth 1 https://github.com/opencv/opencv_contrib.git opencv_contrib-4.8.0

# 配置到独立构建目录
cmake -S opencv-4.8.0 -B opencv-4.8.0-build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$HOME/.local/opt/opencv-4.8.0" \
        -DOPENCV_EXTRA_MODULES_PATH="$PWD/opencv_contrib-4.8.0/modules" \
        -DWITH_TBB=ON \
        -DWITH_V4L=ON \
        -DWITH_OPENGL=ON \
        -DBUILD_EXAMPLES=OFF

# 编译和安装；并行度按机器资源调整
cmake --build opencv-4.8.0-build --parallel 4
cmake --install opencv-4.8.0-build

# 消费项目中显式提供该前缀，避免与系统 OpenCV 混用
cmake -S my-project -B my-project-build \
      -DCMAKE_PREFIX_PATH="$HOME/.local/opt/opencv-4.8.0"
```

配置阶段必须阅读 CMake 的依赖检测摘要：请求 `WITH_TBB=ON` 不保证 TBB 最终启用，缺少依赖时有的选项会关闭而非报错。源码标签固定了上游版本，却没有固定编译器和全部系统库；团队要复现还需记录系统包版本和构建日志。

==== RoboMaster 常用软件安装

下面按用途列出 Ubuntu 22.04 / ROS 2 Humble 环境中常见的包名。先用 `apt show`、`apt-cache policy` 和项目清单确认真正需要的组件，再让 APT 展示计划；不建议把整段列表一次性全部安装。

*基础开发工具*

```bash
# 编译工具
sudo apt install build-essential cmake cmake-curses-gui ninja-build

# 版本控制
sudo apt install git git-lfs

# 编辑器和 IDE
sudo apt install vim
# VS Code 可通过受信任的 Snap 或供应方仓库安装，来源应与队内方案统一

# 调试工具
sudo apt install gdb valgrind

# 文档工具
sudo apt install doxygen graphviz
```

*核心库*

```bash
# OpenCV（从软件源安装）
sudo apt install libopencv-dev python3-opencv

# Eigen
sudo apt install libeigen3-dev

# fmt 和 spdlog
sudo apt install libfmt-dev libspdlog-dev

# yaml-cpp（配置文件解析）
sudo apt install libyaml-cpp-dev

# Ceres Solver（非线性优化）
sudo apt install libceres-dev

# Google Test
sudo apt install libgtest-dev
```

*ROS 2 安装*

ROS 2 Humble 的 deb 包面向 Ubuntu 22.04。ROS 官方的软件源引导方式和签名密钥会更新，本书不固化一段“下载密钥并以 root 写入”的网络管道；安装时应打开 ROS 2 Humble 官方 deb 安装文档，核对页面适用系统和发布日期，并按上一节的方法验证仓库配置。完成仓库配置后，再检查候选来源并二选一安装桌面版或基础版：

```bash
sudo apt update
apt-cache policy ros-humble-desktop ros-humble-ros-base

# 开发机常选含 RViz 等 GUI 工具的桌面版
sudo apt install ros-humble-desktop

# 无图形车载机可改选基础版，而不是重复安装两套元包
# sudo apt install ros-humble-ros-base

# 安装开发工具
sudo apt install ros-dev-tools
```

安装成功后先在当前 Bash 中执行 `source /opt/ros/humble/setup.bash` 并验证 `ros2 --help`。需要新终端自动加载时，再把下面的条件块编辑进 `~/.bashrc` 一次，而不是反复追加：

```bash
if [ -f /opt/ros/humble/setup.bash ]; then
    source /opt/ros/humble/setup.bash
fi
```

同时安装多个 ROS 发行版或使用工作空间 overlay 时，自动 source 可能掩盖环境顺序问题；队伍应记录每个终端加载的发行版和工作空间链。仓库签名验证成功、包能安装，也不证明所有第三方 ROS 包与本机硬件驱动兼容。

*常用 ROS 2 包*

```bash
# 图像相关
sudo apt install ros-humble-cv-bridge ros-humble-image-transport
sudo apt install ros-humble-camera-info-manager

# TF2
sudo apt install ros-humble-tf2 ros-humble-tf2-ros ros-humble-tf2-geometry-msgs

# 可视化
sudo apt install ros-humble-rviz2 ros-humble-rqt ros-humble-rqt-common-plugins

# 仿真包必须按 ROS/Gazebo 当前兼容表选择，不把旧 Gazebo Classic 包机械加入新环境
```

这组包名是功能示例，不是每个视觉项目的固定依赖。Gazebo Classic 已结束上游生命周期，Humble 项目究竟保留旧仿真环境还是迁移到新版 Gazebo，需要结合现有世界文件、ROS bridge 和维护计划决定。

*串口和硬件相关*

```bash
# 串口通信库
sudo apt install libserial-dev

# 若实际设备确属 dialout 且用户 alice 确需访问，再由管理员授权
sudo usermod -aG dialout alice

# V4L2 相机工具
sudo apt install v4l-utils
v4l2-ctl --list-devices  # 列出摄像头
```

*NVIDIA 相关（如果有 NVIDIA GPU）*

```bash
# 只读列出硬件和 Ubuntu 推荐候选
ubuntu-drivers devices

# 确认候选、Secure Boot、当前内核与回滚入口后，
# 在“软件和更新 → 附加驱动”或维护窗口中安装选定驱动
```

驱动升级可能要求重启，并可能影响显示、内核模块和已有 CUDA 程序。不要照抄固定驱动版本；应按 GPU、Ubuntu 内核和所需 CUDA 支持矩阵选择。x86 主机的 CUDA 仓库流程与 Jetson/JetPack 不同，cuDNN 也要与 CUDA、框架和架构匹配，安装后用目标程序实际验证，而不只看 `nvidia-smi`。

==== 常见问题解决

*依赖问题*

```bash
# 查看 dpkg 记录的未完成状态
dpkg --audit

# 先模拟 APT 的修复方案，重点检查会安装、升级或删除什么
apt --simulate --fix-broken install

# 审阅并确认需要继续运行未完成的配置脚本后再执行
sudo dpkg --configure -a
```

`dpkg --configure -a` 会运行待配置包的维护脚本，不是只读“强制修复”。如果错误来自软件源混用、磁盘已满、损坏下载或脚本自身失败，应先处理相应条件；重复执行同一命令不会自动区分原因。准备使用 `apt --fix-broken install` 时，同样先审阅真实方案再去掉模拟选项。

*锁文件问题*

“无法获取锁”通常表示另一个 APT/dpkg、图形更新器或自动更新服务正在工作，也可能是前一次进程异常终止后系统状态仍需恢复：

```bash
E: Could not get lock /var/lib/dpkg/lock-frontend

# 只读查看相关进程和服务，确认它们是否仍在运行
ps -ef | grep -E '[a]pt|[d]pkg|unattended-upgrade'
systemctl status apt-daily.service apt-daily-upgrade.service
```

正常更新可能需要等待下载、解包或生成 initramfs，不能仅凭几分钟没有终端输出就终止。不要删除 lock 文件：锁的正确性来自持有进程，删路径既不能让并发修改变安全，还可能造成两个包管理器同时写数据库。确认进程确已异常退出后，应检查日志、磁盘空间和 `dpkg --audit`，必要时重启到一致状态或按 Ubuntu 恢复文档处理。

*包被保留*

```bash
# 查看被保留的包
apt-mark showhold

# 只有确认保留原因已消失并评估升级影响后才取消
sudo apt-mark unhold package_name
```

包可能因驱动兼容、项目版本锁定或分阶段发布而被保留。`apt-mark unhold` 只改变本地 hold 标记，不能解决依赖约束；先用 `apt-cache policy package_name` 和团队环境记录确认候选版本。

*清理系统*

```bash
# 先模拟自动依赖清理并审阅清单
apt autoremove --simulate

# 清理下载缓存
sudo apt clean

# 查看当前正在运行的内核，不能删除或替换后假定无需重启验证
uname -r
```

确认模拟结果后才执行实际 `autoremove`，是否加 `--purge` 取决于是否还需保留登记的系统配置。APT 会对内核采用专门的自动移除策略，但不能笼统承诺“永远保留当前和上一个”；清理前应确认可启动内核、`/boot` 空间和恢复入口。

APT 把来源、版本、依赖和已安装状态集中管理，但每次安装、升级和清理仍是一次系统变更。安全更新应及时安排，同时要在维护窗口中审阅方案、保存关键数据、考虑内核/驱动重启，并先在与比赛机器相近的环境验证。开发机、车载机和容器应记录各自的软件源与包版本，不能只凭一条安装命令就假定环境一致。下一节从磁盘上的软件转向正在运行的进程，并继续采用“先观察，再决定是否修改状态”的顺序。


=== 进程与系统监控
// 管理运行中的程序
// - ps, top, htop
// - kill, killall, pkill
// - 前台后台：&, jobs, fg, bg
// - 系统资源：free, df, du
// - 系统服务：systemctl
// === 进程与系统监控

运行程序通常会创建一个或多个进程；每个进程有身份、虚拟地址空间、文件描述符、线程和调度状态等上下文。系统指标只能告诉我们在某段时间观察到什么，不能凭一次高 CPU 或内存快照直接判定程序有 bug。本节按“识别进程 → 连续观察资源 → 查日志或调用行为 → 选择最小干预”的顺序介绍工具，最后再说明如何管理长期服务。

==== 查看进程：ps

`ps`（process status）命令显示系统中的进程信息。它有许多选项，最常用的是 `aux` 组合：

```bash
ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1 169584 13256 ?        Ss   Jan15   0:03 /sbin/init
root         2  0.0  0.0      0     0 ?        S    Jan15   0:00 [kthreadd]
...
alice    12345  2.5  1.2 456789 98765 pts/0    Sl+  10:00   0:30 ./detector_node
alice    12400  0.0  0.0  12345  1234 pts/1    R+   10:30   0:00 ps aux
```

输出的各列含义：

- `USER`：进程所属用户
- `PID`：当前 PID 命名空间中的进程号；进程退出后号码可以复用
- `%CPU`：ps 按自身采样/累计规则计算的 CPU 比例，多线程进程可能超过 100%
- `%MEM`：RSS 相对于物理内存的近似比例
- `VSZ`：虚拟地址空间大小，不等于实际占用的 RAM
- `RSS`：当前驻留内存估计，其中共享页可能在多个进程中重复计入
- `TTY`：控制终端；`?` 表示没有控制终端，但有终端也不代表进程在前台
- `STAT`：进程状态
- `START`：启动时间
- `TIME`：累计 CPU 时间
- `COMMAND`：启动命令

进程状态（STAT）的常见值：

- `R`：运行中（Running）
- `S`：睡眠（Sleeping），等待某个事件
- `D`：不可中断等待，常见于部分内核或 I/O 路径，但单凭状态不能确定原因
- `T`：停止（Stopped）
- `Z`：僵尸进程（Zombie），已终止但父进程未回收
- `+`：前台进程组
- `l`：多线程
- `s`：会话领导者

`ps` 的输出是瞬时快照，显示命令执行那一刻的状态。常用的 `ps` 命令变体：

```bash
# 显示所有进程的详细信息
ps aux

# 显示进程树，展示父子关系
ps auxf
# 或
pstree

# 只显示特定用户的进程
ps -u alice

# 显示特定进程
ps -p 12345

# 在完整命令行中搜索 detector，并显示 PID
pgrep -af detector
12345 ./detector_node
```

`ps | grep` 会把 grep 自身和参数中碰巧含有字符串的进程也列出来。方括号技巧只能减少自身匹配，不能解决名称歧义；优先用 `pgrep` 并核对完整命令行、用户和父进程。

`pgrep` 是专门用于查找进程的工具，比 `ps | grep` 更方便：

```bash
# -a 显示进程名匹配 detector 的 PID 和命令行
pgrep -a detector
12345 ./detector_node

# 只输出 PID
pgrep detector
12345

# 查找特定用户的进程
pgrep -u alice python
```

==== 实时监控：top 和 htop

`ps` 是一次快照，`top` 则按设定间隔重复采样并刷新进程视图：

```bash
top
top - 10:30:00 up 5 days, 12:30,  2 users,  load average: 0.50, 0.45, 0.40
Tasks: 250 total,   1 running, 249 sleeping,   0 stopped,   0 zombie
%Cpu(s):  5.0 us,  2.0 sy,  0.0 ni, 92.5 id,  0.5 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16000.0 total,   8000.0 free,   5000.0 used,   3000.0 buff/cache
MiB Swap:   2000.0 total,   2000.0 free,      0.0 used.  10500.0 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
12345 alice     20   0  456789  98765  12345 S  25.0   0.6   0:30.00 detector_node
12346 alice     20   0  234567  45678   8901 S  10.0   0.3   0:15.00 tracker_node
    1 root      20   0  169584  13256   8456 S   0.0   0.1   0:03.00 systemd
...
```

顶部的系统摘要显示了重要信息：

- *load average*：过去约 1、5、15 分钟处于可运行或某些不可中断等待状态的任务数平均值。它可与 CPU 数量对照，但包含 I/O 等等待，不能把单核 `1.0` 或四核 `4.0` 直接等同于 CPU 满载。
- *Tasks*：进程统计——总数、运行中、睡眠、停止、僵尸
- *%Cpu(s)*：CPU 使用分解——us（用户空间）、sy（内核空间）、id（空闲）、wa（等待 I/O）等
- *Mem/Swap*：内存和交换空间使用情况

在 top 运行时，可以用按键交互：

- `q`：退出
- `h`：显示帮助
- `k`：向进程发送信号（输入 PID 和信号；执行前先核对目标）
- `r`：调整进程优先级（renice）
- `M`：按内存使用排序
- `P`：按 CPU 使用排序
- `1`：显示每个 CPU 核心的使用情况
- `c`：显示完整命令行
- `f`：选择显示哪些列

`htop` 提供交互式进程列表、树视图、过滤和可配置仪表。Ubuntu 安装环境不一定预装：

```bash
sudo apt install htop
htop
```

顶部仪表可显示 CPU、内存和 swap，颜色含义由主题与设置决定；进程列表支持键盘和鼠标操作。它与 top 一样提供观察值，不会自动解释指标升高的原因。

htop 的常用操作：

- `F1`：帮助
- `F2`：设置
- `F3`：搜索进程
- `F4`：过滤进程
- `F5`：树状视图
- `F6`：选择排序列
- `F9`：选择并发送信号（默认信号可在界面中确认）
- `F10`：退出
- `Space`：标记进程（可以同时操作多个）
- `u`：只显示特定用户的进程
- `t`：切换树状/列表视图

机器人系统响应变慢时，htop 可以帮助找出采样期间 CPU 或驻留内存较高的进程，再结合时间戳、线程视图、日志和性能分析工具区分预期负载、I/O 等待、内存增长或其他原因。一次排序结果只是线索，不是根因诊断。

==== 终止进程：kill、killall、pkill

需要请求进程退出、暂停或重新读取配置时，Linux 通常使用信号（signal）。发送信号会改变运行状态；先确认 PID、用户、完整命令行和所属服务，避免在观察与操作之间因 PID 复用而命中另一个进程。由 systemd 管理的进程优先通过对应 service 操作。

`kill` 命令向指定 PID 的进程发送信号：

```bash
# 在刚确认目标身份后发送 SIGTERM，请求进程自行收尾退出
kill -s TERM -- 12345

# 仅在 TERM 超时且已评估状态一致性后发送不可捕获的 SIGKILL
kill -s KILL -- 12345

# 发送 SIGHUP（1），通常用于重新加载配置
kill -HUP 12345
```

常用的信号：

- `SIGTERM`（15）：终止信号，默认信号。进程可以捕获这个信号并进行清理后退出。
- `SIGKILL`（9）：进程不能捕获或忽略，不会运行用户态清理；处于某些内核等待的任务也可能要等相应路径返回后才消失。
- `SIGINT`（2）：中断信号，相当于 Ctrl+C。
- `SIGSTOP`（19）：不可捕获的停止信号；`Ctrl+Z` 通常发送的是可处理的 `SIGTSTP`，两者不等同。
- `SIGCONT`（18）：继续运行暂停的进程。
- `SIGHUP`（1）：历史上表示终端挂起；部分守护进程约定用它重载，但是否支持及重载哪些内容由程序定义。

常见流程是先发送 `SIGTERM`，再按该程序文档规定的超时时间观察状态和日志。强制结束可能留下不完整事务、共享硬件状态或待修复文件，不能把 “进程消失” 当作清理已经完成：

```bash
# 先温和地请求终止
kill -s TERM -- 12345

# 再次核对 PID 与命令；是否升级为 KILL 取决于目标程序和风险
ps -o pid,user,stat,lstart,args -p 12345
```

`killall` 和 `pkill` 可以按名称或模式命中多个进程，方便的同时也扩大了范围。不同 Unix 系统的 `killall` 语义并不统一，本章的描述仅针对 Ubuntu 的 psmisc 实现。先用完全相同的 `pgrep` 条件预览，再优先采用精确名称：

```bash
# 预览名称恰好为 detector_node、属于 alice 的进程
pgrep -a -u alice -x detector_node

# 确认清单后，对同一精确集合发送 TERM
pkill --signal TERM -u alice -x detector_node
```

默认模式是正则表达式，`-f` 还会匹配完整命令行，可能把包装脚本、Shell 或其他参数碰巧相同的任务一并选中。`-n`、`-o` 只按工具看到的启动顺序缩小集合，也不能证明选择的是业务上正确的实例。

ROS 2 图中的节点名与操作系统进程不是一一对应：一个进程可承载多个 component，一个节点也可能由 launch 管理。`ros2 node list` 只能查看图中节点，标准普通节点没有通用的“按节点名强制停止”命令：

```bash
# ROS 2 方式
ros2 node list
/detector_node
/tracker_node

# 结合 launch 输出或进程列表定位宿主进程，再核对 PID
pgrep -af 'detector|tracker'
```

若节点实现了 ROS 2 managed lifecycle，可先通过生命周期接口请求受控转换；由 launch 或 systemd 管理时，则让管理器停止相应单元。只有明确宿主进程和影响范围后，才退回到信号终止。

==== 前台与后台

交互式 Shell 通常把同步启动的命令放入前台进程组并等待它结束；后台作业则让 Shell 先返回提示符。前台/后台描述的是终端作业控制关系，不等于服务是否“在后台运行”或是否脱离会话。

在命令末尾加 `&` 让程序在后台启动：

```bash
./long_running_program &
[1] 12345
 # 立即返回提示符，可以继续工作
```

`[1]` 是作业号，`12345` 是进程 ID。程序在后台运行，但它的输出仍然会显示在终端上（可能会打断你的输入）。

`jobs` 命令列出当前 Shell 的后台作业：

```bash
jobs
[1]+  Running                 ./long_running_program &
[2]-  Stopped                 vim file.txt
```

`+` 表示当前作业（最近操作的），`-` 表示上一个作业。

`fg`（foreground）把后台作业带回前台：

```bash
fg %1      # 把作业 1 带到前台
fg         # 把当前作业（+）带到前台
```

`bg`（background）让暂停的作业在后台继续运行：

```bash
# 运行一个程序
./program
# 按 Ctrl+Z 暂停
^Z
[1]+  Stopped                 ./program

# 让它在后台继续运行
bg %1
[1]+ ./program &
```

如果一个支持这种终端交互的任务预计运行较久，可以用 `Ctrl+Z` 请求暂停，再用 `bg` 继续。全屏终端程序、读取标准输入的任务和自行处理信号的程序可能不适合这样切换；暂停期间也可能导致网络或硬件超时。

后台作业仍继承终端和 Shell 会话。关闭终端时是否收到 `SIGHUP`、收到后是否退出，取决于终端、Shell 和程序。对简单的非交互任务，可以用 `nohup` 明确处理挂起信号和输入输出：

```bash
nohup ./long_running_program </dev/null >long-running.log 2>&1 &
[1] 12345
```

`nohup` 让启动的命令忽略 `SIGHUP`，上例还断开输入并将两类输出写入明确日志。它不处理日志轮转、故障重启、资源限制、启动依赖或机器重启。

另一个选择是使用 `disown` 将已经在后台运行的作业与 Shell 解除关联：

```bash
./program &
[1] 12345
disown %1
# 从当前 Bash 的作业表移除；输入输出关系没有因此自动改变
```

`disown` 的确切 SIGHUP 行为受 Bash 选项和参数影响，而且它不会自动关闭已继承的终端文件描述符。需要恢复交互现场时用 `screen`/`tmux`；需要开机启动、重启策略和集中日志时使用 systemd。它们不能互相无条件替代。

==== 系统资源监控

*内存：free*

`free` 命令显示系统内存使用情况：

```bash
free -h
              total        used        free      shared  buff/cache   available
Mem:           15Gi       5.0Gi       6.0Gi       500Mi       4.0Gi        10Gi
Swap:         2.0Gi          0B       2.0Gi
```

`-h` 选项以人类可读的格式显示（GB、MB）。各列含义：

- `total`：总物理内存
- `used`：已使用内存
- `free`：完全空闲的内存
- `shared`：共享内存（如 tmpfs）
- `buff/cache`：缓冲区和缓存使用的内存
- `available`：可供新程序使用的内存（包括可释放的缓存）

Linux 会利用空闲内存做页缓存，因此 `free` 较低本身不等于内存不足。`available` 是内核根据可回收页等信息给出的估计，比只看 `free` 更有参考价值；是否存在压力还要结合 swap-in/swap-out、回收延迟、OOM 日志和目标进程的时间序列判断，不能设一个适用于所有负载的固定余量。

Swap 可以把部分匿名页移出物理内存。已经使用的 swap 不会在压力解除后必然立即归零，所以“占用高”可能是历史结果；持续的换入换出、延迟上升和 available 下降更能反映当前压力。禁用 swap 也不自动改善实时性，反而可能更早触发 OOM，需要在目标负载下验证。

*磁盘空间：df*

`df`（disk free）显示文件系统的磁盘空间使用情况：

```bash
df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   45G   50G  48% /
/dev/sda2       500G  200G  275G  43% /home
tmpfs           7.8G     0  7.8G   0% /dev/shm
/dev/sdb1       1.0T  500G  500G  50% /data
```

输出显示每个挂载的文件系统的大小、已用空间、可用空间和挂载点。

```bash
# 只显示本地文件系统，排除虚拟文件系统
df -h --local

# 显示特定目录所在的文件系统
df -h /home/alice/projects
```

*目录大小：du*

`du`（disk usage）显示目录或文件占用的磁盘空间：

```bash
# 显示当前目录的总大小
du -sh .
2.5G    .

# 显示各子目录的大小
du -sh */
500M    build/
1.5G    models/
200M    src/
300M    data/

# 显示所有文件和目录
du -ah

# 限制深度
du -h --max-depth=1

# 初步查看非隐藏条目中占用较大的项目
du -sh -- * | sort -rh | head -n 10
```

当磁盘空间不足时，先用 `df` 确定哪个分区满了，再用 `du` 找出占用空间最多的目录：

```bash
df -h
# 发现 /home 分区快满了

# 在自己的家目录按一层深度汇总，包含工具能够读取的隐藏目录
du -h --max-depth=1 "$HOME" | sort -rh | head -n 10
30G     /home/alice
10G     /home/alice/projects
...
```

不要为了扫描其他用户目录就无条件加 `sudo`：这会绕过隐私边界，也会让一次大范围扫描产生明显 I/O。`du` 与 `df` 不一致时还要考虑已删除但仍打开的文件、快照、保留块和不可访问路径；“最大的可见目录”不一定就是空间差异的原因。

*综合监控工具*

除了单独的命令，还有一些综合监控工具：

```bash
# vmstat：虚拟内存统计
vmstat 1      # 每秒刷新一次
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0      0 6000000 200000 4000000  0    0     5    10  200  500  5  2 92  1  0

# iostat：I/O 统计（由 sysstat 包提供，机器未安装时需先评估再安装）
iostat -xh 1
Device      r/s     w/s     rkB/s   wkB/s  %util
sda        10.00   20.00   500.0k   1.0M   5.00

# iotop：实时 I/O 监控（需要安装）
sudo apt install iotop
sudo iotop

# nethogs：网络流量监控（按进程）
sudo apt install nethogs
sudo nethogs
```

这些工具的字段与权限需求取决于内核、版本和容器环境。以 root 运行监控工具会让它看到更广范围的数据，也扩大工具自身的权限；先使用普通权限，只有明确缺少哪项观测且信任该工具时再提权。采样工具会带来一定开销，高频采样尤其要避免直接留在比赛进程旁长期运行。

==== 系统服务：systemd 和 systemctl

Ubuntu 22.04 使用 systemd 作为系统级初始化与服务管理器，系统实例通常以 PID 1 运行。它管理由单元声明的服务、挂载点、定时器等，并通过 cgroup 跟踪进程；这不表示机器上的每个进程都直接由一个 `.service` 单元单独启动。

`systemctl` 是与 systemd 交互的命令。服务在 systemd 中被称为“单元”（unit），服务单元的后缀是 `.service`。

*查看服务状态*

```bash
# 查看服务状态
systemctl status ssh
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/lib/systemd/system/ssh.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-01-15 10:00:00 CST; 5 days ago
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 1234 (sshd)
      Tasks: 1 (limit: 18904)
     Memory: 5.0M
        CPU: 1.234s
     CGroup: /system.slice/ssh.service
             └─1234 sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups

Jan 15 10:00:00 hostname systemd[1]: Started OpenBSD Secure Shell server.
```

状态输出汇总加载状态、当前活动状态、主进程、cgroup 和最近日志。`enabled` 与 `active` 是两回事：前者描述某些启动依赖是否已建立，后者描述当前状态；单次 `status` 仍只是快照，退出码也应在脚本中检查。

*启动、停止、重启服务*

```bash
# 启动服务
sudo systemctl start ssh

# 停止服务
sudo systemctl stop ssh

# 重启服务
sudo systemctl restart ssh

# 重新加载配置（不中断服务）
sudo systemctl reload ssh

# 如果不确定是否支持 reload
sudo systemctl reload-or-restart ssh
```

`reload` 是否存在、能否无中断应用全部配置由服务实现决定；`reload-or-restart` 在不能 reload 时会重启，并不保证连接不断。修改 SSH、网络或机器人控制服务前，先运行服务自身的配置检查，确认备用连接或安全停机方式，再在维护窗口操作。

*设置开机自启*

```bash
# 设置开机自启
sudo systemctl enable ssh

# 取消开机自启
sudo systemctl disable ssh

# 同时启动并设置开机自启
sudo systemctl enable --now ssh
```

`enable` 通常创建启动依赖链接，不保证服务现在启动，也不保证下次启动成功；`--now` 才同时请求当前启动。启用前应检查单元来源、依赖和暴露的网络端口，不要因为某软件已安装就自动开启其服务。

*查看所有服务*

```bash
# 列出所有服务
systemctl list-units --type=service

# 列出所有服务（包括未运行的）
systemctl list-units --type=service --all

# 列出启用的服务
systemctl list-unit-files --type=service --state=enabled

# 列出失败的服务
systemctl --failed
```

*查看服务日志*

systemd 有自己的日志系统 journald，用 `journalctl` 查看：

```bash
# 查看特定服务的日志
journalctl -u ssh

# 查看最近的日志
journalctl -u ssh -n 50

# 实时追踪日志
journalctl -u ssh -f

# 查看本次启动以来的日志
journalctl -u ssh -b

# 查看特定时间范围的日志
journalctl -u ssh --since "2024-01-15 10:00:00" --until "2024-01-15 12:00:00"
```

journal 是否持久保存、普通用户能看到哪些字段以及磁盘保留多久由 journald 配置和组权限决定。没有查到旧日志可能是未持久化、已轮转或权限不足，不能直接推断服务当时没有报错。

*创建自己的服务*

系统级自定义单元通常安装到 `/etc/systemd/system/`。先在普通用户可写目录创建并审阅文件，再由管理员安装；示例中的用户名、路径、包名和网络依赖都必须替换为本机已经验证的值：

```bash
nano rm-vision.service
```

服务文件内容：

```ini
[Unit]
Description=RoboMaster Vision System
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
User=alice
WorkingDirectory=/home/alice/ros2_ws
ExecStart=/bin/bash -c 'source /opt/ros/humble/setup.bash && source /home/alice/ros2_ws/install/setup.bash && exec ros2 launch rm_vision vision_launch.py'
Restart=on-failure
RestartSec=5
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
```

配置说明：

- `[Unit]` 部分描述服务和依赖关系
- `Wants`/`After=network-online.target` 请求并排序到“网络在线”目标之后；它是否真正等待可用链路取决于相应 wait-online 服务，应用仍要处理断网和重连
- `[Service]` 部分定义如何运行服务
- `Type=simple` 表示 ExecStart 启动的进程就是主进程
- `User` 指定运行服务的用户
- `Restart=on-failure` 会在 systemd 认定失败时重启，配合 StartLimit 限制快速失败循环；它不能修复程序状态或保证硬件安全
- `[Install]` 部分定义如何启用服务

先验证语法和引用路径，再安装并只启动当前会话观察：

```bash
# 只读检查本地单元；警告和依赖缺失也要处理
systemd-analyze verify ./rm-vision.service

# 审阅无误后安装到系统级目录并重新加载配置
sudo install -m 0644 rm-vision.service /etc/systemd/system/rm-vision.service
sudo systemctl daemon-reload

# 先启动但暂不设置开机自启
sudo systemctl start rm-vision

# 普通用户通常可以查看状态和日志
systemctl status rm-vision
journalctl -u rm-vision -b -n 100

# 完成停机、故障、设备缺失和重启测试后，才考虑开机自启
sudo systemctl enable rm-vision
```

单元能启动只说明这次启动路径可用。比赛部署还要验证工作空间已安装且不会被临时构建覆盖、运行用户具有精确设备权限、停止信号能让执行器进入安全状态、日志有容量上限、重复崩溃不会持续抢占资源，以及网络/相机迟到时能够恢复。对只需当前用户运行的任务，也可以评估 systemd user service，但登录和 linger 行为与系统服务不同。

*常用系统服务*

一些 RoboMaster 开发中可能遇到的系统服务：

```bash
# SSH 服务
systemctl status ssh

# 网络管理
systemctl status NetworkManager

# 时间同步
systemctl status systemd-timesyncd

# Docker（如果安装了）
systemctl status docker

# 查看所有 ROS 相关服务（如果有）
systemctl list-units | grep ros
```

==== 实际应用场景

让我们看一些 RoboMaster 开发中的实际场景。

*排查程序占用过多资源*

```bash
# 系统响应变慢时，先采样并记录时间与负载
htop
# 观察到 detector_node 在多个采样周期中 CPU 较高

# 精确查看候选进程的身份、状态、启动时间和完整参数
pgrep -af detector_node
ps -o pid,ppid,user,stat,lstart,%cpu,%mem,args -p 12345
12345 12000 alice Rl+ Mon Jan 15 10:00:00 2024 99.0 5.0 ./detector_node

# 在允许附加且能接受观测开销时，进一步观察系统调用
strace -p 12345

# 确认需要停止且不是由服务管理器托管后，请求受控退出
kill -s TERM -- 12345
```

高 CPU 可以来自预期图像处理、输入频率上升、忙等或死循环，当前观察尚不能区分。`strace` 只显示系统调用，纯用户态计算可能几乎没有输出；附加 `gdb` 通常会暂停或扰动目标进程，并受 ptrace 权限限制。应结合程序日志、线程级采样、输入负载和可复现实验再判断机制。

*监控 ROS 2 节点资源使用*

```bash
# 查找命令行候选，再核对进程与节点/component 的映射
pgrep -af 'ros2|detector|tracker|aim'

# 已确认 PID 后只显示对应宿主进程
htop -p 12345
```

*处理僵尸进程*

```bash
# 精确筛选 STAT 以 Z 开头的条目
ps -eo stat=,pid=,ppid=,user=,args= | awk '$1 ~ /^Z/'
Z  12345  12300  alice  [worker] <defunct>

# 找到父进程
ps -o ppid= -p 12345
12300

# 查看父进程身份与日志，确认它为何没有 wait/reap
ps -o pid,ppid,user,stat,lstart,args -p 12300
```

僵尸进程已经结束，不再执行代码，残留的是供父进程读取的退出状态。无法通过向僵尸本身发送 `SIGKILL` 清理；正确修复是让父进程执行 `wait`，或修复/受控重启有缺陷的父进程。直接终止父进程可能同时中断其他子任务，只有在了解监督关系和恢复策略后才考虑。

*释放磁盘空间*

```bash
# 检查磁盘使用
df -h
# /home 快满了

# 在自己的家目录按一层深度找占用较大的路径
du -h --max-depth=1 "$HOME" | sort -rh | head -n 10
30G     /home/alice/ros2_ws
20G     /home/alice/data

# 先分别核对 ROS 2 工作空间中的生成目录
du -sh -- "$HOME/ros2_ws/build" "$HOME/ros2_ws/install" "$HOME/ros2_ws/log"

# 预览 APT 自动依赖方案；缓存是否值得清理由上面的占用结果决定
apt autoremove --simulate
du -sh /var/cache/apt/archives/

# 查询 pip 自己管理的缓存位置和大小
python3 -m pip cache dir
python3 -m pip cache info
```

只有确认 `build`、`install`、`log` 完全可由当前源码和记录的环境重建，且没有运行进程依赖其中内容时，才删除精确目录；删除后还应预计完整重编译时间。APT、pip 等缓存优先使用各自的 `clean`/`cache purge` 子命令，并在执行前确认会失去哪些离线复用能力。最大的目录只是空间线索，不能据此跳过内容和备份检查。

本节把一次快照、连续采样、日志、进程关系和状态变更区分开来。监控结果先用来界定“哪个进程在什么时段出现了什么现象”，再通过更有区分力的检查定位原因；终止、重启和清理都不应代替诊断。systemd 能统一启动、停止、日志和有限的重试策略，但可靠性仍取决于程序安全停机、依赖就绪、重启限制和实机故障测试。下一节将这些原则带到网络与远程操作中。


=== 网络与远程访问
// 连接与远程操作
// - 网络信息：ip addr, ping
// - 下载：wget, curl
// - SSH 远程连接与密钥认证
// - 文件传输：scp, rsync
// - SSH 在机器人开发中的用途
// === 网络与远程访问

Jetson、工控机等车载计算机常以无显示器方式部署，开发者通过有线或无线网络查看状态、传输文件和维护服务。SSH 提供加密的远程登录与转发能力，但网络可达、主机身份验证、账户授权和机器人现场安全缺一不可。本节先用分层检查定位网络问题，再介绍下载、SSH、文件同步和谨慎修改网络配置的方法。

==== 查看网络信息

在连接网络之前，首先要了解本机的网络配置。`ip` 命令是现代 Linux 系统查看和配置网络的标准工具。

查看网络接口和 IP 地址：

```bash
ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:12:34:56 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic enp0s3
       valid_lft 86400sec preferred_lft 86400sec

3: wlp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether a4:5e:60:ab:cd:ef brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.101/24 brd 192.168.1.255 scope global dynamic wlp2s0
       valid_lft 86400sec preferred_lft 86400sec
```

示例中的 `lo` 是回环接口，`enp0s3` 和 `wlp2s0` 分别代表某台机器上的有线与无线接口。真实名称受固件、总线、udev 和配置影响，不能在脚本里照抄。`link/ether` 显示链路层地址，`inet` 显示 IPv4 地址与前缀；一个接口可以有多个 IPv4/IPv6 地址。

常用的 `ip` 命令变体：

```bash
# 简洁显示 IP 地址
ip -br addr
lo               UNKNOWN        127.0.0.1/8 
enp0s3           UP             192.168.1.100/24 
wlp2s0           UP             192.168.1.101/24 

# 显示路由表
ip route
default via 192.168.1.1 dev enp0s3 proto dhcp metric 100 
192.168.1.0/24 dev enp0s3 proto kernel scope link src 192.168.1.100 

# 显示网络接口的链路状态
ip link
```

旧资料常使用 net-tools 提供的 `ifconfig`，Ubuntu 的现代网络排查通常使用 iproute2 的 `ip` 和 `ss`。两套命令的输出与功能并非逐项完全等价，转换教程时应重新核对参数。

`ping` 发送 ICMP Echo Request 并观察回应，可测量这一类报文的往返时间和丢失情况：

```bash
ping 192.168.1.1
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=1.23 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=64 time=0.98 ms
64 bytes from 192.168.1.1: icmp_seq=3 ttl=64 time=1.05 ms
^C
--- 192.168.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.980/1.086/1.230/0.104 ms
```

Ubuntu 的 `ping` 默认持续发送，直到 `Ctrl+C` 中断；`-c` 可以限制数量。统计值只覆盖该时间段的 ICMP 样本，防火墙或主机策略可能禁止回应，因此 ping 失败不证明主机或 SSH 一定不可达；ping 成功也不证明目标 TCP 端口和应用正常。

```bash
# 只发送指定数量的包
ping -c 4 192.168.1.1

# 先用系统名称服务解析域名
getent ahosts example.com

# 指定间隔时间（秒）
ping -i 0.5 192.168.1.1
```

排查时把接口、地址、路由、名称解析和具体服务分开检查：

```bash
# 检查本地网络栈
ping 127.0.0.1

# 检查网关（路由器）
ping 192.168.1.1

# 查看访问目标地址将采用的路由、源地址和接口
ip route get 192.168.1.50

# 检查 DNS 解析
getent ahosts example.com

# 最后测试目标 SSH 服务与已配置的非交互认证，并设置有限超时
ssh -o BatchMode=yes -o ConnectTimeout=5 alice@192.168.1.50 true
```

例如，接口没有 carrier、没有地址和路由选择错误是不同观察；网关 ICMP 不响应也可能只是其策略。域名解析失败才把线索指向 resolver 配置或 DNS 服务，仍需用 `resolvectl status/query`、`getent` 和日志区分本机、网络与上游。最后一条 SSH 命令不会弹出密码提示：成功说明目标服务可达且现有非交互认证可用；失败也可能只是尚未配置密钥，不能单凭它认定 22 端口或 sshd 异常。只有具体 SSH 连接失败时，才继续结合 `ssh -v`、防火墙和服务日志定位，而不是由一条 ping 结果直接下诊断。

其他有用的网络诊断工具：

```bash
# 追踪路径（traceroute 和 dig 通常由额外软件包提供）
traceroute example.com

# 显示网络连接和监听端口
ss -tuln
# -t TCP, -u UDP, -l 监听, -n 数字显示

# 查看 DNS 解析
resolvectl query example.com
dig example.com

# 查看主机名
hostname
hostname -I  # 显示主机已配置地址的简表，顺序和范围不适合作为脚本接口
```

==== 下载文件：wget 和 curl

`wget` 和 `curl` 都能通过 HTTPS 获取内容。成功写出文件只证明客户端完成了这次传输；发布方身份、版本、散列/签名、文件格式与执行安全仍需另行验证。

`wget` 专注于下载文件，简单直接：

```bash
# 下载文件
wget https://example.com/file.tar.gz

# 下载并指定保存的文件名
wget -O myfile.tar.gz https://example.com/file.tar.gz

# 尝试断点续传；服务器需支持，远端内容还必须保持一致
wget -c https://example.com/large_file.zip

# 后台下载
wget -b https://example.com/large_file.zip
# 日志保存在 wget-log

# 限速下载（避免占满带宽）
wget --limit-rate=1M https://example.com/file.zip

# 递归下载会产生大量请求，只有站点许可且范围明确时才使用
# wget -r -np -k https://docs.example.com/approved-path/
```

`-O` 会写入指定路径，已有文件可能被覆盖；`-c` 对错误的本地残片或已经变化的远端文件也可能产生无效结果。下载发布物时优先写入新名称，并用发布方独立提供的 SHA-256 或签名核验。递归抓取还要遵守站点条款、访问频率和存储范围。

`curl` 功能更丰富，支持更多协议，常用于 API 调用和脚本：

```bash
# 下载文件（默认输出到标准输出）
curl https://example.com/file.txt

# 对 HTTP 错误返回失败、跟随重定向并保存到明确新文件名
curl -fL -o file.txt https://example.com/file.txt

# 跟随重定向
curl -L https://example.com/redirect

# 显示响应头
curl -I https://example.com

# POST 表单数据（-d 已使 curl 采用 POST）
curl -fS -d "data=value" https://api.example.com/endpoint

# 发送 JSON 数据
curl -fS -H "Content-Type: application/json" \
       -d '{"key": "value"}' https://api.example.com/endpoint

# 只写用户名，让 curl 交互提示密码，避免把密码直接放入命令历史
curl -fS --user username https://example.com/protected
```

脚本中的凭据应来自权限受控的凭据文件、agent 或秘密管理机制，并避免出现在命令行、日志和调试输出中。`-f` 让常见 HTTP 4xx/5xx 返回非零，但 API 仍可能用 2xx 返回业务错误；必须按协议检查响应体和状态。

在 RoboMaster 开发中，这些工具常用于：

```bash
# 下载到明确文件名，随后按发布页核对版本与散列
curl -fL -o model-v1.0.onnx https://releases.example.invalid/model-v1.0.onnx

# 下载源码发布包时保留版本号，不直接覆盖项目目录
curl -fL -o opencv-4.8.0.tar.gz \
  https://github.com/opencv/opencv/archive/refs/tags/4.8.0.tar.gz
```

`.invalid` 域名在示例中故意不可用，用来提醒读者替换为项目正式发布地址。不要把下载内容直接管道给 `sudo`、Shell 或包管理命令；先保存、验证并阅读将要执行的内容。

==== SSH：远程登录与执行命令

SSH（Secure Shell）在客户端与服务端之间建立加密连接，并通过主机密钥验证服务器身份，再按密码、公钥等方式认证用户。加密不能弥补错误接受主机密钥、泄露私钥或远端账户权限过大，因此首次连接验证是流程的一部分。

*基本连接*

```bash
# 连接到远程主机
ssh username@hostname
ssh alice@192.168.1.50

# 使用非默认端口
ssh -p 2222 alice@192.168.1.50

# 首次连接会提示确认主机指纹
The authenticity of host '192.168.1.50 (192.168.1.50)' can't be established.
ED25519 key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

首次连接时，不应看到提示就直接输入 `yes`。应通过设备控制台、队内资产清单或管理员提供的独立可信渠道核对完整指纹；确认后，主机密钥记录会写入 `~/.ssh/known_hosts`（也可能采用散列主机名）。以后密钥变化可能来自重装、IP 被另一台设备复用、密钥轮换或中间人攻击，在原因独立确认前不要用 `ssh-keygen -R` 机械删除警告。

连接成功后，你会看到远程主机的 Shell 提示符，可以像在本地一样执行命令：

```bash
alice@robot:~$ ls
ros2_ws  projects

alice@robot:~$ ros2 node list
/detector_node
/tracker_node

alice@robot:~$ exit  # 或 Ctrl+D 退出
Connection to 192.168.1.50 closed.
```

*执行单个命令*

不需要交互式 Shell 时，可以直接在 SSH 命令后附加要执行的命令：

```bash
# 远程执行单个命令
ssh alice@192.168.1.50 'pwd; ls -la'

# 远程执行多个命令
ssh alice@192.168.1.50 'cd "$HOME/ros2_ws" && colcon build'

# 查看远程系统状态
ssh alice@192.168.1.50 "free -h && df -h"
```

外层单引号让 `$HOME` 等内容留到远端 Shell 展开；使用双引号时，本地 Shell 可能先展开变量和通配符。远程命令仍会修改远端状态，长时间构建还可能在网络断开后收到信号；先确认远端目录、版本和资源，不要把 SSH 当作无条件重试接口。

*SSH 密钥认证*

公钥认证用私钥证明客户端身份，服务器只保存对应公钥。它减少了重复输入账户密码的需要，也便于逐个撤销密钥；安全性仍取决于算法、私钥保护、passphrase、服务端策略和账户权限。

生成密钥对：

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/alice/.ssh/id_ed25519): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/alice/.ssh/id_ed25519
Your public key has been saved in /home/alice/.ssh/id_ed25519.pub
```

这会生成 `id_ed25519` 私钥和 `id_ed25519.pub` 公钥。私钥不得复制给他人，公钥也应按设备和用途登记。passphrase 会加密磁盘上的私钥；攻击者拿到文件但不知道 passphrase 时更难直接使用。空 passphrase 虽便于无人值守，却使文件一旦泄露即可被尝试使用，自动化场景应结合专用低权限账户、受限 `authorized_keys` 和密钥轮换。

将公钥复制到远程主机：

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub alice@192.168.1.50
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s)
...
Number of key(s) added: 1
```

`ssh-copy-id` 会在通过现有认证登录后，把选定公钥追加到远端 `authorized_keys`。执行前用 `-i ~/.ssh/id_ed25519.pub` 明确要部署的键，并在保持原会话的情况下开第二个终端验证新登录，避免误部署后锁住自己。连接时仍可能要求私钥 passphrase、硬件令牌或服务端配置的其他认证步骤。

```bash
ssh alice@192.168.1.50
# 直接进入，无需密码
alice@robot:~$
```

如果没有 `ssh-copy-id`，可以由远端管理员核对并把完整的一行公钥加入目标账户的 `authorized_keys`。不要把下面的缩略示例原样追加，也不要通过聊天工具传输私钥：

```bash
# 查看公钥
cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxx... your_email@example.com

# 远端管理员应检查目录所有者，并采用保守权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

OpenSSH 的 `StrictModes` 检查会关注文件、父目录的所有者和可写权限。设置模式后还要确认所有权；权限警告不能靠关闭检查或放宽到 `777` 解决。

*SSH 配置文件*

频繁连接多台机器时，每次输入完整的用户名和地址很繁琐。可以在 `~/.ssh/config` 中配置别名：

```bash
nano ~/.ssh/config
```

配置中可能包含内部地址、用户名和代理关系，应把文件设为仅自己可写，并避免随项目公开：`chmod 600 ~/.ssh/config`。

```
# 机器人主机
Host robot
    HostName 192.168.1.50
    User alice
    Port 22

# Jetson 开发板
Host jetson
    HostName 192.168.1.60
    User nvidia
    IdentityFile ~/.ssh/jetson_key

# 跳板机访问内网服务器
Host internal
    HostName 10.0.0.100
    User admin
    ProxyJump jumphost

# 所有主机的通用设置
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

配置后，连接变得简单：

```bash
ssh robot    # 相当于 ssh alice@192.168.1.50
ssh jetson   # 相当于 ssh nvidia@192.168.1.60 -i ~/.ssh/jetson_key
```

`ServerAliveInterval` 让客户端在无服务器数据时发送 SSH 层探测，`ServerAliveCountMax` 控制连续无响应后断开。它能更快发现部分失效连接，也可能避开某些空闲超时，但不能保证网络不断或远程任务继续运行。

*SSH 端口转发*

SSH 可以创建加密隧道，转发端口流量。这在访问远程服务时很有用。

本地端口转发——把远程服务映射到本地：

```bash
# 将远端仅监听回环地址的 8080 服务映射到本地回环地址
ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:8080:localhost:8080 alice@robot
# 现在访问 localhost:8080 就是访问远程的 8080

# 访问远程机器上的 Jupyter Notebook
ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:8888:localhost:8888 alice@robot
```

远程端口转发——把本地服务映射到远程：

```bash
# 让远程机器能访问本地的服务
ssh -N -o ExitOnForwardFailure=yes -R 3000:localhost:3000 alice@robot
```

动态端口转发——创建 SOCKS 代理：

```bash
ssh -N -D 127.0.0.1:1080 alice@robot
# 本地 1080 端口成为 SOCKS 代理
```

`-N` 表示只建立转发而不启动远程 Shell。隧道不会替代被转发服务自身的认证，监听地址还决定本机或远端哪些用户能访问。远程转发能否向其他主机暴露受 `GatewayPorts` 等服务端配置控制；动态转发也只有显式配置为使用 SOCKS 的应用会经过隧道，DNS 解析方式需另行核对。

==== 文件传输：scp 和 rsync

`scp` 通过 SSH 传输文件，现代 OpenSSH 默认使用 SFTP 协议。它的源/目标语法类似 `cp`，但远端 Shell、服务器版本和路径语义仍需核对；同名目标可能被覆盖。

```bash
# 上传文件到远程
scp file.txt alice@192.168.1.50:/home/alice/
scp file.txt robot:~/  # 使用 SSH 配置的别名

# 下载文件到本地
scp alice@192.168.1.50:/home/alice/data.csv ./
scp robot:~/results.txt ./

# 复制整个目录（-r 递归）
scp -r project/ robot:~/

# 使用非默认端口
scp -P 2222 file.txt robot:~/
```

`scp` 通常按文件完整传输。递归复制会把整棵目录送到目标位置，符号链接、权限和特殊文件的处理也不等同于本地 `cp -a`。重要传输后应检查目标清单或散列，不能以命令退出为零推断应用数据已经一致。

对大目录或重复同步，rsync 会比较源和目标，并在适用时只传输变化文件或文件内的差异。源目录结尾的 `/` 很重要：`project/` 表示同步目录内容，`project` 更可能在目标下建立目录本身。

```bash
# 同步目录到远程
rsync -av project/ robot:~/project/
# -a 归档模式（递归并保留常见元数据，但不自动包含 ACL、xattr、hard link）
# -v 显示详细信息

# 从远程同步到本地
rsync -av robot:~/data/ ./data/

# 显示进度
rsync -av --progress large_file.zip robot:~/

# 预览镜像同步中将删除的远端条目，不实际传输
rsync -av --dry-run --itemize-changes --delete project/ robot:~/project/

# 排除某些文件
rsync -av --exclude='build/' --exclude='*.log' project/ robot:~/project/

# 带相同排除规则再次预览完整镜像方案
rsync -av --dry-run --itemize-changes --delete \
  --exclude='build/' --exclude='*.log' project/ robot:~/project/
```

最后一条才是前面 `--delete` 镜像方案的对应预览；dry-run 必须使用与正式命令相同的源、目标、结尾斜杠、排除规则和删除选项。确认后去掉 `--dry-run`，仍应先有目标端备份或快照，因为并发修改、权限差异和网络中断会让正式运行时状态不同。`-z` 可压缩传输，但 ONNX、ZIP 等已压缩文件可能只增加 CPU 开销，应按链路测试。

`rsync` 的增量同步特别适合开发场景：

```bash
# 修改代码后，只同步变化的文件
rsync -av --dry-run --itemize-changes ~/ros2_ws/src/ robot:~/ros2_ws/src/

# 审阅后执行同一同步，再在确认的远端版本目录构建
ssh robot 'cd "$HOME/ros2_ws" && colcon build'
```

同步源码时，版本控制通常比直接覆盖工作目录更容易审计；至少应确认远端没有未提交修改，也不要在构建进程读取文件时并发替换源码。双向同步的冲突策略更复杂，使用 unison、NFS 或 SSHFS 前需明确哪一端拥有最终版本。

*SSHFS：挂载远程目录*

SSHFS 可以把远程目录挂载到本地，像访问本地文件一样访问远程文件：

```bash
# 安装 sshfs
sudo apt install sshfs

# 创建挂载点
mkdir ~/remote_robot

# 挂载远程目录
sshfs robot:/home/alice/ros2_ws ~/remote_robot

# 现在可以直接访问
ls ~/remote_robot
build  install  log  src

# 卸载（Ubuntu 22.04 的 FUSE 3）
fusermount3 -u ~/remote_robot
```

SSHFS 便于临时浏览，但网络抖动、延迟、缓存、权限映射、文件监视和构建工具的原子重命名都可能影响编辑体验。断开前先停止使用挂载点的进程并正常卸载。VS Code Remote-SSH 通常把编辑器后端运行在远端，行为与把远端目录挂成本地文件系统不同，也要核对扩展信任和远端资源占用。

==== SSH 在机器人开发中的用途

在许多 RoboMaster 队伍中，SSH 是维护无显示器车载计算机的常用方式，但不是机器人控制的安全通道或唯一调试方案。串口控制台、现场显示器、日志采集与专用运维系统仍是重要的备用入口。

车载计算机运行时通常不接显示器和键盘，SSH 让开发者从工作站访问其命令行；初装、网络故障和 SSH 配置错误时，仍要准备本地恢复方式。

无线连接可以远程查看状态和日志，但链路会丢包、漫游或中断。机器人运动期间不应依赖临时 SSH 命令承担急停或实时控制，也不应在未进入安全调试状态时在线修改参数；运动控制需要独立、经过验证的通信与失效保护。

多个终端会话可以分别观察节点输出、系统资源和日志。时间戳、主机名和使用的环境应一起记录，否则不同窗口中的输出容易被误配到错误进程或测试轮次。

SSH 支持多个账户同时登录，但这些会话会竞争 CPU、网络、相机和串口，也可能同时修改同一工作区或重启服务。团队应使用个人账户、明确操作负责人并记录变更，不能把“能够同时登录”理解为互不干扰。

一个典型的调试场景：

```bash
# 终端 1：查看检测节点的输出
ssh robot
ros2 topic echo /detector/armors

# 终端 2：监控系统资源
ssh robot
htop

# 终端 3：实时查看日志
ssh robot
tail -f ~/ros2_ws/log/latest/detector_node.log

# 终端 4：先确认远端是否支持 X11 转发，再运行轻量 GUI
ssh -X robot
rqt_image_view
```

X11 转发需要客户端 X server、远端 `xauth` 和 sshd 允许转发；Wayland 环境也可能经过兼容层。它增加信任面并受网络带宽和延迟影响，RViz/图像流尤其可能很慢。优先考虑在本地运行可视化工具并通过经过配置的 ROS 网络读取数据，或使用 Remote-SSH；采用哪种方式要结合 DDS 发现、安全和带宽测试。

使用 `tmux` 或 `screen` 可以让远程会话在断开后继续运行：

```bash
# 在机器人上启动 tmux 会话
ssh robot
tmux new -s vision

# 运行程序
ros2 launch rm_vision vision_launch.py

# 按 Ctrl+B 然后 D 分离会话
# 分离后 tmux 会话继续存在；仍需检查程序本身状态

# 重新连接
ssh robot
tmux attach -t vision
```

tmux 可以避免普通 SSH 断开直接带走终端会话，但程序仍可能因自身错误、资源不足、信号或机器重启终止。长期无人值守测试还需要日志、超时、安全停机和服务监督。

==== 网络配置技巧

在 RoboMaster 场景中，网络配置有一些常见的模式。

*固定 IP 配置*

固定地址、DHCP reservation 和 mDNS 都可以让设备更容易定位。直接设置静态 IP 前要确认网段、网关、DNS、地址冲突和比赛网络规则，并准备本地控制台；远程应用错误配置会立即断开 SSH。

```bash
# 先查看现有 renderer、接口名和所有 netplan 文件
ip -br link
ls -l /etc/netplan/

# 用 sudoedit 修改实际配置文件，而不是照抄示例文件名
SUDO_EDITOR=nano sudoedit /etc/netplan/01-network-config.yaml
```

```yaml
network:
  version: 2
  renderer: networkd  # 桌面版可能实际使用 NetworkManager，不能机械替换
  ethernets:
    enp0s3:  # 替换为本机确认的接口名
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 192.168.1.1
```

```bash
# 先生成并检查，再用带自动回退确认的 try；最好从本地控制台执行
sudo netplan generate
sudo netplan try
```

YAML 缩进、文件权限和多个文件合并都会影响最终配置。`netplan try` 的回退能力也不是所有 renderer/变更都能完全保证；没有本地恢复入口时不要远程试验。生效后分别验证地址、路由、DNS、SSH 和重启后的状态，而不只看一条 ping。

*多机器人网络*

多台机器人共网时，需要规划地址、主机名、DDS 发现范围和安全边界。例如：

```bash
# 机器人 1：192.168.1.50，ROS_DOMAIN_ID=1
# 机器人 2：192.168.1.51，ROS_DOMAIN_ID=2
# 控制站：192.168.1.100

# 可在对应启动脚本或 systemd 单元中按机器人设置，避免污染所有终端
export ROS_DOMAIN_ID=1
```

`ROS_DOMAIN_ID` 影响 DDS domain 的发现范围，但不是访问控制或加密机制；不同 domain 默认互相发现不到，同一 domain 的节点也可能互相干扰。控制站需要匹配目标 domain，或采用明确的 discovery/bridge 方案。可用值还受 DDS 实现和端口范围约束，应按 ROS 2 文档与队内网络规划分配。

*无线热点*

机器人可以创建自己的无线热点，便于笔记本直接连接：

```bash
# 让 NetworkManager 交互询问缺失参数，避免把密码写入命令历史
nmcli --ask device wifi hotspot ifname wlp2s0 con-name RM-Hotspot ssid RoboMaster-Team
```

热点是否可用取决于网卡 AP 模式、NetworkManager 权限、频段与当地无线规则。应使用足够强的凭据，记录恢复方式，并在赛场干扰条件下测试；不要假定自建热点始终比现有网络稳定。

远程维护的可靠流程包括：独立核验主机密钥、使用个人低权限账户、在修改前保留恢复通道、记录文件同步与服务操作，并把急停和实时控制留给专用安全机制。下一节用 Shell 脚本自动化其中可重复的部分，同时防止自动化把一次错误扩大成批量错误。


=== Shell 脚本入门
// 自动化你的工作
// - 第一个脚本与 shebang
// - 变量与用户输入
// - 条件判断：if, test, [[ ]]
// - 循环：for, while
// - 函数
// - 命令行参数与退出状态
// - 实用脚本示例（编译、初始化、备份）
// === Shell 脚本入门

Shell 脚本可以把一组命令、判断和参数处理保存下来，用于构建、检查环境和收集日志。它提高了可重复性，也会以相同速度重复路径错误、未加引号的展开或高权限操作。因此本节不仅讲语法，还把输入验证、退出状态、超时、只读预演和可恢复输出放进示例；系统升级、账户授权和批量删除不会被包装成“一键初始化”。

==== 第一个脚本与 Shebang

让我们从最简单的脚本开始。用你喜欢的编辑器创建一个文件：

```bash
nano hello.sh
```

输入以下内容：

```bash
#!/bin/bash

echo "Hello, RoboMaster!"
echo "Current time: $(date)"
echo "Current directory: $(pwd)"
```

第一行称为 shebang（或 hashbang）。直接执行脚本时，内核用 `#!` 后的路径启动解释器，并把脚本路径传给它；本例明确要求 Bash。没有有效 shebang 的文本文件不应依赖 Shell 的兼容回退行为，调用者应显式选择解释器。

赋予脚本执行权限并运行：

```bash
chmod u+x hello.sh
./hello.sh
Hello, RoboMaster!
Current time: Mon Jan 15 10:30:00 CST 2024
Current directory: /home/alice/scripts
```

`$(command)` 是命令替换：执行括号中的命令，移除其输出末尾的换行，再把剩余文本插入当前位置。放在双引号中可以避免后续单词拆分和通配符展开；命令失败和输出包含内部换行仍要单独处理。

你也可以显式用 bash 运行脚本，这时不需要执行权限：

```bash
bash hello.sh
```

显式运行 `bash hello.sh` 是合法用法，只要求 Bash 能读取该文件；需要把脚本作为 `./hello.sh` 或 PATH 中的命令调用时，再添加最小执行权限并使用准确 shebang。

关于 shebang 的一些变体：

```bash
#!/bin/bash          # 使用 bash
#!/bin/sh            # 使用系统提供的 POSIX sh；Ubuntu 通常是 Dash，不支持全部 Bash 语法
#!/usr/bin/env bash  # 使用当前环境 PATH 选中的 bash
#!/usr/bin/env python3  # Python 脚本也用同样的方式
```

`/usr/bin/env bash` 避免固定 Bash 自身路径，适合受控的多平台用户环境；代价是结果受 PATH 影响，在高权限、服务或可复现部署中可能选到意外解释器。本书固定 Ubuntu 环境时，`#!/bin/bash` 的选择更明确。无论采用哪一种，都应在目标环境用 `bash -n 脚本` 做语法检查，并实际测试关键分支。

==== 变量

变量用于存储数据。在 Bash 中，变量赋值时等号两边不能有空格：

```bash
#!/bin/bash

# 变量赋值（注意：等号两边没有空格）
name="Alice"
project="rm_vision"
version=1.0

# 使用变量（用 $ 前缀）
echo "Hello, $name!"
echo "Working on $project version $version"

# 花括号明确变量边界
echo "Project: ${project}_2024"  # 输出：rm_vision_2024
echo "Project: $project_2024"    # 错误：会查找名为 project_2024 的变量
```

变量名区分大小写。脚本内部变量常用小写或带项目限定的名称，导出的接口变量常用大写；这是约定而非语法规则。不要复用 `HOME`、`PATH` 等已有环境变量存放其他含义。

命令的输出可以赋值给变量：

```bash
#!/bin/bash

# 命令替换
current_date=$(date +%Y-%m-%d)
file_count=$(find . -maxdepth 1 -type f -printf x | wc -c)
git_branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || printf '%s\n' "detached-or-not-a-repository")

echo "Date: $current_date"
echo "Files in current directory: $file_count"
echo "Git branch: $git_branch"
```

一些特殊变量在脚本中很有用：

```bash
$0          # 脚本名称
$1, $2, ... # 命令行参数
$#          # 参数个数
$@          # 只有写成 "$@" 时，才按原边界展开所有位置参数
$*          # 写成 "$*" 时，用 IFS 的首字符连接为一个字符串
$?          # 上一个命令的退出状态
$$          # 当前 Bash 主 Shell 的 PID；子 Shell 场景可再了解 BASHPID
$USER       # 环境中的用户名字符串，不是授权判断依据
$HOME       # 环境中的用户主目录路径
$PWD        # Shell 维护的逻辑工作目录
```

变量展开通常写在双引号中，例如 `printf '%s\n' "$project"` 和 `command -- "$path"`。未加引号的展开会参与单词拆分与通配符匹配，文件名含空格、换行或 `*` 时就会改变参数数量。`$?` 也只保存最近一条命令的状态，若要稍后使用应立即赋给专用变量。

*用户输入*

`read` 命令从用户获取输入：

```bash
#!/bin/bash

IFS= read -r -p "Enter your name: " username || exit 1

IFS= read -r -p "Enter project name: " project || exit 1

echo "Hello, $username! Setting up $project..."

# 带提示的读取
IFS= read -r -p "Continue? [y/N] " answer || exit 1
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    printf '%s\n' "Proceeding..."
fi

# 隐藏输入（用于密码）
IFS= read -r -s -p "Enter password: " password || exit 1
printf '\n'
# 使用后尽快 unset password；Shell 变量仍不是专用秘密存储
```

`IFS=` 与 `-r` 可以保留行首尾空白和反斜杠，检查 `read` 的状态则能区分输入与 EOF。隐藏回显只防止旁观者从屏幕看到字符，密码仍存在于进程内存并可能被后续命令误打印；优先使用能自行安全读取凭据的目标程序。

==== 条件判断

条件判断让脚本能根据情况执行不同的操作。

*if 语句*

```bash
#!/bin/bash

file="config.yaml"

if [[ -f "$file" ]]; then
    echo "Config file exists"
elif [[ -d "$file" ]]; then
    echo "It's a directory, not a file"
else
    echo "Config file not found; no file was created"
    exit 1
fi
```

`[[ ... ]]` 是 Bash 语法，支持模式和正则等功能，并避免其中许多未加引号展开产生单词拆分；面向 `/bin/sh` 的 POSIX 脚本不能使用它。`[ ... ]` 实际是命令形式，变量和操作符需要按其规则引用。两者都不会自动消除检查后文件被替换的竞态。

*文件测试操作符*

```bash
-e file    # 文件存在
-f file    # 是普通文件
-d file    # 是目录
-r file    # 可读
-w file    # 可写
-x file    # 可执行
-s file    # 文件大小大于 0
-L file    # 是符号链接
```

示例：

```bash
#!/bin/bash

workspace="$HOME/ros2_ws"

if [[ ! -d "$workspace" ]]; then
    echo "Workspace not found: $workspace" >&2
    exit 1
fi

if [[ -r "/opt/ros/humble/setup.bash" ]]; then
    source /opt/ros/humble/setup.bash
else
    echo "Readable ROS 2 Humble setup file not found" >&2
    exit 1
fi
```

`source` 需要脚本可读，不要求它带执行位。目录或 setup 文件存在只能确认这一项前提，不能证明 ROS 安装完整；后续仍应检查所需命令与包。

*字符串比较*

```bash
[[ "$str1" == "$str2" ]]   # 相等
[[ "$str1" != "$str2" ]]   # 不相等
[[ -z "$str" ]]            # 字符串为空
[[ -n "$str" ]]            # 字符串非空
[[ "$str" == pattern* ]]   # 模式匹配（支持通配符）
[[ "$str" =~ regex ]]      # 正则表达式匹配
```

示例：

```bash
#!/bin/bash

IFS= read -r -p "Enter ROS distro [humble]: " distro || exit 1

if [[ -z "$distro" ]]; then
    distro="humble"
    echo "Using default: $distro"
fi

if [[ "$distro" == "humble" ]]; then
    echo "Setting up ROS 2 $distro..."
    setup_file="/opt/ros/$distro/setup.bash"
    [[ -r "$setup_file" ]] || { echo "Missing: $setup_file" >&2; exit 1; }
    source "$setup_file"
else
    echo "Unsupported distro for this Ubuntu 22.04 tutorial: $distro" >&2
    exit 1
fi
```

*数值比较*

```bash
[[ $a -eq $b ]]   # 等于
[[ $a -ne $b ]]   # 不等于
[[ $a -lt $b ]]   # 小于
[[ $a -le $b ]]   # 小于等于
[[ $a -gt $b ]]   # 大于
[[ $a -ge $b ]]   # 大于等于

# 或者使用 (( )) 进行算术比较
(( a == b ))
(( a < b ))
(( a >= b ))
```

示例：

```bash
#!/bin/bash

IFS= read -r -p "Maximum retry count: " retry_count || exit 1
if [[ ! "$retry_count" =~ ^[0-9]+$ ]]; then
    echo "Retry count must be a non-negative integer" >&2
    exit 2
fi

if (( retry_count > 10 )); then
    echo "Refusing a retry count above 10" >&2
    exit 2
elif (( retry_count == 0 )); then
    echo "Retries disabled"
else
    echo "Retry count: $retry_count"
fi
```

解析 `top` 的本地化显示再把一个字段称为“CPU 正常/过高”，既脆弱也缺少负载基准，因此这里改用可验证的整数输入展示算术比较。Bash 算术表达式会继续解释变量内容，来自用户或文件的值应先用正则限制格式，再放入 `(( ... ))`。

*逻辑操作符*

```bash
[[ condition1 && condition2 ]]   # AND
[[ condition1 || condition2 ]]   # OR
[[ ! condition ]]                # NOT
```

==== 循环

*for 循环*

遍历列表：

```bash
#!/bin/bash

# 遍历列表
for fruit in apple banana orange; do
    echo "I like $fruit"
done

# 遍历匹配文件；没有匹配时展开为空，而不是字面量 *.cpp
shopt -s nullglob
for file in ./*.cpp; do
    echo "Processing $file..."
    # 对每个文件执行操作
done

# 先捕获并检查生产者状态，再按行读取
package_output=$(ros2 pkg list) || { echo "ros2 pkg list failed" >&2; exit 1; }
if [[ -n "$package_output" ]]; then
    while IFS= read -r pkg; do
        echo "Found package: $pkg"
    done <<< "$package_output"
fi

# 遍历数组
packages=("rm_vision" "rm_control" "rm_description")
for pkg in "${packages[@]}"; do
    echo "Building $pkg..."
done
```

C 风格的 for 循环：

```bash
#!/bin/bash

# 数字循环
for ((i = 1; i <= 10; i++)); do
    echo "Iteration $i"
done

# 使用花括号展开
for i in {1..10}; do
    echo "Count: $i"
done

# 带步长
for i in {0..100..10}; do
    echo "Step: $i"
done
```

*while 循环*

```bash
#!/bin/bash

# 基本 while 循环
count=1
while (( count <= 5 )); do
    echo "Count: $count"
    ((count++))
done

# 读取文件的每一行
while IFS= read -r line; do
    echo "Line: $line"
done < "input.txt"

# 有限次轮询，避免条件永远不满足时永久挂起
for ((attempt = 1; attempt <= 12; attempt++)); do
    echo "Checking system status..."
    sleep 5
done
```

等待条件满足：

```bash
#!/bin/bash

# 最多等待 30 秒看到精确节点名
echo "Waiting for detector_node..."
found=false
for ((attempt = 1; attempt <= 30; attempt++)); do
    if ros2 node list 2>/dev/null | grep -Fxq '/detector_node'; then
        found=true
        break
    fi
    sleep 1
done

if [[ "$found" != true ]]; then
    echo "Timed out waiting for /detector_node" >&2
    exit 1
fi
echo "Node name appeared in the ROS graph"
```

节点出现在图中只证明 discovery 在该时刻看到了名称，不证明订阅、硬件或处理循环健康。可靠就绪检查应查询节点提供的生命周期状态、诊断或项目定义的健康接口。用 `/tmp/ready.flag` 这类可预测共享文件作为安全就绪信号还会遇到旧文件、权限和伪造问题，因此不再作为示例。

*循环控制*

```bash
#!/bin/bash

for i in {1..10}; do
    if (( i == 5 )); then
        continue  # 跳过本次迭代
    fi
    if (( i == 8 )); then
        break     # 退出循环
    fi
    echo "Number: $i"
done
# 输出：1 2 3 4 6 7
```

==== 函数

函数让你可以将代码组织成可重用的块：

```bash
#!/bin/bash

# 定义函数
greet() {
    local person=${1:?"greet requires a name"}
    printf 'Hello, %s!\n' "$person"
}

# 调用函数
greet "Alice"
greet "Bob"

# 带多个参数的函数
log_message() {
    local level=${1:?"log level required"}
    local message=${2:?"log message required"}
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S") || return 1
    printf '[%s] [%s] %s\n' "$timestamp" "$level" "$message"
}

log_message "INFO" "Starting application"
log_message "ERROR" "Connection failed"
```

Bash 函数用 `return` 设置 0 到 255 范围内的退出状态，约定 0 表示该操作成功。需要传出文本时可以写标准输出并由调用者捕获，但命令替换会去掉末尾换行，函数中的日志也会混入结果；较复杂数据更适合数组、文件或其他语言的结构化接口。

```bash
#!/bin/bash

# 只检查本书所用 Humble 环境脚本是否可读，并返回退出状态
has_humble_setup() {
    if [[ -r "/opt/ros/humble/setup.bash" ]]; then
        return 0  # 成功/真
    else
        return 1  # 失败/假
    fi
}

if has_humble_setup; then
    echo "ROS 2 Humble setup file is readable"
fi

# 根据本书支持范围返回发行版标签；只把结果写到标准输出
get_ros_distro() {
    [[ -r "/opt/ros/humble/setup.bash" ]] || return 1
    printf '%s\n' "humble"
}

distro=$(get_ros_distro) || { echo "ROS 2 Humble setup not found" >&2; exit 1; }
echo "Detected ROS 2 distro: $distro"

# 返回计算结果
add_numbers() {
    local a=${1:?"first integer required"}
    local b=${2:?"second integer required"}
    [[ "$a" =~ ^-?[0-9]+$ && "$b" =~ ^-?[0-9]+$ ]] || return 2
    printf '%d\n' "$((a + b))"
}

result=$(add_numbers 5 3) || { echo "Invalid integer input" >&2; exit 1; }
echo "5 + 3 = $result"
```

==== 命令行参数与退出状态

处理命令行参数让脚本更灵活：

```bash
#!/bin/bash

# 简单的参数处理
echo "Script name: $0"
echo "First argument: $1"
echo "Second argument: $2"
printf 'Argument: <%s>\n' "$@"
echo "Number of arguments: $#"

# 检查参数
if (( $# < 1 || $# > 2 )); then
    echo "Usage: ${0##*/} <project_name> [Debug|Release]" >&2
    exit 2
fi

project_name="$1"
build_type="${2:-Release}"  # 默认值

case "$build_type" in
    Debug|Release) ;;
    *) echo "Unsupported build type: $build_type" >&2; exit 2 ;;
esac

echo "Building $project_name in $build_type mode"
```

更复杂的参数解析可以用 `getopts`：

```bash
#!/bin/bash

# 默认值
verbose=false
output_dir="./output"
config_file=""

# 显示帮助
show_help() {
    echo "Usage: ${0##*/} [-v] [-o output_dir] [-c config_file] <input>"
    echo "  -v              Verbose mode"
    echo "  -o output_dir   Output directory (default: ./output)"
    echo "  -c config_file  Configuration file"
    echo "  -h              Show this help"
}

# 解析选项
while getopts "vo:c:h" opt; do
    case $opt in
        v)
            verbose=true
            ;;
        o)
            output_dir="$OPTARG"
            ;;
        c)
            config_file="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done

# 移除已处理的选项，剩下的是位置参数
shift "$((OPTIND - 1))"

# 检查必需参数
if [[ $# -ne 1 ]]; then
    echo "Error: Expected exactly one input file" >&2
    show_help
    exit 1
fi

input_file="$1"

if [[ ! -f "$input_file" ]]; then
    echo "Input is not a regular file: $input_file" >&2
    exit 2
fi

# 使用参数
echo "Input: $input_file"
echo "Output: $output_dir"
echo "Config: $config_file"
echo "Verbose: $verbose"
```

*退出状态*

每条简单命令都有 0 到 255 的退出状态。0 通常表示该命令完成了所定义的成功条件，非零的具体含义必须查命令文档：例如 grep 的 1 表示没有匹配，diff 的 1 表示发现差异，并不都等同于运行错误。脚本应为自己的接口定义并返回状态：

```bash
#!/bin/bash

# 检查命令是否成功
if ! colcon build; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"
exit 0
```

`set` 可以改变 Bash 对部分错误的处理：

```bash
#!/bin/bash

set -e  # 对未处于条件等豁免上下文中的非零状态请求退出
set -u  # 使用未定义变量时报错
set -o pipefail  # 管道中任何命令失败则整体失败

# 通常组合使用
set -euo pipefail

# 这条简单命令失败时会触发 -e
cd /nonexistent_dir  # 这里会失败并退出
echo "This won't be printed"
```

`set -e` 在 `if`/`while` 条件、`&&`/`||` 列表、命令替换和函数调用等上下文中有例外，不能替代逐项错误处理；`set -u` 也要求可选参数写成 `${1:-}` 等形式。`pipefail` 让管道返回最右侧非零命令的状态，但不会自动解释失败原因。对需要清理临时文件的脚本，还应设置只清理自己创建路径的 `trap`，并测试每个失败分支。

==== 实用脚本示例

让我们看几个 RoboMaster 开发中实用的脚本。

*编译脚本*

```bash
#!/bin/bash
# build.sh - 在已确认的 ROS 2 Humble 工作空间中构建

set -uo pipefail

if (( $# > 2 )); then
    echo "Usage: ${0##*/} [Debug|Release|RelWithDebInfo] [workers]" >&2
    exit 2
fi

workspace_path=${RMCV_WORKSPACE:-"$HOME/ros2_ws"}
build_type=${1:-Release}
worker_count=${2:-4}
ros_setup=/opt/ros/humble/setup.bash

case "$build_type" in
    Debug|Release|RelWithDebInfo) ;;
    *) echo "Unsupported build type: $build_type" >&2; exit 2 ;;
esac

if [[ ! "$worker_count" =~ ^[1-9][0-9]*$ ]] || (( worker_count > 32 )); then
    echo "workers must be an integer from 1 to 32" >&2
    exit 2
fi

workspace_path=$(realpath -e -- "$workspace_path") || {
    echo "Workspace does not exist" >&2
    exit 1
}

[[ -d "$workspace_path/src" ]] || {
    echo "Workspace has no src directory: $workspace_path" >&2
    exit 1
}
[[ -r "$ros_setup" ]] || {
    echo "Readable ROS setup file not found: $ros_setup" >&2
    exit 1
}

source "$ros_setup" || exit 1
cd -- "$workspace_path" || exit 1

printf 'Workspace: %s\nBuild type: %s\nWorkers: %s\n' \
    "$workspace_path" "$build_type" "$worker_count"

if colcon build \
    --parallel-workers "$worker_count" \
    --symlink-install \
    --cmake-args "-DCMAKE_BUILD_TYPE=$build_type"; then
    printf 'Build command completed. To load this overlay, inspect and source:\n  %s\n' \
        "$workspace_path/install/setup.bash"
else
    build_status=$?
    echo "colcon build failed with status $build_status" >&2
    exit "$build_status"
fi
```

脚本有意不提供 `--clean`：递归删除 `build`、`install`、`log` 会丢失诊断材料，也可能命中仍被进程使用的 overlay。需要全新验证时，可以新建独立工作空间或为 colcon 指定另一组 build/install/log 基目录；确认旧目录可重建且无人使用后，再由操作者单独处理。并行度也不直接取 `nproc`，因为内存和比赛负载往往比逻辑 CPU 数更早成为限制。

*环境检查脚本*

```bash
#!/bin/bash
# preflight_dev.sh - 只读检查本书的开发环境前提

set -uo pipefail

if (( EUID == 0 )); then
    echo "Run this audit as the normal development user" >&2
    exit 2
fi

problem_count=0
required_commands=(cmake git g++ colcon)
ros_setup=/opt/ros/humble/setup.bash
required_packages=(
    build-essential
    cmake
    git
    libopencv-dev
    libeigen3-dev
    libfmt-dev
    libspdlog-dev
    libyaml-cpp-dev
)
missing_packages=()

if [[ -r /etc/os-release ]]; then
    # Ubuntu owns this file; it uses shell-compatible KEY=VALUE syntax.
    source /etc/os-release || {
        echo "Could not read /etc/os-release" >&2
        ((problem_count += 1))
    }
else
    echo "Missing readable /etc/os-release" >&2
    ((problem_count += 1))
fi

if [[ "${ID:-}" != ubuntu || "${VERSION_CODENAME:-}" != jammy ]]; then
    printf 'Expected Ubuntu jammy; observed ID=%s codename=%s\n' \
        "${ID:-unknown}" "${VERSION_CODENAME:-unknown}" >&2
    ((problem_count += 1))
fi

for command_name in "${required_commands[@]}"; do
    if ! command -v -- "$command_name" >/dev/null 2>&1; then
        printf 'Missing command: %s\n' "$command_name" >&2
        ((problem_count += 1))
    fi
done

for package_name in "${required_packages[@]}"; do
    package_status=$(dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null || true)
    if [[ "$package_status" != "install ok installed" ]]; then
        missing_packages+=("$package_name")
        ((problem_count += 1))
    fi
done

if [[ ! -r "$ros_setup" ]]; then
    echo "Missing readable ROS 2 Humble setup file" >&2
    ((problem_count += 1))
elif source "$ros_setup"; then
    if ! command -v ros2 >/dev/null 2>&1; then
        echo "ros2 command not found after loading ROS 2 Humble" >&2
        ((problem_count += 1))
    fi
else
    echo "Failed to load ROS 2 Humble setup file" >&2
    ((problem_count += 1))
fi

workspace_path=${RMCV_WORKSPACE:-"$HOME/ros2_ws"}
if [[ ! -d "$workspace_path/src" ]]; then
    printf 'Workspace src directory not found: %s\n' "$workspace_path/src" >&2
    ((problem_count += 1))
fi

if ! id -nG | tr ' ' '\n' | grep -Fxq dialout; then
    echo "Current session is not in dialout; verify the actual device group before requesting access"
fi

if (( ${#missing_packages[@]} > 0 )); then
    printf 'Missing dpkg packages:'
    printf ' %s' "${missing_packages[@]}"
    printf '\nAPT simulation follows; review sources and plan before any real install.\n'
    apt --simulate install -- "${missing_packages[@]}" || true
fi

if (( problem_count > 0 )); then
    printf 'Preflight found %d unmet checks. No system state was changed.\n' \
        "$problem_count" >&2
    exit 1
fi

echo "Preflight checks passed for the inspected items"
```

原来常见的“一键初始化”写法会无条件升级系统、自动接受安装方案、改写 `.bashrc` 和 Git 全局配置，并把当前用户加入多个高权限设备组；任何一个错误前提都会被批量放大。这里改成只读检查和 APT 模拟。它仍只覆盖列出的条件，不检查 GPU 驱动、相机、网络、包版本一致性或项目测试，因此最后一句不能理解为整套开发环境已经验证完毕。

*备份脚本*

```bash
#!/bin/bash
# backup.sh - 创建不含可重建 colcon 产物的项目快照

set -uo pipefail
umask 077

if (( $# > 2 )); then
    echo "Usage: ${0##*/} [source_dir] [backup_dir]" >&2
    exit 2
fi

source_dir=${1:-"$HOME/ros2_ws"}
backup_dir=${2:-"$HOME/backups"}

source_dir=$(realpath -e -- "$source_dir") || {
    echo "Source does not exist" >&2
    exit 1
}
[[ -d "$source_dir" ]] || { echo "Source is not a directory" >&2; exit 1; }

mkdir -p -- "$backup_dir" || exit 1
backup_dir=$(realpath -e -- "$backup_dir") || exit 1

# 输出目录不能位于输入目录中，否则归档可能包含正在生成的归档。
case "$backup_dir/" in
    "$source_dir/"*) echo "Backup directory must be outside the source" >&2; exit 2 ;;
esac

project_name=${source_dir##*/}
[[ "$project_name" =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo "Source basename contains unsupported characters: $project_name" >&2
    exit 2
}

timestamp=$(date +%Y%m%d_%H%M%S) || exit 1
partial_archive=$(mktemp --tmpdir="$backup_dir" \
    ".${project_name}_${timestamp}.partial.XXXXXX") || exit 1
random_suffix=${partial_archive##*.}
backup_file="$backup_dir/${project_name}_${timestamp}_${random_suffix}.tar.gz"

cleanup_partial() {
    [[ -n "${partial_archive:-}" ]] && rm -f -- "$partial_archive"
}
trap cleanup_partial EXIT
# 信号处理先以约定状态退出，再由 EXIT trap 清理本脚本的 partial 文件。
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

printf 'Source: %s\nDestination: %s\n' "$source_dir" "$backup_file"

# 只排除工作空间根下可重建的 colcon 产物，保留源码、Git 和项目数据。
tar -czf "$partial_archive" \
    --exclude='./build' \
    --exclude='./install' \
    --exclude='./log' \
    -C "$source_dir" . || exit 1

# 检查 gzip/tar 结构后再把 partial 名称原子改为最终名称。
tar -tzf "$partial_archive" >/dev/null || exit 1
mv -nT -- "$partial_archive" "$backup_file" || exit 1
[[ ! -e "$partial_archive" && -f "$backup_file" ]] || {
    echo "Could not publish archive without overwriting an existing file" >&2
    exit 1
}
partial_archive=""
trap - EXIT HUP INT TERM

du -h -- "$backup_file"
sha256sum -- "$backup_file"
echo "Archive structure verified; a restore test is still required"
```

脚本只验证归档可被读取，没有验证每个文件满足业务需求，也没有覆盖系统包、设备配置或归档写入期间的并发修改。它不自动删除旧备份：用 `ls | tail | xargs rm` 轮转会在空格、换行、匹配范围和目录错误时删除意外文件。保留策略应交给有快照、锁和恢复测试的备份工具；至少把副本放到另一块介质或远端，并定期解压到临时目录做恢复演练。

*启动脚本*

```bash
#!/bin/bash
# launch_robot.sh - 前台启动一套已安装的 ROS 2 launch，并保存日志

set -uo pipefail

ros_setup=/opt/ros/humble/setup.bash
overlay_setup="$HOME/ros2_ws/install/setup.bash"
serial_device=${RMCV_SERIAL_DEVICE:-/dev/ttyUSB0}
log_dir="$HOME/robot_logs"
timestamp=$(date +%Y%m%d_%H%M%S) || exit 1

[[ -r "$ros_setup" ]] || { echo "Missing $ros_setup" >&2; exit 1; }
[[ -r "$overlay_setup" ]] || { echo "Missing $overlay_setup" >&2; exit 1; }

source "$ros_setup" || exit 1
source "$overlay_setup" || exit 1
command -v ros2 >/dev/null 2>&1 || { echo "ros2 not found after setup" >&2; exit 1; }

# 检查本次指定的设备，而不是自动扩大用户组权限。
if [[ ! -c "$serial_device" || ! -r "$serial_device" || ! -w "$serial_device" ]]; then
    printf 'Serial device is absent or not readable/writable: %s\n' "$serial_device" >&2
    ls -l -- "$serial_device" 2>/dev/null || true
    id >&2
    exit 1
fi

mkdir -p -- "$log_dir" || exit 1
log_file=$(mktemp --tmpdir="$log_dir" --suffix=.log \
    "robot_${timestamp}.XXXXXX") || exit 1
printf 'Log: %s\n' "$log_file"

ros2 launch rm_bringup robot_launch.py 2>&1 | tee -- "$log_file"
pipeline_status=("${PIPESTATUS[@]}")

if (( pipeline_status[0] != 0 )); then
    printf 'ros2 launch exited with status %d\n' "${pipeline_status[0]}" >&2
    exit "${pipeline_status[0]}"
fi
if (( pipeline_status[1] != 0 )); then
    printf 'tee failed with status %d; log may be incomplete\n' "${pipeline_status[1]}" >&2
    exit "${pipeline_status[1]}"
fi
```

原脚本在任何退出路径中执行 `pkill -f "ros2"`，会终止本机其他用户或终端中命令行恰好匹配的 ROS 进程。新版本让 launch 保持前台，并由终端信号和 ros2 launch 自己管理其子进程；如果要转为 systemd 服务，应由单元的 cgroup 管理整组进程。`tee` 组成管道后必须保存 `PIPESTATUS`，否则只能看到最后一个命令的状态。即便两个状态都是 0，也只说明 launch 与日志管道正常结束，不证明机器人任务达标。

Shell 脚本适合编排已有命令和实现小型、边界明确的自动化。是否值得写脚本取决于输入是否可验证、失败能否恢复、任务是否需要结构化数据与并发，而不是简单按重复次数决定。完成后可用 `bash -n` 检查语法、ShellCheck 查常见展开问题，并在临时目录或测试机器覆盖空输入、失败命令、信号和重复执行。下一节配置交互式开发环境时，也要保持“可回退、按需加载、不过度隐藏真实命令”的原则。


=== 开发环境配置
// 配置可复现的开发环境
// - Shell 配置：.bashrc, .zshrc, alias
// - Oh My Zsh 美化
// - tmux 终端复用
// - VS Code 远程开发
// - CMake 项目构建流程
// - 常见问题排查
// === 开发环境配置

开发环境配置的目的不是堆叠工具，而是让常用操作容易找到、重复步骤不易出错，并让失败原因仍然可见。本节从 Shell 启动文件讲起，再介绍 Zsh、tmux、VS Code Remote-SSH 和 CMake/colcon 的日常用法。示例以 Ubuntu 22.04、Bash 和 ROS 2 Humble 为背景；可以按自己的项目取舍，不必一次照搬全部配置。

==== Shell 配置

Shell 的启动方式决定它读取哪些配置文件。Ubuntu 桌面终端通常启动交互式非登录 Bash，主要读取 `~/.bashrc`；SSH 登录、TTY 登录和脚本的规则并不完全相同。先分清加载顺序，能避免“在一个终端有效、换个入口就失效”的困惑。

*理解配置文件*

Bash 常见的用户级文件如下：

- `~/.bashrc`：交互式非登录 Bash 读取它，适合提示符、补全、别名和交互函数。
- `~/.bash_profile`、`~/.bash_login`、`~/.profile`：登录 Bash 按这个顺序只读取第一个存在且可读的文件，适合会话级环境设置。
- `~/.bash_logout`：登录 Bash 正常退出时读取；它不会在所有终端关闭或异常退出路径中运行。

Ubuntu 新建用户的 `~/.profile` 通常已经在检测到 Bash 时加载 `~/.bashrc`。先打开现有文件确认，避免重复添加。若你确实选择 `~/.profile` 作为登录配置，可以使用下面的写法：

```bash
# ~/.profile 中的一部分；只加载自己拥有且可读的配置
if [ -n "${BASH_VERSION:-}" ]; then
    if [ -r "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
```

如果已经存在 `~/.bash_profile`，Bash 不会再读取 `~/.profile`；非交互 SSH 命令也不应依赖交互式 `.bashrc` 提供环境。需要脚本使用的变量，应由脚本显式加载受信任的环境文件或通过服务配置传入。

*定制 .bashrc*

下面是一份适合作为起点的 `.bashrc` 片段。它保留了历史、提示符和常用函数，但不会自动切入某个工作空间，也不把会修改仓库的 Git 命令藏在单字母别名后面：

```bash
# ~/.bashrc

# 如果不是交互式 Shell，不加载配置
case $- in
    *i*) ;;
      *) return;;
esac

# ========== 历史记录配置 ==========
HISTSIZE=10000                    # 内存中保存的历史条数
HISTFILESIZE=20000               # 文件中保存的历史条数
HISTCONTROL=ignoreboth           # 忽略重复和空白开头的命令
shopt -s histappend              # 追加而不是覆盖历史文件

# ========== Shell 选项 ==========
shopt -s checkwinsize            # 命令结束后更新终端行列数
# shopt -s globstar              # 按需启用：** 可递归匹配目录
# shopt -s cdspell               # 按需启用：交互式 cd 可尝试纠正小拼写错误

# ========== 提示符配置 ==========
# 带颜色的提示符：用户@主机:目录$；\[...\] 标记不占显示宽度的转义序列
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# ========== 别名 ==========
# 文件操作
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'

# 快捷操作
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# 只读或容易辨认的 Git 别名
alias gst='git status --short --branch'
alias glog='git log --oneline --decorate -10'
alias gdiff='git diff --'

# 系统监控
alias ports='ss -tuln'
alias meminfo='free -h'
alias diskinfo='df -h'

# ========== 环境变量 ==========
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-$EDITOR}"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# ROS 2 环境
if [ -r /opt/ros/humble/setup.bash ]; then
    source /opt/ros/humble/setup.bash ||
        printf 'Could not load ROS 2 Humble setup\n' >&2
fi

# ========== 自定义函数 ==========
# 创建并进入目录
mkcd() {
    if (( $# != 1 )); then
        echo "Usage: mkcd <directory>" >&2
        return 2
    fi
    mkdir -p -- "$1" && cd -- "$1"
}

# 按文件名片段查找；模式前后的 * 由 find 解释，不由当前 Shell 展开
ff() {
    if (( $# != 1 )); then
        echo "Usage: ff <name-fragment>" >&2
        return 2
    fi
    find . -name "*$1*" -print
}

# 递归查找文本；名称避免覆盖 Bash 作业控制内置命令 fg
search_text() {
    if (( $# != 1 )); then
        echo "Usage: search_text <text>" >&2
        return 2
    fi
    grep -RIn -- "$1" .
}

# 显式进入并加载指定 ROS 2 工作空间，避免每个终端静默加载旧 overlay
use_ros_ws() {
    if (( $# != 1 )); then
        echo "Usage: use_ros_ws <workspace-directory>" >&2
        return 2
    fi
    local workspace
    workspace=$(realpath -e -- "$1") || {
        echo "Workspace path not found: $1" >&2
        return 1
    }
    local setup_file="$workspace/install/setup.bash"
    [[ -d "$workspace/src" && -r "$setup_file" ]] || {
        echo "Workspace or readable overlay not found: $workspace" >&2
        return 1
    }
    cd -- "$workspace" || return 1
    source "$setup_file" || return 1
    printf 'Loaded workspace: %s\n' "$workspace"
}
```

`ROS_DOMAIN_ID` 应由队伍按网络规划设置；它用于 DDS 发现域隔离，不是访问控制或加密机制，因此示例不在所有终端中固定导出它。若需要显示 Git 分支，可使用发行版提供的 Git prompt 或其他提示符工具；这类命令会在每次刷新提示符时运行，在大型仓库或网络文件系统上可能增加延迟。

修改后先执行 `bash -n "$HOME/.bashrc"` 检查语法，再用 `bash --noprofile --rcfile "$HOME/.bashrc" -i` 打开一个测试子 Shell。确认提示符、补全和函数都正常后再关闭旧终端。直接在当前会话中 `source ~/.bashrc` 会立即执行到出错位置，已有环境可能只更新了一部分，因此不适合作为唯一测试。

*别名与函数各自适合什么*

别名适合不带复杂参数的固定展开；需要校验输入、改变目录或组合多个命令时，函数更清楚。无论使用哪一种，都应让会写文件、启动机器人或修改仓库状态的动作从名字上可辨认。例如：

```bash
# 进入固定源码目录
alias cdrmv='cd "$HOME/ros2_ws/src/rm_vision"'
alias cdrmc='cd "$HOME/ros2_ws/src/rm_control"'

# 构建视觉相关包；从已加载的工作空间根目录调用
build_vision() {
    [[ -d src ]] || {
        echo "Run this from a ROS 2 workspace root" >&2
        return 1
    }
    colcon build --symlink-install \
        --packages-select rm_vision rm_detector rm_tracker
}

# 启动常用的 launch 文件
alias launch_robot='ros2 launch rm_bringup robot.launch.py'
alias launch_sim='ros2 launch rm_gazebo simulation.launch.py'

# 连接机器人
alias ssh_robot='ssh alice@192.168.1.50'

# 查看特定话题
alias echo_armor='ros2 topic echo /detector/armors'
```

`alias rm='rm -i'` 之类的设置可以在交互终端增加一次确认，但别名通常不会在脚本和非交互 Shell 中展开，命令也能用 `command rm` 绕过。它不能替代检查目标路径和备份；若启用，应把它视为交互提示，而不是删除操作已经“安全”的保证。至此，Bash 配置的边界已经清楚。若你更喜欢另一套交互体验，可以再考虑 Zsh，而不必重写项目脚本。

==== Zsh 与 Oh My Zsh

Zsh（Z Shell）可以作为交互式 Shell，提供可扩展补全、提示符主题和不同于 Bash 的选项体系。它不是对 Bash 的原位升级：两者语法和启动文件有差异，把登录 Shell 换成 Zsh 也不会改变以 `#!/bin/bash` 或 `#!/bin/sh` 启动的脚本。先确认自己确实需要它的交互功能，再决定是否迁移。

*安装 Zsh*

```bash
# 安装 Zsh
sudo apt install zsh

# 查看实际路径、版本，并确认它列在系统允许的登录 Shell 中
command -v zsh
zsh --version
grep -Fx -- "$(command -v zsh)" /etc/shells

# 设为默认 Shell
chsh -s "$(command -v zsh)"
```

`chsh` 修改的是之后登录时使用的 Shell，现有终端不会立即切换。保留当前 Bash 会话，重新登录一个终端验证 Zsh 能正常启动；若配置有误，仍可在旧会话中修正 `~/.zshrc`，或把登录 Shell 改回 `/bin/bash`。服务器是否允许用户执行 `chsh` 取决于账户和目录服务策略。

*安装 Oh My Zsh*

Oh My Zsh 是可选的 Zsh 配置框架，提供主题、插件加载和一份起始配置。它及其插件都会以当前用户权限在每个交互 Shell 中执行，因此也属于需要审查和更新的软件。常见的 `curl ... | sh` 安装命令会把刚下载的内容直接交给 Shell，本书不把它作为可直接复制的步骤。可以先用 Git 获取源码，再比较模板和现有配置：

```bash
# 在项目主页核对仓库地址后，克隆到尚不存在的目录
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git \
    "$HOME/.oh-my-zsh"

# 先生成一个候选配置，不覆盖已有 ~/.zshrc
install -m 600 \
    "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" \
    "$HOME/.zshrc.omz-example"

# 已有配置时逐项比较；没有时只提示候选文件位置
if [[ -e "$HOME/.zshrc" ]]; then
    diff -u -- "$HOME/.zshrc" "$HOME/.zshrc.omz-example"
else
    printf 'No existing ~/.zshrc; review candidate: %s\n' \
        "$HOME/.zshrc.omz-example"
fi
```

如果目标目录或候选文件已经存在，先确认它的来源，不要为了重装直接覆盖。浅克隆便于试用，但不固定版本；团队要复现同一环境时，应记录经过审查的提交或发布版本，并在升级后重新测试补全、插件和 ROS 环境加载。

*配置主题*

Oh My Zsh 自带多种主题。在 `~/.zshrc` 中一次选择一个固定主题，终端截图和排障输出会更一致：

```bash
# 内置的简洁主题
ZSH_THEME="robbyrussell"
```

Powerlevel10k 等第三方主题可以显示 Git 状态、退出状态和耗时，但会增加配置项与外部依赖。需要时把它作为普通第三方代码安装并审阅，而不是默认前提：

```bash
# 目标目录必须尚不存在；团队环境还应固定审阅过的版本
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# 在 ~/.zshrc 中设置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 在测试 Zsh 中重新加载配置，首次启动时按提示选择显示内容
```

带图标的主题还要求终端客户端使用包含相应字形的字体。先从字体项目的正式发布页取得并核对文件，再安装到当前用户目录；远程 SSH 终端的字形通常仍由本地运行 VS Code 或终端模拟器的一侧渲染。

```bash
# 假设已把经过核对的字体下载到 ~/Downloads
install -d -m 755 "$HOME/.local/share/fonts"
install -m 644 "$HOME/Downloads/MesloLGS NF Regular.ttf" \
    "$HOME/.local/share/fonts/"
fc-cache -f
fc-match "MesloLGS NF"

# 最后在终端或 VS Code 的本地设置中选择该字体
```

*配置插件*

插件可以增加补全、目录跳转或显示功能，也可能改写快捷键和别名。先从少量插件开始，遇到启动变慢或行为变化时逐个停用比较：

```bash
plugins=(
    git                 # Git 补全和一组可查阅的别名
    colored-man-pages   # 彩色 man 页面
    z                   # 根据访问记录跳转目录
)
```

第三方插件同样会执行源码。下面展示安装位置，不代表已经验证其最新版本；使用前查看仓库、许可证和更新记录，团队配置应固定提交：

```bash
# zsh-autosuggestions：基于历史的命令建议
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

# zsh-syntax-highlighting：命令语法高亮
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

# 添加到插件列表
plugins=(
    git
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
)
```

高亮插件通常放在列表靠后位置，以免后续插件覆盖它的钩子。像 `sudo` 这类能重写当前命令行的插件并非必需；若启用，要先理解其快捷键，避免把原本只读的命令意外变为提权操作。

*迁移 Bash 配置*

不要直接从 `.zshrc` 加载整份 `.bashrc`：`shopt`、数组下标、补全和部分选项并不通用。环境变量和简单别名可以逐项迁移，ROS 2 则加载对应的 `.zsh` 文件：

```bash
# 加载 ROS 2 underlay
if [[ -r /opt/ros/humble/setup.zsh ]]; then
    source /opt/ros/humble/setup.zsh ||
        print -u2 "Could not load ROS 2 Humble setup"
fi

# 别名（大部分与 Bash 相同）
alias ll='ls -alF'
alias cb='colcon build --symlink-install'
# ...其他别名

# 工作空间 overlay 仍显式选择
use_ros_ws() {
    if (( $# != 1 )); then
        print -u2 "Usage: use_ros_ws <workspace-directory>"
        return 2
    fi
    local workspace
    workspace=$(realpath -e -- "$1") || {
        print -u2 "Workspace path not found: $1"
        return 1
    }
    local setup_file="$workspace/install/setup.zsh"
    [[ -d "$workspace/src" && -r "$setup_file" ]] || {
        print -u2 "Workspace or readable overlay not found: $workspace"
        return 1
    }
    builtin cd -- "$workspace" && source "$setup_file"
}
```

运行 `zsh -n "$HOME/.zshrc"` 可做语法检查；再启动 `zsh -f` 得到不加载用户配置的测试 Shell，并在其中手动 `source ~/.zshrc`。这能把试错限制在子 Shell 中。确认交互 Shell 稳定后，下一步可以用 tmux 组织多个长期终端，而不是继续把更多启动动作塞进配置文件。

==== tmux 终端复用

tmux（Terminal Multiplexer）由一个后台服务器维护伪终端，多个客户端可以连接到同一组会话。SSH 客户端断线时，tmux 服务器和其中的命令通常仍在远端运行，重新连接后可以继续查看输出。不过它不能跨越远端重启、tmux 服务器退出或进程被系统终止；需要开机自启和故障重启的机器人服务仍应交给 systemd 等服务管理器。

*安装和基本概念*

```bash
sudo apt install tmux
tmux -V
```

tmux 有三个层次的概念：

- *会话（Session）*：一组窗口，由 tmux 服务器保存，可以有零个或多个客户端连接。
- *窗口（Window）*：类似标签页，一个会话可以包含多个窗口。
- *窗格（Pane）*：窗口内的分割区域，每个窗格运行一个伪终端和前台程序。

*基本操作*

```bash
# 创建名为 robot 的会话；若已存在则直接连接
tmux new-session -A -s robot

# 列出会话
tmux list-sessions

# 连接到会话
tmux attach-session -t robot

# 断开会话（会话继续运行）
# 在 tmux 中按 Ctrl+B 然后 D

# 先确认会话名称；关闭会话会终止其中仍依附于伪终端的程序
tmux list-sessions
tmux kill-session -t robot
```

tmux 的大多数默认快捷键以前缀键开始。默认前缀是 `Ctrl+B`：先松开这两个键，再按功能键；它不是三个键同时按。

*常用快捷键*

会话管理（前缀 + 键）：
- `d`：断开当前会话
- `s`：列出会话并切换
- `$`：重命名当前会话

窗口管理：
- `c`：创建新窗口
- `n`：下一个窗口
- `p`：上一个窗口
- `数字`：切换到指定窗口
- `,`：重命名当前窗口
- `&`：关闭当前窗口

窗格管理：
- `%`：垂直分割（左右）
- `"`：水平分割（上下）
- `方向键`：在窗格间移动
- `x`：确认后关闭当前窗格及其中的前台程序
- `z`：最大化或恢复当前窗格
- `空格`：切换预设窗格布局

其他：
- `?`：显示帮助
- `[`：进入复制模式（可滚动查看历史）
- `]`：粘贴

*tmux 配置*

创建 `~/.tmux.conf` 可以调整按键、终端能力和状态栏。下面是一份可读的起点；前缀键和无前缀的 Alt 快捷键都可能与编辑器或桌面环境冲突，应按自己的终端逐项启用：

```conf
# ~/.tmux.conf

# 可选：更改前缀键为 Ctrl+A
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# 启用鼠标支持
set -g mouse on

# 从 1 开始给窗口和窗格编号
set -g base-index 1
setw -g pane-base-index 1

# 更直观的分割快捷键
bind '|' split-window -h -c "#{pane_current_path}"
bind '-' split-window -v -c "#{pane_current_path}"

# 使用 Alt+方向键切换窗格（无需前缀）
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# 快速重载配置
bind r source-file ~/.tmux.conf \; display-message "Config reloaded"

# tmux 内部声明的终端类型；使用前以 infocmp tmux-256color 确认 terminfo 存在
set -g default-terminal "tmux-256color"

# 增加历史记录
set -g history-limit 10000

# 给独立 Esc 与终端转义序列保留一个较短的区分窗口
set -sg escape-time 10

# 状态栏美化
set -g status-style bg=black,fg=white
set -g status-left '[#S] '
set -g status-right '%H:%M %d-%b-%y'
```

`default-terminal` 描述 tmux 提供给内部程序的能力，不等于外层终端的 `$TERM`。若 `infocmp tmux-256color` 找不到条目，可暂用兼容性更广但能力较少的 `screen-256color`；真彩色还取决于 tmux 版本、外层终端和远端 terminfo，不能只靠一行配置保证。修改配置后，可以用独立服务器试载，避免影响正在工作的会话：

```bash
check_socket="rmcv-config-check-$$"
if tmux -L "$check_socket" -f "$HOME/.tmux.conf" \
    new-session -d -s config-check; then
    tmux -L "$check_socket" list-sessions
    tmux -L "$check_socket" kill-server
else
    echo "tmux configuration did not load; inspect the diagnostics" >&2
fi
```

*RoboMaster 开发的 tmux 工作流*

下面的脚本只创建布局，不替你启动编译或机器人节点。这样进入会话后仍能看清每个窗格执行了什么：

```bash
#!/bin/bash
set -u

workspace="$HOME/ros2_ws"
[[ -d "$workspace/src" ]] || { echo "Workspace not found" >&2; exit 1; }

# 不把新布局意外叠加到同名旧会话上
if tmux has-session -t robot 2>/dev/null; then
    echo "Session robot already exists; attach to it or choose another name" >&2
    exit 1
fi

tmux new-session -d -s robot -n editor -c "$workspace"
tmux new-window -t robot -n build -c "$workspace"
tmux new-window -t robot -n monitor -c "$workspace"
tmux split-window -t robot:monitor -h -c "$workspace"
tmux split-window -t robot:monitor -v -c "$workspace"
tmux select-layout -t robot:monitor tiled
tmux select-window -t robot:editor
tmux attach-session -t robot
```

进入后，可以在 `editor` 窗口打开编辑器，在 `build` 窗口加载对应 overlay 并构建，在 `monitor` 的三个窗格分别运行 `htop`、`ros2 topic echo` 和日志查看命令。按前缀后再按 `d` 只是分离客户端，不等于任务已成功或日志已落盘；重新连接时先查看每个程序的退出状态和时间戳。tmux 解决的是终端组织和短时断线问题，代码编辑、索引和图形化调试则可以交给下一节的远程编辑器。

==== VS Code 远程开发

VS Code Remote-SSH 把编辑器界面留在本机，通过 SSH 操作远端文件，并在远端运行 VS Code Server 和一部分扩展。它适合代码实际存放在机器人或开发服务器上的场景，但不会消除 SSH 的主机身份验证、密钥保护和远端资源限制。

先在运行 VS Code 的本机配置 `~/.ssh/config`。`IdentityFile` 指定客户端尝试的私钥，`IdentitiesOnly yes` 避免 SSH agent 中的其他密钥抢先耗尽服务端尝试次数：

```bash
# ~/.ssh/config
Host robot
    HostName 192.168.1.50
    User alice
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ForwardAgent no
```

这并不承诺“从此无需密码”：加密私钥仍可能要求 passphrase，服务端也可能要求多因素认证。首次连接前应通过可信渠道核对主机指纹；配置完成后先在本地终端执行 `ssh robot true`，确认普通 SSH 命令能连接并正常返回，再让 VS Code 使用同一主机别名。不要为图省事关闭主机密钥检查或把私钥复制到远端。

*远程开发工作流*

连接后，各部分的位置并不相同：

- 窗口和界面仍由本机 VS Code 渲染，文件浏览器显示远端工作区。
- 集成终端、Git 命令、编译器和调试目标在远端运行。
- 语言服务器等工作区扩展通常安装在远端扩展主机；主题和界面扩展通常留在本机，具体位置由扩展声明决定。
- VS Code Server 会占用远端磁盘、内存和进程；受限账户、只读主目录或不兼容平台可能无法安装或运行它。

常见选择包括 C/C++、CMake Tools、Python，以及与所用 ROS 2 工作流兼容的扩展。安装前核对扩展标识、发布者、权限和维护状态，只装当前项目需要的部分。打开不熟悉的仓库时先查看工作区信任提示，因为 `.vscode/tasks.json`、调试配置和扩展本身都可能在远端执行命令。

*为普通 CMake 项目配置 VS Code*

如果打开的是单个、可由 CMake Tools 直接配置的 CMake 项目，可以让 CMake Tools 向 C/C++ 扩展提供编译参数，并使用独立构建目录：

```json
{
    "C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools",
    "cmake.configureOnOpen": false,
    "cmake.buildDirectory": "${workspaceFolder}/build-vscode",
    "files.associations": {
        "*.launch.py": "python",
        "*.xacro": "xml"
    }
}
```

保持 `configureOnOpen` 为 `false`，可以先在状态栏核对 Kit、生成器、源码目录和构建目录，再主动配置。编译器标准、宏、头文件和系统路径应来自真实 CMake target，而不是在 `c_cpp_properties.json` 中再维护一份容易过期的宽泛 `includePath`。

*为 colcon 工作空间提供索引信息*

colcon 工作空间包含多个包，工作空间根目录通常不是一个应由 CMake Tools 单独配置的 CMake target。可以把下面的短脚本保存在工作空间外，或在远端终端逐条确认成功，让各 CMake 包导出它们实际使用的编译命令：

```bash
#!/bin/bash
set -euo pipefail

source /opt/ros/humble/setup.bash || exit 1
cd -- "$HOME/ros2_ws" || exit 1
colcon build --symlink-install \
    --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

成功配置过的 CMake 包通常会在 `build/<package>/compile_commands.json` 生成编译数据库。以 `rm_vision` 为当前主要包时，可以在工作空间的 `.vscode/settings.json` 中显式指向它：

```json
{
    "cmake.configureOnOpen": false,
    "C_Cpp.default.compileCommands": "${workspaceFolder}/build/rm_vision/compile_commands.json",
    "files.associations": {
        "*.launch.py": "python",
        "*.xacro": "xml"
    }
}
```

路径必须与实际包名和构建基目录一致；切换主要包时相应调整。多包工作空间若需要统一索引，应使用能保留每条命令且处理重复源文件的编译数据库合并工具，不能简单假设根目录会自动出现一份完整文件。

Python 分析路径也应从加载环境后的真实解释器取得；同样让任一步失败时停止：

```bash
#!/bin/bash
set -euo pipefail

source /opt/ros/humble/setup.bash || exit 1
source "$HOME/ros2_ws/install/setup.bash" || exit 1
python3 -c 'import sys; print("\n".join(sys.path))'
python3 -c 'import rclpy; print(rclpy.__file__)'
```

若 Python 扩展仍找不到包，再把输出中确实存在的项目路径加入 `python.analysis.extraPaths`。不要预先给所有集成终端写死全局 `PYTHONPATH`：它可能把旧 overlay 放到系统包之前，使终端运行结果与 colcon/launch 的环境顺序不一致。索引配置只改善编辑器理解代码的能力，是否能构建仍要由下一节的 CMake/colcon 命令和项目测试确认。

==== CMake 项目构建流程

CMake 读取项目的 `CMakeLists.txt`，完成依赖查找和 target 配置，再生成 Ninja、Makefiles 等底层构建系统；`cmake --build` 随后调用对应工具完成编译。RoboMaster 项目和许多 ROS 2 C++ 包都使用它。本节先给出日常操作主线，后面的 CMake 专章再解释 target、依赖传播、安装与导出。

*标准 CMake 流程*

```bash
#!/bin/bash
set -euo pipefail

# 1. 为当前源码选择独立的构建目录和用户可写安装前缀
source_dir=$PWD
build_dir="$PWD/build-relwithdebinfo"
install_dir="$PWD/stage"

# 2. 配置；不写 -G 时使用本机默认生成器
cmake -S "$source_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="$install_dir"

# 3. 构建；并行度要结合内存和当前负载选择
cmake --build "$build_dir" --parallel 4

# 4. 若项目定义了 CTest 测试，则运行它们
ctest --test-dir "$build_dir" --output-on-failure

# 5. 需要检查安装布局时，先安装到用户可写的 staging 目录
cmake --install "$build_dir"
```

把源码和构建目录分开，便于并存 Debug、Release 等配置，也避免生成文件混进源码。`stage` 只是一份待检查的安装树，不会自动让系统或 ROS 找到它；确认内容、运行时搜索路径和卸载方案后，再决定项目应安装到工作空间、用户前缀、软件包还是系统前缀。不要把 `sudo make install` 当作默认步骤，因为它可能写入包管理器未跟踪的系统文件。

`CMAKE_BUILD_TYPE` 适用于 Unix Makefiles、Ninja 这类单配置生成器。Visual Studio、Xcode 和 Ninja Multi-Config 等多配置生成器通常在构建和安装时使用 `--config RelWithDebInfo`，不能假设配置阶段的同名变量起效。`ctest` 退出 0 只说明当前构建树中被发现并执行的测试通过；若项目没有注册测试，它可能报告 “No tests were found”。

*常用 CMake 选项*

```bash
# 单配置构建类型；项目支持哪些类型和附加标志仍需查看其文档
cmake -S . -B build-debug -DCMAKE_BUILD_TYPE=Debug

# 安装前缀
cmake -S . -B build-stage -DCMAKE_INSTALL_PREFIX="$PWD/stage"

# 编译器应在首次配置时选择；路径以本机 command -v 的结果为准
cmake -S . -B build-clang \
    -DCMAKE_C_COMPILER=/usr/bin/clang \
    -DCMAKE_CXX_COMPILER=/usr/bin/clang++

# 指定已安装的生成器
cmake -S . -B build-ninja -G Ninja

# 仅列出当前缓存变量；加 -A 可显示 advanced 项
cmake -L -N build-relwithdebinfo
cmake -L -A -N build-relwithdebinfo
```

生成器和编译器会参与构建树的基本结构，不能在同一缓存中随意互换；要比较另一套工具链，应新建构建目录。Ninja 常有较简洁的输出和良好的并行调度，但具体速度取决于项目、依赖、磁盘和缓存，不能写成普遍快于 Make。`WITH_CUDA`、`BUILD_TESTS` 等名称只有项目实际定义时才有意义；先查项目文档和缓存说明，不要根据相似项目猜选项。

*ccmake 交互式配置*

```bash
sudo apt install cmake-curses-gui
ccmake build-relwithdebinfo
```

`ccmake` 以文本界面显示该构建目录的缓存变量。按 `t` 可切换 advanced 项，修改后先按 `c` 重新配置，处理错误，再按 `g` 生成。它适合查看选项和说明，但修改缓存仍会影响后续构建；不认识的工具链、依赖路径或内部变量不要批量改动。

*ROS 2 colcon 构建*

colcon 负责发现工作空间中的包、按依赖顺序调用各包的构建类型，并组织 `build`、`install` 和 `log`。`ament_cmake` 包会由 colcon 调用 CMake，Python 等包则可能使用其他后端，因此 colcon 不是 CMake 的简单别名。

```bash
# 先加载 ROS 2 underlay，再进入工作空间；任一步失败都不要继续构建
source /opt/ros/humble/setup.bash
cd -- "$HOME/ros2_ws"

# 构建前查看实际发现的包
colcon list

# 构建所有包；并行度同样受内存约束
colcon build --symlink-install --parallel-workers 4

# 只选择列出的包；它们的依赖必须已在 underlay/overlay 中可用
colcon build --packages-select pkg1 pkg2

# 构建 pkg1 以及本工作空间中到达它所需的依赖包
colcon build --packages-up-to pkg1

# 把 CMake 参数传给本次选中的 CMake 包
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Debug

# 在一条构建命令成功后，再单独加载本工作空间 overlay
source "$HOME/ros2_ws/install/setup.bash"
```

`--symlink-install` 会让部分脚本和资源通过符号链接出现在安装空间中，适合迭代开发，但 C++、接口生成和安装规则变化仍常常需要重新构建。加载 overlay 后，同名包可能遮蔽 underlay 中的版本；用 `ros2 pkg prefix <package>` 核对当前解析到哪里。

不要把 `rm -rf build/ install/ log/` 作为普通“清理”按钮：它会同时删掉缓存、上一份可运行 overlay 和诊断日志。需要比较一套全新配置时，优先使用另一组基目录：

```bash
colcon --log-base log-debug build \
    --build-base build-debug \
    --install-base install-debug \
    --cmake-args -DCMAKE_BUILD_TYPE=Debug
```

确认旧目录可完全重建、没有终端或服务仍在加载它，并保留需要的日志后，再由操作者处理明确的旧目录。这样“全新构建”和“删除现有证据”就不会绑在同一条命令中。

*调试构建问题*

```bash
# 缩小到一个包，并让事件直接显示在终端
colcon build --packages-select pkg1 \
    --event-handlers console_direct+

# 只读查看缓存变量和帮助
cmake -L -A -N build/pkg1

# 要求 CMake 包重新执行配置，或移除其 CMake cache 后再由 colcon 配置
colcon build --packages-select pkg1 --cmake-force-configure
colcon build --packages-select pkg1 --cmake-clean-cache

# 查看该包底层构建工具执行的命令
cmake --build build/pkg1 --verbose

# 构建后运行已注册测试，并展开失败信息
colcon test --packages-select pkg1
colcon test-result --verbose
```

`console_direct+` 便于观察单包输出，多包并行时不同进程的行可能交错。直接进入 `build/<package>` 手工重新运行一个猜测出来的 `cmake ../../src/...`，可能漏掉 colcon 提供的安装前缀、工具链和依赖环境，反而制造另一套配置。先保存失败命令、退出状态、`CMakeCache.txt` 与 `log/latest_build` 中的对应日志，再选择强制配置、清缓存或独立构建目录。接下来的常见问题也沿用这个顺序：先确定错误发生在哪一层，再改变最小的相关输入。

==== 常见问题排查

同一条末尾报错可能由不同前置问题造成。先保留完整命令、第一处相关错误、退出状态和当前环境，再判断发生在预处理、编译、链接、动态加载、ROS 包发现、设备访问还是网络连接。下面给出的是逐步缩小范围的方法，不是看到关键词就执行的固定处方。

*找不到库或头文件*

```bash
# 错误：fatal error: opencv2/opencv.hpp: No such file or directory

# 查看真实编译命令，确认 -I、编译器和当前构建目录
cmake --build build --verbose

# 若开发包已安装，检查它实际提供的文件和 pkg-config 信息
dpkg-query -W libopencv-dev
dpkg -L libopencv-dev | grep -F 'opencv2/opencv.hpp'
pkg-config --cflags --libs opencv4

# 若尚未安装，先查看来源和模拟安装方案
apt-cache policy libopencv-dev
apt --simulate install libopencv-dev
```

确认软件源与模拟方案后，才执行实际安装。开发包存在仍不代表当前 target 会收到它的 include 目录；CMake 项目应按该包文档连接依赖。例如 Ubuntu 22.04 的 OpenCV 配置常见写法是：

```cmake
find_package(OpenCV REQUIRED)
target_include_directories(my_target PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(my_target PRIVATE ${OpenCV_LIBS})
```

某些包会提供更明确的 imported target，应优先使用其官方配置说明。头文件缺失也可能来自拼写、条件编译、选错 sysroot、旧缓存或编译的并非你刚修改的 target；详细编译命令能区分这些情况。

*链接错误*

```bash
# 错误：undefined reference to `cv::imread(...)'

# 先取得完整链接命令
cmake --build build --verbose

# 查看动态链接器缓存中有哪些 OpenCV 库
ldconfig -p | grep -F 'libopencv'

# 对已确认来源的候选库查看导出符号
nm -D -C /path/to/libopencv_imgcodecs.so | grep -F 'cv::imread'
```

`undefined reference` 发生在链接阶段。未链接实现库是常见原因，但静态库顺序、头文件与库版本不一致、C++ ABI、条件宏和函数签名不一致也会产生相似结果。把详细链接行中的对象文件、`-L`、库名和顺序与 `find_package` 的结果对应起来，再修改 `target_link_libraries`；仅看到系统里存在某个 `.so` 还不能确定当前链接使用了它。

*运行时找不到共享库*

```bash
# 错误：error while loading shared libraries: libxxx.so

# 查看程序声明的依赖和嵌入式搜索路径
readelf -d ./my_program | grep -E 'NEEDED|RPATH|RUNPATH'

# 只对自己构建且信任的程序使用 ldd
ldd ./my_program

# 为单次诊断临时增加一个已核对的目录，不写入 Shell 配置
LD_LIBRARY_PATH="/verified/prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    ./my_program
```

这里要区分“库不存在”“库存在但搜索不到”“找到了错误版本”和“库的依赖又缺失”。`LD_LIBRARY_PATH` 的单次命令可验证搜索路径假设，但不适合全局写入 `.bashrc`。项目可根据实际安装布局设置受控的 install RPATH，例如可执行文件位于 `bin`、私有库位于相邻 `lib` 时使用 `INSTALL_RPATH "$ORIGIN/../lib"`；系统级 `/etc/ld.so.conf.d` 和 `ldconfig` 应留给经过审查、可卸载的系统安装方案。对不可信二进制不要运行 `ldd`，可先用 `readelf` 做静态检查。

*ROS 2 包找不到*

```bash
# 错误：Package 'xxx' not found

# 查看当前搜索前缀，一行一个目录
tr ':' '\n' <<< "${AMENT_PREFIX_PATH:-}"

# 按 underlay 在前、overlay 在后的顺序加载；失败时停止后续诊断
source /opt/ros/humble/setup.bash
source "$HOME/ros2_ws/install/setup.bash"

# 精确检查包发现结果和当前前缀
ros2 pkg list | grep -Fx -- xxx
ros2 pkg prefix xxx

# 检查源码工作空间中是否发现该包
cd -- "$HOME/ros2_ws"
colcon list | awk '$1 == "xxx" { print }'

# 缺少本工作空间依赖时，构建到该包为止；成功后再加载 overlay
colcon build --packages-up-to xxx
source install/setup.bash
```

这些命令按顺序展示，但只有上一条 `source`、`cd` 或构建成功时才继续下一步。包找不到可能是没有加载正确环境、包未成功安装、包名与目录名不同、存在 `COLCON_IGNORE`、清单无效或旧 overlay 遮蔽了预期版本。`ros2 pkg prefix` 直接给出当前命中的安装前缀；若构建失败，继续 source 原有 `install` 可能仍得到上一次版本，所以要把构建状态与包前缀一起记录。

*串口权限问题*

```bash
# 错误：Permission denied: '/dev/ttyUSB0'

# 先确认设备节点、类型、所有者、组和当前会话组
serial_device=/dev/ttyUSB0
ls -l -- "$serial_device"
stat -c 'mode=%A owner=%U group=%G path=%n' -- "$serial_device"
id -nG | tr ' ' '\n'
udevadm info --query=property --name="$serial_device" |
    grep -E '^(ID_VENDOR_ID|ID_MODEL_ID|ID_SERIAL)='

# 检查当前进程是否实际具备读写权限
[[ -r "$serial_device" && -w "$serial_device" ]]
```

Ubuntu 上许多 USB 串口属于 `dialout`，但应以设备节点的实际组为准。确认该组只授予预期设备权限后，管理员可以用 `sudo usermod -aG dialout "$USER"` 添加成员；必须完整退出并重新登录，旧会话的组列表才会更新。不要用 `chmod 666` 把设备临时开放给所有本机用户，udev 还可能在重插后重置权限。固定硬件可依据核对过的 vendor/product/serial 编写最小权限 udev 规则；若权限位允许但仍打不开，还要检查设备是否消失、被其他进程占用，以及容器或沙箱是否传入了该设备。

*SSH 连接问题*

```bash
# 客户端：观察解析、路由、握手和认证停在哪一步
ssh -vvv -o ConnectTimeout=5 robot true
ip route get 192.168.1.50

# 只能通过远端控制台或已有管理会话执行以下服务端检查
sudo systemctl status ssh --no-pager
sudo ss -ltnp 'sport = :22'
sudo journalctl -u ssh -b --no-pager -n 50

sudo ufw status verbose
```

`Connection refused` 表明这次 TCP 尝试被主动拒绝，常见于目标地址上没有监听者或防火墙明确 reject；超时更可能涉及路由、丢包或静默过滤，但都需要结合服务端观察。不要仅凭客户端字符串就启动服务或开放防火墙：先确认目标地址确实是那台机器、sshd 本来就应启用，以及允许范围符合网络策略。

`Host key verification failed` 更不能直接解释为“旧记录该删了”。它可能提示主机重装、地址复用，也可能提示连接被劫持。先在远端控制台或由管理员通过独立渠道取得主机公钥指纹：

```bash
# 远端可信控制台
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

# 本地查看现有记录；只有独立核对新指纹后才备份并更新真实 HostName
ssh-keygen -F 192.168.1.50
cp -a -- "$HOME/.ssh/known_hosts" \
    "$HOME/.ssh/known_hosts.$(date +%Y%m%d_%H%M%S).bak"
ssh-keygen -R 192.168.1.50
```

更新前可以备份 `known_hosts`，并同时检查配置中的真实 `HostName`，因为别名和 IP 地址可能对应不同记录。删除条目只会让客户端在下次连接时重新询问，不会自行证明新密钥可信。

*内存不足导致编译失败*

```bash
# 错误：c++: fatal error: Killed signal terminated program cc1plus

# 查看内存、swap 和本次启动后的内核记录
free -h
swapon --show
journalctl -k -b --no-pager |
    grep -Ei 'out of memory|oom-kill|killed process'

# 先减少同时运行的编译任务，再复现并观察峰值
colcon build --parallel-workers 2
```

`cc1plus` 被信号终止与内存压力相符，但单行输出不足以确认 OOM；只有同一时段的内核 OOM 记录明确列出对应进程或 PID，才能把这次终止归因于内核的 OOM 处理。若减少并行度仍不能满足已验证的内存需求，且磁盘空间、介质寿命和机器策略允许，可以评估临时 swap。下面的 4 GiB 只是脚本示例，目标文件必须尚不存在：

```bash
#!/bin/bash
set -u

swap_path=/swapfile-rmcv
[[ ! -e "$swap_path" ]] || { echo "Refusing to reuse $swap_path" >&2; exit 1; }
df -h /
sudo fallocate -l 4G -- "$swap_path" || exit 1
sudo chmod 600 -- "$swap_path" || exit 1
sudo mkswap -- "$swap_path" || exit 1
sudo swapon -- "$swap_path" || exit 1
swapon --show
```

这个过程会改变系统状态并占用磁盘；添加到 `/etc/fstab` 会进一步影响开机流程，不应由通用脚本自动完成。swap 可能避免一次 OOM，也可能让构建因换页显著变慢，它不能证明程序没有泄漏或目标设备内存足够。记录前后内存峰值和构建状态，再决定保留、调整或按运维流程撤销。

*Git 子模块问题*

```bash
# 先查看超级项目记录的提交和当前子模块状态
git submodule status --recursive
git diff --submodule=log

# 上游修改过 URL 时同步配置，再检出超级项目记录的确切提交
git submodule sync --recursive
git submodule update --init --recursive

# 检查每个已初始化子模块是否还有本地修改
git submodule foreach --recursive 'git status --short'
```

子模块在超级项目中记录的是一个确切提交，不是“始终跟随最新版本”的目录。普通克隆后目录为空或未初始化时，`update --init --recursive` 会按这些记录检出；`git submodule update --remote <path>` 则会查询配置的远端分支并改变该子模块工作树，应只对明确路径有意执行，再审查超级项目中出现的 gitlink 变化。不要用 `deinit -f .` 处理一般更新问题，它会强制移除所有子模块工作树，未保存修改可能丢失。

至此，一套开发环境应当满足三个可观察条件：新终端能说明自己加载了哪些环境，构建命令和产物目录可以复现，出现错误时还能找到原始日志与最小诊断路径。提示符、主题和快捷键可以按个人习惯调整；工具链版本、依赖来源、ROS overlay 顺序和设备权限则应写进团队文档并经过实际构建与硬件检查。每次只改一组相关配置并保留回退路径，比追求“一次配置完成”更容易维护。
