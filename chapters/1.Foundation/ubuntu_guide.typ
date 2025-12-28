
#show raw.where(block: true): set block(inset: (left: 4em))
=== 图形界面初探
// Ubuntu 桌面环境快速上手
// - GNOME 桌面基本操作
// - 文件管理器（Nautilus）
// - 系统设置
// - 应用程序安装（Software Center）
// - 截图、录屏等实用工具
// - 快捷键汇总
// - 但是...为什么我们要学命令行？

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

如果说 Linux 是一个王国，那么终端就是通往这个王国的大门。虽然现代 Linux 发行版都提供了精美的图形界面，但终端——那个黑色（或其他颜色）的窗口，闪烁着等待输入的光标——仍然是 Linux 的灵魂所在。通过终端，你可以用文字与系统对话，执行命令，管理文件，运行程序，完成几乎任何任务。对于 RoboMaster 开发者来说，终端更是日常工作的核心工具。本节将带你从零开始，理解终端的工作原理，掌握基本的使用技巧。

==== 终端、Shell 与 Bash

在深入使用之前，让我们先理清几个容易混淆的概念：终端（Terminal）、Shell 和 Bash。

终端，准确地说是终端模拟器（Terminal Emulator），是一个图形程序，提供了一个窗口让你输入文字命令。在早期的计算机系统中，终端是一个物理设备——一个带键盘和显示器的硬件，通过电缆连接到主机。如今，这个物理设备被软件模拟了，但"终端"这个名字保留了下来。Ubuntu 默认的终端程序叫 GNOME Terminal，你也可以使用其他终端模拟器如 Konsole、Terminator、Alacritty 等，它们的核心功能是相同的。

Shell 是终端中实际运行的程序，负责解释你输入的命令并执行。当你在终端中输入 `ls` 并按回车，是 Shell 解析这个命令，找到 `ls` 程序，执行它，并把结果显示在终端上。Shell 是你和操作系统内核之间的翻译官，把你的意图转化为系统调用。

Bash（Bourne Again Shell）是最常用的 Shell 程序。它是早期 Bourne Shell（sh）的增强版，几乎所有 Linux 发行版都默认使用 Bash。除了 Bash，还有 Zsh、Fish、Dash 等其他 Shell，它们有各自的特点和语法差异，但基本概念是相通的。本教程主要以 Bash 为例，因为它是最通用的选择。

简单总结：终端是窗口，Shell 是在窗口中运行的程序，Bash 是最常用的 Shell 程序。当人们说"打开终端输入命令"时，实际上是打开终端模拟器，在其中运行的 Bash Shell 里输入命令。

==== 打开终端

在 Ubuntu 桌面环境中，最快捷的方式是按下 `Ctrl+Alt+T`，这会立即打开一个终端窗口。你也可以在应用程序菜单中搜索"Terminal"或"终端"来打开它。

打开终端后，你会看到一个提示符（prompt），类似于：

```
username@hostname:~$
```

这个提示符包含了几个信息：`username` 是当前登录的用户名，`hostname` 是计算机的名称，`~` 表示当前所在的目录（`~` 是用户主目录的简写），`$` 表示这是一个普通用户（如果是 root 用户，会显示 `#`）。提示符的格式是可以自定义的，不同的系统或配置可能看起来不同。

现在你可以输入命令了。试着输入 `echo "Hello, Linux!"` 并按回车：

```bash
$ echo "Hello, Linux!"
Hello, Linux!
```

恭喜，你刚刚执行了第一个 Linux 命令！`echo` 命令的作用是把后面的文字打印出来，这是最简单的命令之一，但它验证了你的终端正在正常工作。

==== 命令的格式

Linux 命令遵循一个通用的格式：

```
命令 [选项] [参数]
```

命令是你要执行的程序名，选项（options）修改命令的行为，参数（arguments）是命令操作的对象。选项和参数都是可选的，具体取决于命令。

让我们以 `ls` 命令为例。`ls` 用于列出目录内容，是最常用的命令之一：

```bash
# 最简单的形式，列出当前目录的内容
$ ls
Desktop  Documents  Downloads  Music  Pictures  Videos

# 带选项：-l 表示详细列表格式
$ ls -l
total 24
drwxr-xr-x 2 user user 4096 Jan 15 10:00 Desktop
drwxr-xr-x 2 user user 4096 Jan 15 10:00 Documents
...

# 带参数：指定要列出的目录
$ ls /usr/bin
[大量程序名]

# 同时带选项和参数
$ ls -l /usr/bin
[详细列表]
```

选项通常有两种形式：短选项以单个连字符开头，后跟一个字母（如 `-l`）；长选项以两个连字符开头，后跟完整的单词（如 `--long`）。许多选项同时有短形式和长形式，例如 `-a` 和 `--all` 是等价的。短选项可以组合在一起，`ls -la` 等价于 `ls -l -a`。

不同的命令有不同的选项和参数规则。记住所有命令的所有选项是不现实的，关键是知道如何查找帮助信息——这正是下一节要讲的内容。

==== 获取帮助

Linux 命令众多，选项繁杂，没有人能记住所有的细节。好消息是，Linux 提供了完善的帮助系统，让你可以随时查阅命令的用法。

最全面的帮助来自手册页（man pages）。几乎每个命令都有对应的手册页，使用 `man` 命令查看：

```bash
$ man ls
```

这会打开 `ls` 命令的手册页，包含了命令的详细说明、所有选项的解释、使用示例等。手册页使用 `less` 程序显示，你可以用方向键或 `j`/`k` 上下滚动，用 `/` 搜索，按 `q` 退出。

手册页非常详尽，有时候你只需要快速查看常用选项。这时可以使用 `--help` 选项，大多数命令都支持它：

```bash
$ ls --help
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
...
```

输出会比手册页简短，直接在终端中显示，适合快速参考。

对于完全不熟悉的命令，`tldr`（Too Long; Didn't Read）是一个非常友好的工具。它提供简洁实用的命令示例，比手册页更容易理解：

```bash
# 首先安装 tldr
$ sudo apt install tldr

# 查看命令的简明帮助
$ tldr tar
tar

Archiving utility.
...

- Create an archive from files:
    tar cvf target.tar file1 file2 file3

- Extract an archive in the current directory:
    tar xvf source.tar
...
```

`tldr` 直接给出常见用法的例子，非常适合学习新命令。

还有一个有用的命令是 `type`，它告诉你某个命令是什么：

```bash
$ type ls
ls is aliased to `ls --color=auto'

$ type cd
cd is a shell builtin

$ type python3
python3 is /usr/bin/python3
```

这可以帮助你了解命令是内置命令、外部程序还是别名。

==== 命令历史与自动补全

高效使用终端的关键是少打字。Shell 提供了多种机制帮助你减少输入。

Tab 键是你最好的朋友。当你输入命令或路径的一部分时，按 Tab 键，Shell 会尝试自动补全。如果只有一个匹配项，会直接补全；如果有多个匹配项，按两次 Tab 会列出所有可能的选项：

```bash
# 输入 "cd Doc" 然后按 Tab
$ cd Doc<Tab>
$ cd Documents/  # 自动补全

# 输入 "ls /usr/l" 然后按 Tab Tab
$ ls /usr/l<Tab><Tab>
lib/    lib64/  local/  # 显示所有可能的选项
```

自动补全不仅适用于命令和路径，还适用于选项（需要安装 bash-completion 包）、Git 分支名、SSH 主机名等。养成频繁按 Tab 的习惯，可以大大提高输入效率并减少拼写错误。

命令历史让你可以重用之前输入过的命令。按上箭头 `↑` 可以回溯到上一条命令，继续按可以查看更早的命令；下箭头 `↓` 可以向前浏览。找到想要的命令后，可以直接按回车执行，也可以编辑后再执行。

更强大的是反向搜索功能。按 `Ctrl+R`，然后输入关键词，Shell 会搜索历史中包含该关键词的命令：

```bash
# 按 Ctrl+R，然后输入 "git"
(reverse-i-search)`git': git push origin main
```

继续按 `Ctrl+R` 可以查看更早的匹配项。找到想要的命令后，按回车执行，或按右箭头将其放到命令行上编辑。这个功能在你想重复执行某个复杂命令但记不清完整内容时非常有用。

历史命令保存在 `~/.bash_history` 文件中，默认保存最近的 1000 条（可配置）。你可以用 `history` 命令查看历史列表，用 `!n` 执行第 n 条历史命令，用 `!!` 执行上一条命令。

==== 常用快捷键

掌握终端快捷键可以让你的操作更加流畅。以下是最重要的几个：

`Ctrl+C` 是最常用的快捷键，用于中断当前正在运行的命令。如果一个程序运行时间太长，或者你不小心启动了错误的命令，按 `Ctrl+C` 可以强制终止它。这会向程序发送 SIGINT 信号，大多数程序会响应这个信号并退出。

```bash
# 运行一个长时间的命令
$ sleep 1000
^C  # 按 Ctrl+C 中断
$   # 回到提示符
```

`Ctrl+D` 表示输入结束（EOF）。在提示符下按 `Ctrl+D` 会退出当前 Shell（相当于输入 `exit`）。在某些交互式程序中，`Ctrl+D` 表示输入完成。

`Ctrl+Z` 暂停当前程序并放到后台。程序不会终止，只是暂停执行。你可以用 `fg` 命令把它恢复到前台，或用 `bg` 让它在后台继续运行。这在你需要暂时做其他事情但不想终止当前程序时很有用。

`Ctrl+L` 清屏，相当于 `clear` 命令。当终端内容太多变得混乱时，这个快捷键可以让你获得一个干净的屏幕，但不会影响命令历史或当前正在输入的内容。

编辑命令行时，以下快捷键也很有用：

- `Ctrl+A`：移动光标到行首
- `Ctrl+E`：移动光标到行尾
- `Ctrl+U`：删除光标前的所有内容
- `Ctrl+K`：删除光标后的所有内容
- `Ctrl+W`：删除光标前的一个单词
- `Alt+B`：向后移动一个单词
- `Alt+F`：向前移动一个单词

这些快捷键源自 Emacs 编辑器的键绑定，在许多命令行程序中都通用。一开始可能记不住这么多，但随着使用它们会变成肌肉记忆。

==== 通配符

通配符（wildcards）让你可以用模式匹配多个文件，而不需要一个个地输入文件名。Shell 会在执行命令前展开通配符，将其替换为匹配的文件列表。

星号 `*` 匹配任意数量的任意字符（包括零个字符）。这是最常用的通配符：

```bash
# 列出所有 .cpp 文件
$ ls *.cpp
main.cpp  detector.cpp  tracker.cpp

# 列出所有以 test 开头的文件
$ ls test*
test_detector.cpp  test_tracker.cpp  test_results.txt

# 删除所有 .o 文件（小心使用！）
$ rm *.o
```

问号 `?` 匹配恰好一个任意字符：

```bash
# 匹配 file1.txt, file2.txt, ... 但不匹配 file10.txt
$ ls file?.txt
file1.txt  file2.txt  file3.txt
```

方括号 `[]` 匹配其中的任意一个字符：

```bash
# 匹配 file1.txt 或 file2.txt
$ ls file[12].txt
file1.txt  file2.txt

# 匹配任意数字
$ ls file[0-9].txt
file0.txt  file1.txt  ...

# 匹配任意字母
$ ls file[a-z].txt
filea.txt  fileb.txt  ...
```

使用通配符时要小心，特别是与 `rm` 等危险命令一起使用时。一个好习惯是先用 `ls` 加通配符查看会匹配哪些文件，确认无误后再用 `rm`：

```bash
# 先查看会删除哪些文件
$ ls *.tmp
cache1.tmp  cache2.tmp  temp.tmp

# 确认后再删除
$ rm *.tmp
```

另一个需要注意的是，如果通配符没有匹配到任何文件，默认行为是保持原样。这可能导致意外的结果：

```bash
# 如果没有 .xyz 文件
$ ls *.xyz
ls: cannot access '*.xyz': No such file or directory
```

==== 输入输出重定向

每个程序都有三个标准的数据流：标准输入（stdin）、标准输出（stdout）和标准错误（stderr）。默认情况下，标准输入来自键盘，标准输出和标准错误都显示在终端上。重定向让你可以改变这些数据流的来源和去向。

`>` 将标准输出重定向到文件。如果文件存在，会被覆盖；如果不存在，会被创建：

```bash
# 将 ls 的输出保存到文件
$ ls -l > filelist.txt

# 查看文件内容
$ cat filelist.txt
total 24
drwxr-xr-x 2 user user 4096 Jan 15 10:00 Desktop
...
```

`>>` 将标准输出追加到文件末尾，不会覆盖原有内容：

```bash
# 追加内容到文件
$ echo "New line" >> filelist.txt
```

`<` 将文件内容作为标准输入：

```bash
# 从文件读取输入
$ sort < unsorted.txt
```

标准错误（错误信息）默认不会被 `>` 重定向。要重定向标准错误，使用 `2>`：

```bash
# 将错误信息重定向到文件
$ ls nonexistent 2> error.log

# 将标准输出和标准错误分别重定向
$ command > output.log 2> error.log

# 将标准错误重定向到标准输出（常用于日志记录）
$ command > all.log 2>&1

# 更简洁的写法（Bash 4+）
$ command &> all.log
```

`2>&1` 的含义是"将文件描述符 2（标准错误）重定向到文件描述符 1（标准输出）当前指向的地方"。顺序很重要：`> file 2>&1` 是正确的（先重定向标准输出到文件，再让标准错误跟随），而 `2>&1 > file` 是错误的（标准错误会去到原来的标准输出，即终端）。

如果你想丢弃某个输出，可以重定向到 `/dev/null`，这是一个特殊的"黑洞"设备：

```bash
# 丢弃标准输出
$ command > /dev/null

# 丢弃所有输出
$ command > /dev/null 2>&1
```

==== 管道

管道（pipe）是 Unix 哲学的核心体现之一：每个程序做好一件事，复杂的任务通过组合简单程序来完成。管道用 `|` 符号表示，它把一个命令的标准输出连接到另一个命令的标准输入。

```bash
# 列出文件并统计行数
$ ls -l | wc -l
15

# 查找包含特定文本的行
$ cat log.txt | grep "error"
[所有包含 error 的行]

# 排序并去重
$ cat names.txt | sort | uniq
```

管道可以连接多个命令，形成处理流水线：

```bash
# 复杂的例子：找出当前目录下最大的 5 个文件
$ ls -lS | head -6
total 1024
-rw-r--r-- 1 user user 512000 Jan 15 10:00 bigfile.dat
-rw-r--r-- 1 user user 256000 Jan 15 10:00 medium.dat
...
```

这个命令的工作流程是：`ls -lS` 列出文件并按大小排序，输出通过管道传给 `head -6`，后者只保留前 6 行（包括 total 行）。

管道让你可以构建强大的数据处理流程。一些常用的管道组件包括：

- `grep`：过滤包含特定模式的行
- `sort`：排序
- `uniq`：去除相邻的重复行（通常与 sort 配合使用）
- `wc`：统计行数、单词数、字符数
- `head` / `tail`：只保留开头/结尾的几行
- `cut`：提取列
- `awk` / `sed`：更强大的文本处理

学习这些工具的基本用法，你就能通过管道组合解决各种文本处理问题。这是命令行的威力所在——不需要编写程序，只需要把现有工具连接起来。

==== 后台运行

默认情况下，当你运行一个命令时，Shell 会等待它完成才显示下一个提示符。对于长时间运行的任务，你可能希望让它在后台运行，这样可以继续做其他事情。

在命令末尾加上 `&`，命令会在后台启动：

```bash
$ long_running_command &
[1] 12345
$  # 立即返回提示符
```

`[1]` 是作业编号，`12345` 是进程 ID。命令在后台运行，你可以继续输入其他命令。

`jobs` 命令列出当前 Shell 的后台作业：

```bash
$ jobs
[1]+  Running                 long_running_command &
```

`fg` 把后台作业带回前台，`bg` 让暂停的作业在后台继续运行：

```bash
# 把作业 1 带到前台
$ fg %1

# 让作业 1 在后台继续
$ bg %1
```

前面提到的 `Ctrl+Z` 可以暂停当前前台程序，然后用 `bg` 让它在后台继续：

```bash
$ long_command
^Z  # 按 Ctrl+Z 暂停
[1]+  Stopped                 long_command
$ bg
[1]+ long_command &
$  # 命令在后台继续运行
```

但是，后台作业仍然与当前终端关联。如果你关闭终端，后台作业也会被终止。要让命令在终端关闭后继续运行，使用 `nohup`：

```bash
$ nohup long_command &
nohup: ignoring input and appending output to 'nohup.out'
[1] 12345
```

`nohup` 让命令忽略挂起信号（SIGHUP），即使终端关闭也会继续运行。输出会被保存到 `nohup.out` 文件。

对于更复杂的需求，可以使用 `screen` 或 `tmux` 这样的终端复用器。它们允许你创建多个虚拟终端会话，断开连接后会话保持运行，之后可以重新连接。这对于远程服务器管理特别有用。

==== 环境变量与 PATH

环境变量是 Shell 中存储配置信息的机制。它们是键值对，影响 Shell 和程序的行为。使用 `echo $变量名` 可以查看环境变量的值：

```bash
$ echo $HOME
/home/username

$ echo $USER
username

$ echo $SHELL
/bin/bash
```

`env` 命令列出所有环境变量，`export` 命令设置环境变量：

```bash
# 设置环境变量
$ export MY_VAR="hello"

# 验证
$ echo $MY_VAR
hello
```

`export` 设置的变量会传递给子进程。如果只是 `MY_VAR="hello"`（不带 `export`），变量只在当前 Shell 中有效，不会传给运行的程序。

最重要的环境变量之一是 `PATH`。它决定了 Shell 在哪些目录中搜索可执行程序。当你输入一个命令时，Shell 会按 PATH 中列出的目录顺序查找同名的可执行文件：

```bash
$ echo $PATH
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
```

PATH 中的目录用冒号分隔。这就解释了为什么你可以直接输入 `ls` 而不是 `/bin/ls`——因为 `/bin` 在 PATH 中。

如果你安装了程序到非标准位置，需要把它的目录加入 PATH：

```bash
# 临时添加到 PATH（当前 Shell 有效）
$ export PATH="$PATH:/opt/myprogram/bin"

# 永久添加（编辑 ~/.bashrc）
$ echo 'export PATH="$PATH:/opt/myprogram/bin"' >> ~/.bashrc
$ source ~/.bashrc  # 立即生效
```

`~/.bashrc` 是 Bash 的配置文件，每次启动交互式 Shell 时会执行。在这里设置的环境变量会对所有新的终端窗口生效。

另一个常见的需求是设置库路径。当程序运行时需要加载共享库，系统会在 `LD_LIBRARY_PATH` 指定的目录中查找：

```bash
$ export LD_LIBRARY_PATH="/opt/cuda/lib64:$LD_LIBRARY_PATH"
```

对于 RoboMaster 开发，你会经常遇到与 ROS 2 相关的环境变量。ROS 2 使用环境变量来定位包、设置域 ID 等。这就是为什么每次打开终端都需要 `source /opt/ros/humble/setup.bash`——这个脚本设置了 ROS 2 需要的所有环境变量。

终端和 Shell 是进入 Linux 世界的钥匙。这里介绍的只是基础，但掌握这些基础已经足够应对日常开发中的大多数情况。随着使用经验的积累，你会逐渐发现更多技巧，命令行会从一个陌生的界面变成一个高效的工具。记住，每个熟练的 Linux 用户都是从第一个命令开始的。保持好奇心，多尝试，多查阅帮助文档，你会越来越得心应手。


=== 文件系统与目录结构
// Linux 的文件组织方式
// - 根目录 / 与目录树
// - 重要目录详解：/home, /etc, /usr, /opt, /var, /tmp, /dev, /proc
// - 绝对路径与相对路径
// - 特殊路径：. .. ~ -
// - 文件类型：普通文件、目录、链接、设备
// - 隐藏文件（.开头）
// === 文件系统与目录结构

理解 Linux 的文件系统是使用这个操作系统的基础。与 Windows 的盘符系统不同，Linux 采用了一种更加统一和优雅的方式来组织文件——一切都从根目录 `/` 开始，形成一棵倒置的树。这种设计不仅仅是审美上的选择，它反映了"一切皆文件"的 Unix 哲学，让系统的管理和编程都变得更加一致。本节将带你深入了解 Linux 的目录结构，理解每个重要目录的用途，掌握路径的表示方法，为后续的文件操作打下基础。

==== 根目录与目录树

Linux 文件系统的起点是根目录，用单个斜杠 `/` 表示。这是整个文件系统的最顶层，所有其他目录和文件都是根目录的子孙。无论你有多少块硬盘、多少个分区，它们最终都会被"挂载"到这棵目录树的某个位置，成为树的一部分。

让我们从根目录开始探索。打开终端，输入 `ls /` 可以看到根目录下的内容：

```bash
$ ls /
bin   dev  home  lib64       media  opt   root  sbin  srv  tmp  var
boot  etc  lib   lost+found  mnt    proc  run   snap  sys  usr
```

每个目录都有特定的用途，遵循文件系统层次标准（Filesystem Hierarchy Standard，FHS）。这个标准定义了 Linux 系统中目录的组织方式，让不同的发行版保持一致，也让用户和开发者知道应该在哪里找什么。

这种结构的一个重要特点是"内容按类型组织，而不是按来源组织"。在 Windows 中，一个程序的所有文件（可执行文件、库、配置、文档）通常都放在 `Program Files` 下的一个文件夹里。在 Linux 中，可执行文件放在 `bin` 目录，库放在 `lib` 目录，配置放在 `etc` 目录，文档放在 `share` 目录。同一个程序的文件分散在多个地方，但同一类型的文件集中在一起。这种组织方式让系统管理更加系统化——要查看所有配置文件，去 `/etc`；要查看所有日志，去 `/var/log`。

==== 重要目录详解

让我们逐一了解最重要的目录。理解它们的用途，你就能在需要时知道去哪里找东西，也知道应该把东西放在哪里。

`/home` 是普通用户的家目录所在地。每个用户都有一个以用户名命名的子目录，如 `/home/alice`、`/home/bob`。用户的个人文件、配置、下载、文档都存放在这里。当你在终端中看到 `~` 符号，它就代表当前用户的家目录。对于用户 `alice` 来说，`~` 等价于 `/home/alice`。

家目录是你的私人空间。你对这个目录有完全的控制权，可以创建、修改、删除任何文件。系统级的目录（如 `/usr`、`/etc`）通常需要管理员权限才能修改，但家目录是你自己的领地。RoboMaster 项目的代码、编译产物、个人配置通常都放在家目录的某个子目录中，如 `~/ros2_ws`（ROS 2 工作空间）或 `~/projects`。

```bash
$ ls ~
Desktop  Documents  Downloads  Music  Pictures  Public  Templates  Videos
ros2_ws  projects   .bashrc    .config  .local
```

注意那些以点开头的文件和目录（如 `.bashrc`、`.config`），它们是隐藏文件，普通的 `ls` 不会显示它们，需要加 `-a` 选项。这些隐藏文件通常存储配置信息，我们稍后会详细讨论。

`/etc` 存放系统级的配置文件。"etc"最初代表"et cetera"（其他），但现在普遍理解为"Editable Text Configuration"（可编辑的文本配置）。几乎所有系统服务和许多应用程序的配置文件都在这里。

```bash
$ ls /etc
apt           hostname    passwd      ssh
bash.bashrc   hosts       profile     sudoers
default       network     resolv.conf systemd
fstab         nginx       shadow      ...
```

一些重要的配置文件包括：`/etc/passwd` 存储用户账户信息，`/etc/hosts` 是本地的域名解析表，`/etc/fstab` 定义了磁盘分区的挂载方式，`/etc/ssh/sshd_config` 配置 SSH 服务器。当你需要修改系统行为时，通常会编辑 `/etc` 下的某个文件。这些修改需要管理员权限（使用 `sudo`），因为它们影响整个系统。

`/usr` 是"Unix System Resources"的缩写，存放用户级的程序和数据。这是文件系统中最大的目录之一，包含了大部分用户命令、库和文档。它的结构镜像了根目录：

```bash
$ ls /usr
bin  games  include  lib  lib64  local  sbin  share  src
```

`/usr/bin` 存放大多数用户命令（如 `gcc`、`python`、`git`），`/usr/lib` 存放程序库，`/usr/include` 存放 C/C++ 头文件，`/usr/share` 存放与架构无关的数据（如文档、图标、翻译）。当你用包管理器安装软件时，大部分文件会被安装到 `/usr` 的相应子目录中。

`/usr/local` 值得特别注意。它用于存放本地安装的软件——不是通过包管理器安装的，而是手动编译安装或从第三方获取的。其结构与 `/usr` 相同（`bin`、`lib`、`include` 等）。当你从源码编译安装软件并使用默认的安装路径时，通常会安装到这里。这种分离让你可以区分系统软件和本地安装的软件，也避免了与包管理器的冲突。

```bash
# 查看本地安装的程序
$ ls /usr/local/bin

# 查看本地安装的库
$ ls /usr/local/lib
```

`/opt` 是"optional"的缩写，用于安装第三方软件包。与 `/usr/local` 不同，`/opt` 下的软件通常保持自包含的结构——一个软件的所有文件都在一个子目录中，如 `/opt/google/chrome`、`/opt/ros/humble`。ROS 2 就默认安装在 `/opt/ros/` 下，每个发行版一个子目录。

```bash
$ ls /opt
google  ros  cuda

$ ls /opt/ros
humble  iron
```

这种组织方式的好处是软件彼此隔离，卸载时只需删除整个目录。但也意味着这些程序的可执行文件不在系统 PATH 中，需要手动添加或 source 相应的设置脚本（如 `source /opt/ros/humble/setup.bash`）。

`/var` 存放可变的数据文件，即运行时会改变的内容。"var"代表"variable"。最重要的子目录包括：

- `/var/log`：系统和程序的日志文件。当程序出问题时，这里通常是第一个查看的地方。
- `/var/cache`：应用程序的缓存数据。包管理器的下载缓存通常在这里。
- `/var/lib`：程序的状态信息。数据库文件、包管理器的数据库等。
- `/var/tmp`：比 `/tmp` 更持久的临时文件，重启后可能保留。

```bash
# 查看系统日志
$ ls /var/log
syslog  auth.log  kern.log  apt  nginx  ...

# 查看最近的系统日志
$ tail /var/log/syslog
```

`/tmp` 是临时文件目录。任何用户都可以在这里创建文件，但这些文件是临时的——系统重启后通常会被清空。程序运行时的临时文件、下载中的文件、解压的临时内容都可以放在这里。

```bash
$ ls /tmp
systemd-private-xxx  ssh-xxx  ...
```

由于 `/tmp` 对所有用户开放，存在安全隐患。敏感的临时数据应该放在更安全的位置，如用户自己的目录。现代系统通常会为每个用户创建私有的临时目录，可以通过 `mktemp` 命令创建安全的临时文件。

`/dev` 是"devices"的缩写，包含设备文件。在 Linux 的"一切皆文件"哲学中，硬件设备也表现为文件。硬盘是 `/dev/sda`，分区是 `/dev/sda1`，终端是 `/dev/tty`，随机数生成器是 `/dev/random`。

```bash
$ ls /dev
sda  sda1  sda2  tty  null  zero  random  urandom  ...
```

一些有趣的设备文件：

- `/dev/null`：黑洞设备，写入的任何内容都会消失，读取会立即返回 EOF。常用于丢弃不需要的输出。
- `/dev/zero`：读取会返回无限的零字节，常用于创建空文件或清零磁盘。
- `/dev/random` 和 `/dev/urandom`：随机数生成器，用于加密等需要随机性的场合。
- `/dev/ttyUSB0`：USB 串口设备，RoboMaster 开发中经常用到。

```bash
# 丢弃命令的输出
$ command > /dev/null

# 创建一个 1MB 的空文件
$ dd if=/dev/zero of=emptyfile bs=1M count=1
```

`/proc` 是一个虚拟文件系统，不占用磁盘空间，而是提供了进程和内核信息的接口。每个运行中的进程在 `/proc` 下都有一个以进程 ID 命名的目录，包含该进程的各种信息。

```bash
$ ls /proc
1  2  3  ...  12345  ...  cpuinfo  meminfo  version  ...

# 查看 CPU 信息
$ cat /proc/cpuinfo
processor   : 0
vendor_id   : GenuineIntel
model name  : Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
...

# 查看内存信息
$ cat /proc/meminfo
MemTotal:       16384000 kB
MemFree:         8192000 kB
...

# 查看进程 12345 的命令行
$ cat /proc/12345/cmdline
/usr/bin/python3 my_script.py
```

`/proc` 是系统监控工具（如 `top`、`htop`、`ps`）获取信息的来源。了解它的存在可以帮助你在需要时直接获取底层信息。

类似地，`/sys` 也是一个虚拟文件系统，提供了对内核子系统、设备驱动和硬件设备的访问。它比 `/proc` 更结构化，主要用于设备管理和内核参数调整。

```bash
# 查看 CPU 的在线状态
$ cat /sys/devices/system/cpu/online
0-7

# 调整屏幕亮度（如果支持）
$ cat /sys/class/backlight/intel_backlight/brightness
500
```

==== 绝对路径与相对路径

在 Linux 中定位文件有两种方式：绝对路径和相对路径。理解它们的区别对于正确使用命令行和编写脚本至关重要。

绝对路径从根目录 `/` 开始，完整地描述了文件在目录树中的位置。无论你当前在哪个目录，绝对路径都指向同一个文件。

```bash
/home/alice/projects/rm_vision/src/main.cpp
/etc/ssh/sshd_config
/opt/ros/humble/setup.bash
```

绝对路径的优点是明确无歧义，缺点是通常比较长。

相对路径从当前工作目录出发，描述如何到达目标文件。它不以 `/` 开头。

```bash
# 假设当前目录是 /home/alice/projects/rm_vision
$ ls src/main.cpp          # 相对路径
$ ls ./src/main.cpp        # 同上，./ 表示当前目录
$ ls ../rm_control/        # 上级目录的 rm_control
```

相对路径更简短，但它的含义取决于当前目录。同样是 `src/main.cpp`，在不同的目录下指向不同的文件。

在脚本和配置文件中，通常推荐使用绝对路径，因为脚本可能在任何目录下执行。但在交互式使用中，相对路径更方便。

==== 特殊路径符号

Shell 提供了几个特殊的路径符号，让路径表示更加简洁。

`.`（单个点）表示当前目录。在大多数情况下，`./file` 和 `file` 是等价的。但在执行当前目录下的程序时，必须使用 `./`：

```bash
# 执行当前目录下的程序
$ ./my_program

# 这是安全特性，防止当前目录下的恶意程序覆盖系统命令
$ my_program  # 这会在 PATH 中查找，而不是当前目录
```

`..`（两个点）表示父目录（上级目录）。可以链式使用：

```bash
$ pwd
/home/alice/projects/rm_vision/src

$ cd ..
$ pwd
/home/alice/projects/rm_vision

$ cd ../..
$ pwd
/home/alice/projects
```

`~`（波浪号）表示当前用户的家目录。这是 Shell 提供的便利功能：

```bash
$ echo ~
/home/alice

$ cd ~/projects
$ pwd
/home/alice/projects

# 也可以指定其他用户的家目录
$ echo ~bob
/home/bob
```

`-`（减号）在 `cd` 命令中表示上一个工作目录，让你可以在两个目录之间快速切换：

```bash
$ cd /var/log
$ cd ~/projects
$ cd -         # 回到 /var/log
$ cd -         # 回到 ~/projects
```

这些符号可以组合使用：

```bash
$ ls ~/projects/../Documents    # 等价于 ls /home/alice/Documents
$ cd ~/.config                  # 进入配置目录
```

==== 文件类型

Linux 文件系统中不只有普通文件和目录。`ls -l` 的输出第一个字符就表示文件类型：

```bash
$ ls -l /
drwxr-xr-x   2 root root  4096 Jan 15 10:00 bin
-rw-r--r--   1 root root   220 Jan 15 10:00 .bashrc
lrwxrwxrwx   1 root root     7 Jan 15 10:00 lib -> usr/lib
crw-rw-rw-   1 root root 1,  3 Jan 15 10:00 /dev/null
brw-rw----   1 root disk 8,  0 Jan 15 10:00 /dev/sda
srwxrwxrwx   1 root root     0 Jan 15 10:00 /run/docker.sock
prw-r--r--   1 root root     0 Jan 15 10:00 /tmp/mypipe
```

让我们逐一了解每种类型。

普通文件（`-`）是最常见的类型，包括文本文件、二进制文件、图片、可执行程序等。Linux 不像 Windows 那样严重依赖文件扩展名来识别文件类型——扩展名只是命名约定，方便人类识别，系统本身通过文件内容（"魔数"）来判断类型。

```bash
# file 命令可以检测文件的实际类型
$ file main.cpp
main.cpp: C++ source, ASCII text

$ file /bin/ls
/bin/ls: ELF 64-bit LSB shared object, x86-64, ...

$ file photo.jpg
photo.jpg: JPEG image data, JFIF standard 1.01, ...
```

目录（`d`）是一种特殊的文件，包含其他文件和目录的列表。从用户角度看，目录就是文件夹；从系统角度看，目录文件存储了名称到 inode 的映射。

符号链接（`l`），也叫软链接，类似于 Windows 的快捷方式。它存储了另一个文件的路径，访问链接时会被重定向到目标文件。链接可以指向文件或目录，可以跨文件系统。

```bash
# 创建符号链接
$ ln -s /opt/ros/humble ~/ros

# 现在 ~/ros 指向 /opt/ros/humble
$ ls -l ~/ros
lrwxrwxrwx 1 alice alice 15 Jan 15 10:00 /home/alice/ros -> /opt/ros/humble

# 访问链接就像访问原始目录
$ ls ~/ros/setup.bash
/home/alice/ros/setup.bash
```

符号链接在 RoboMaster 开发中很有用。你可以为常用的长路径创建短链接，或者让多个名称指向同一个配置文件。如果链接的目标被删除，链接会成为"悬空链接"，访问时会报错。

硬链接是另一种链接类型，它直接指向文件的 inode（文件系统中的数据结构），而不是路径。硬链接和原文件是完全平等的，删除其中一个，另一个仍然有效。硬链接不能指向目录，不能跨文件系统。

```bash
# 创建硬链接（不带 -s 选项）
$ ln original.txt hardlink.txt

# 两个名称指向同一个 inode
$ ls -li original.txt hardlink.txt
12345678 -rw-r--r-- 2 alice alice 100 Jan 15 10:00 original.txt
12345678 -rw-r--r-- 2 alice alice 100 Jan 15 10:00 hardlink.txt
```

注意 inode 号（12345678）相同，链接计数（第三列的 2）表示有两个名称指向这个文件。

字符设备（`c`）和块设备（`b`）是设备文件。字符设备按字符流处理数据（如终端、串口），块设备按块处理数据（如硬盘）。这些文件通常在 `/dev` 目录下，由系统管理。

套接字（`s`）和命名管道（`p`）是用于进程间通信的特殊文件。套接字支持双向通信（如 `/var/run/docker.sock` 用于与 Docker 守护进程通信），命名管道支持单向的先进先出数据流。这些是高级主题，日常使用中较少直接接触。

==== 隐藏文件

在 Linux 中，文件名以点（`.`）开头的文件被视为隐藏文件。这不是一个特殊的文件属性，仅仅是命名约定——`ls` 默认不显示这些文件，但加上 `-a` 选项就会显示。

```bash
$ ls
Documents  Downloads  Pictures

$ ls -a
.  ..  .bashrc  .config  .local  .ssh  Documents  Downloads  Pictures
```

隐藏文件主要用于存储配置和状态信息，避免在日常浏览时造成视觉干扰。用户家目录下通常有大量隐藏文件和目录，每个应用程序都可能创建自己的配置目录。

一些重要的隐藏文件和目录包括：

`~/.bashrc` 是 Bash 的用户配置文件。每次打开新的交互式 Shell 时，这个文件会被执行。你可以在这里设置环境变量、定义别名、配置提示符等。

```bash
# 查看 .bashrc 的内容
$ cat ~/.bashrc

# 常见的自定义内容
export PATH="$PATH:/opt/myprogram/bin"
alias ll='ls -alF'
alias gs='git status'
```

修改 `.bashrc` 后，需要重新打开终端或执行 `source ~/.bashrc` 使改动生效。

`~/.bash_history` 存储命令历史。你之前输入的命令都记录在这里，这就是为什么按上箭头可以找到历史命令。

`~/.ssh/` 目录存储 SSH 相关的文件：`id_rsa` 和 `id_rsa.pub` 是你的 SSH 密钥对，`known_hosts` 记录了你连接过的服务器，`config` 可以配置 SSH 连接的各种选项。

```bash
$ ls -la ~/.ssh
-rw-------  1 alice alice 1679 Jan 15 10:00 id_rsa       # 私钥，必须保密
-rw-r--r--  1 alice alice  400 Jan 15 10:00 id_rsa.pub   # 公钥，可以分享
-rw-r--r--  1 alice alice 1234 Jan 15 10:00 known_hosts
-rw-r--r--  1 alice alice  200 Jan 15 10:00 config
```

`~/.config/` 是现代应用程序存放配置的标准位置，遵循 XDG Base Directory 规范。很多程序会在这里创建自己的子目录，如 `~/.config/Code/`（VS Code）、`~/.config/nvim/`（Neovim）。

`~/.local/` 存储用户级的数据和程序。`~/.local/bin/` 可以放置用户自己的可执行文件，很多用户会把这个目录加入 PATH。`~/.local/share/` 存储应用程序的数据。

```bash
# 将 ~/.local/bin 加入 PATH（在 .bashrc 中添加）
export PATH="$PATH:$HOME/.local/bin"
```

`~/.cache/` 存储缓存数据，可以安全删除（程序会重新生成需要的缓存）。当磁盘空间紧张时，这是一个可以清理的地方。

理解文件系统结构是 Linux 使用的基础。当你知道配置文件在 `/etc`、用户文件在 `/home`、日志在 `/var/log`、设备在 `/dev` 时，你就能更有效地管理系统和排查问题。这种知识也会帮助你理解 ROS 2 的安装位置（`/opt/ros`）、为什么需要 source setup 脚本、以及如何组织自己的项目文件。随着使用经验的积累，这些目录会变得像你自己房间里的抽屉一样熟悉——你总是知道去哪里找什么。


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

掌握了文件系统的结构之后，接下来要学习如何在这个结构中导航和操作。文件与目录操作是 Linux 命令行最基础也是最常用的技能——创建文件、复制目录、移动文件、查看内容、搜索文件——这些操作构成了日常工作的基础。本节将详细介绍这些命令，从最简单的目录切换到复杂的文件查找，从基本的文件复制到灵活的压缩解压。这些命令你会每天使用，熟练掌握它们会显著提升你的工作效率。

==== 目录导航

在命令行中工作，首先要知道自己在哪里，然后才能去想去的地方。

`pwd`（print working directory）显示当前工作目录的绝对路径。当你在目录之间跳转后不确定自己的位置时，`pwd` 可以告诉你：

```bash
$ pwd
/home/alice/projects/rm_vision
```

这个命令非常简单，没有常用的选项，但它是定位自己的基本工具。

`cd`（change directory）用于切换当前工作目录。它是最常用的命令之一：

```bash
# 切换到指定目录（绝对路径）
$ cd /usr/local/bin

# 切换到指定目录（相对路径）
$ cd src/detector

# 回到家目录
$ cd ~
$ cd          # 不带参数也会回到家目录

# 回到上级目录
$ cd ..

# 回到上两级目录
$ cd ../..

# 回到上一个工作目录
$ cd -
/home/alice/projects  # 显示切换到的目录
```

一个常见的工作流程是：用 `cd` 进入项目目录，用 `pwd` 确认位置，然后开始工作。RoboMaster 开发中，你可能会频繁在 ROS 2 工作空间、源码目录、构建目录之间切换：

```bash
$ cd ~/ros2_ws           # 进入工作空间
$ cd src/rm_vision       # 进入包的源码
$ cd ../../build         # 去构建目录查看编译产物
$ cd -                   # 回到刚才的 src/rm_vision
```

养成使用 Tab 补全的习惯可以大大加快目录切换的速度。输入 `cd ~/pro<Tab>` 会自动补全为 `cd ~/projects/`，然后继续输入和补全。

==== 查看目录内容

`ls`（list）列出目录的内容，是使用频率最高的命令之一。它的基本用法很简单，但选项丰富，可以满足各种需求。

```bash
# 列出当前目录的内容
$ ls
CMakeLists.txt  include  src  test  README.md

# 列出指定目录的内容
$ ls /usr/bin

# 列出多个目录的内容
$ ls src include
```

最常用的选项组合是 `-la`，它显示详细信息（`-l`）并包含隐藏文件（`-a`）：

```bash
$ ls -la
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
5. 大小（字节）（`4096`）
6. 最后修改时间（`Jan 15 10:00`）
7. 文件名（`src`）

其他有用的 `ls` 选项：

```bash
# -h 人类可读的文件大小（KB、MB、GB）
$ ls -lh
-rw-r--r-- 1 alice alice 1.2K Jan 15 10:00 CMakeLists.txt
-rw-r--r-- 1 alice alice 156M Jan 15 10:00 model.onnx

# -t 按修改时间排序（最新的在前）
$ ls -lt

# -S 按文件大小排序（最大的在前）
$ ls -lS

# -r 反向排序
$ ls -ltr   # 按时间排序，最旧的在前

# -R 递归列出子目录
$ ls -R

# --color 彩色显示（现代系统通常默认启用）
$ ls --color=auto
```

很多用户会在 `.bashrc` 中定义别名来简化常用的 `ls` 命令：

```bash
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
```

`tree` 命令以树状结构显示目录内容，对于理解项目结构非常有帮助。它不是系统自带的，需要安装：

```bash
$ sudo apt install tree

$ tree
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
$ tree -L 2

# -d 只显示目录
$ tree -d

# -I 排除匹配模式的文件
$ tree -I 'build|__pycache__'

# --dirsfirst 目录排在前面
$ tree --dirsfirst
```

==== 创建文件与目录

`touch` 命令创建空文件，或更新现有文件的时间戳：

```bash
# 创建空文件
$ touch newfile.txt
$ ls -l newfile.txt
-rw-r--r-- 1 alice alice 0 Jan 15 10:00 newfile.txt

# 创建多个文件
$ touch file1.txt file2.txt file3.txt

# 如果文件已存在，更新其修改时间
$ touch existingfile.txt
```

`touch` 主要用于快速创建空文件。如果你需要创建有内容的文件，通常会用重定向或编辑器：

```bash
# 用重定向创建有内容的文件
$ echo "Hello, World!" > hello.txt

# 用 cat 和 heredoc 创建多行文件
$ cat > config.txt << EOF
setting1=value1
setting2=value2
EOF
```

`mkdir`（make directory）创建目录：

```bash
# 创建单个目录
$ mkdir myproject

# 创建多个目录
$ mkdir dir1 dir2 dir3

# -p 创建多级目录（父目录不存在时自动创建）
$ mkdir -p projects/rm_vision/src/detector

# 不加 -p 时，如果父目录不存在会报错
$ mkdir projects/newproject/src
mkdir: cannot create directory 'projects/newproject/src': No such file or directory
```

`-p` 选项非常实用，它让你可以一次性创建完整的目录结构，而不用一级一级地创建。在脚本中使用 `mkdir -p` 也更安全——如果目录已存在，它不会报错，而是静默成功。

创建 RoboMaster 项目的典型目录结构：

```bash
$ mkdir -p rm_vision/{include/rm_vision,src,test,config,launch,models}
$ tree rm_vision
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
$ cp source.txt destination.txt

# 复制文件到目录
$ cp file.txt /path/to/directory/

# 复制多个文件到目录
$ cp file1.txt file2.txt file3.txt /path/to/directory/

# -r 或 -R 递归复制目录（复制目录必须加此选项）
$ cp -r src_dir dest_dir

# -i 覆盖前询问确认
$ cp -i source.txt existing.txt
cp: overwrite 'existing.txt'? 

# -v 显示复制过程（verbose）
$ cp -rv project/ backup/
'project/src/main.cpp' -> 'backup/src/main.cpp'
'project/include/header.h' -> 'backup/include/header.h'
...

# -p 保留文件属性（时间戳、权限等）
$ cp -p important.txt backup.txt

# -a 归档模式，等同于 -dR --preserve=all，完整复制
$ cp -a project/ project_backup/
```

`mv`（move）移动文件或目录，也用于重命名：

```bash
# 移动文件
$ mv file.txt /path/to/directory/

# 移动并重命名
$ mv oldname.txt /path/to/newname.txt

# 重命名（同一目录内移动）
$ mv oldname.txt newname.txt

# 移动目录（不需要 -r）
$ mv mydir /path/to/destination/

# -i 覆盖前询问
$ mv -i source.txt existing.txt

# -v 显示移动过程
$ mv -v *.cpp src/
'main.cpp' -> 'src/main.cpp'
'detector.cpp' -> 'src/detector.cpp'
```

`mv` 在同一文件系统内移动文件时非常快，因为它只是修改目录条目，不实际复制数据。跨文件系统移动时，`mv` 会先复制再删除原文件。

`rm`（remove）删除文件或目录。这是一个危险的命令，因为 Linux 命令行删除的文件不会进入回收站，而是直接消失：

```bash
# 删除文件
$ rm file.txt

# 删除多个文件
$ rm file1.txt file2.txt file3.txt

# -i 删除前询问确认
$ rm -i important.txt
rm: remove regular file 'important.txt'? 

# -r 或 -R 递归删除目录
$ rm -r mydir

# -f 强制删除，不询问确认，忽略不存在的文件
$ rm -f maybe_exists.txt

# -v 显示删除过程
$ rm -rv old_project/
removed 'old_project/src/main.cpp'
removed 'old_project/src/'
removed 'old_project/'
```

`rm -rf` 是最危险的命令组合——递归删除，强制执行，不询问确认。它可以在瞬间删除大量文件，包括你不想删除的。有一些臭名昭著的事故：

```bash
# 极度危险！不要执行！
$ rm -rf /                    # 删除整个系统
$ rm -rf ~                    # 删除整个家目录
$ rm -rf *                    # 删除当前目录所有内容
$ rm -rf $UNDEFINED_VAR/*     # 如果变量未定义，可能变成 rm -rf /*
```

安全使用 `rm` 的建议：

1. 删除前先用 `ls` 确认要删除的文件
2. 使用 `-i` 选项，特别是配合通配符时
3. 对于重要操作，先移动到临时目录，确认无误后再删除
4. 在脚本中删除前检查变量是否为空
5. 考虑使用 `trash-cli` 这样的工具，删除到回收站而不是直接删除

```bash
# 安全的做法
$ ls *.log                    # 先看看会删除什么
temp.log  debug.log  error.log
$ rm -i *.log                 # 逐个确认

# 或者移动到临时目录
$ mv *.log /tmp/to_delete/
# 确认后再 rm -rf /tmp/to_delete/
```

`rmdir` 只能删除空目录，比 `rm -r` 更安全：

```bash
$ rmdir empty_dir             # 成功删除空目录
$ rmdir non_empty_dir
rmdir: failed to remove 'non_empty_dir': Directory not empty
```

==== 查看文件内容

有多种命令可以查看文件内容，适用于不同的场景。

`cat`（concatenate）将文件内容输出到终端，适合查看小文件：

```bash
# 查看文件内容
$ cat config.yaml
setting1: value1
setting2: value2

# 查看多个文件（连接输出）
$ cat file1.txt file2.txt

# -n 显示行号
$ cat -n script.sh
     1  #!/bin/bash
     2  echo "Hello"
     3  exit 0

# 将多个文件合并为一个
$ cat part1.txt part2.txt part3.txt > combined.txt
```

对于大文件，`cat` 会一次性输出所有内容，刷屏而过，不实用。这时应该使用分页器。

`less` 是一个分页查看器，可以前后滚动浏览大文件：

```bash
$ less largefile.log
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

`less` 的一个重要特性是它不会一次性加载整个文件到内存，所以可以查看非常大的文件（如 GB 级的日志文件）。

还有一个类似的命令 `more`，功能比 `less` 少（只能向前翻页），但在某些最小化系统中可能只有 `more`。俗话说"less is more"——`less` 命令的名字就是对 `more` 的调侃。

`head` 显示文件的开头部分，默认前 10 行：

```bash
# 显示前 10 行
$ head file.txt

# 显示前 n 行
$ head -n 20 file.txt
$ head -20 file.txt       # 简写形式

# 显示前 n 个字节
$ head -c 100 file.txt
```

`tail` 显示文件的末尾部分，默认最后 10 行：

```bash
# 显示最后 10 行
$ tail file.txt

# 显示最后 n 行
$ tail -n 20 file.txt
$ tail -20 file.txt

# -f 实时追踪文件更新（follow）
$ tail -f /var/log/syslog
```

`tail -f` 是查看日志的利器。它会持续监控文件，有新内容追加时立即显示。这对于实时监控程序日志非常有用：

```bash
# 在一个终端中运行程序
$ ./my_program

# 在另一个终端中监控日志
$ tail -f ~/my_program.log
```

按 `Ctrl+C` 停止 `tail -f`。

组合使用这些命令可以完成更复杂的任务：

```bash
# 查看文件的第 11-20 行
$ head -20 file.txt | tail -10

# 实时监控日志，只显示包含 "error" 的行
$ tail -f app.log | grep error

# 查看最近修改的文件的前几行
$ ls -t | head -1 | xargs head
```

==== 查找文件

当你不知道文件在哪里时，查找命令就派上用场了。

`find` 是最强大的文件查找命令，可以按名称、类型、大小、时间等各种条件搜索：

```bash
# 按名称查找（在当前目录及子目录中）
$ find . -name "*.cpp"
./src/main.cpp
./src/detector.cpp
./test/test_detector.cpp

# 在指定目录中查找
$ find /home/alice/projects -name "CMakeLists.txt"

# -iname 忽略大小写
$ find . -iname "readme*"

# 按类型查找：f 文件，d 目录，l 链接
$ find . -type f -name "*.hpp"    # 只找文件
$ find . -type d -name "build"    # 只找目录

# 按大小查找：+大于，-小于
$ find . -size +100M              # 大于 100MB 的文件
$ find . -size -1k                # 小于 1KB 的文件

# 按时间查找：-mtime 修改时间，-atime 访问时间
$ find . -mtime -7                # 7 天内修改过的文件
$ find . -mtime +30               # 30 天前修改的文件

# 组合条件
$ find . -name "*.log" -size +10M -mtime +7

# -exec 对找到的文件执行命令
$ find . -name "*.o" -exec rm {} \;       # 删除所有 .o 文件
$ find . -name "*.cpp" -exec wc -l {} \;  # 统计每个 .cpp 文件的行数

# -delete 直接删除（比 -exec rm 快，但更危险）
$ find . -name "*.tmp" -delete
```

`find` 的 `-exec` 语法可能看起来奇怪：`{}` 是找到的文件名的占位符，`\;` 表示命令结束（分号需要转义）。更高效的变体是用 `+` 代替 `\;`，它会将多个文件名一起传给命令，减少命令调用次数：

```bash
$ find . -name "*.cpp" -exec wc -l {} +
```

`locate` 使用预建的数据库来查找文件，比 `find` 快得多，但可能不是最新的：

```bash
# 安装 locate（如果没有）
$ sudo apt install mlocate

# 更新数据库（需要 sudo）
$ sudo updatedb

# 查找文件
$ locate opencv.hpp
/usr/include/opencv4/opencv2/opencv.hpp

# -i 忽略大小写
$ locate -i readme

# 只计数，不显示结果
$ locate -c "*.py"
```

`locate` 适合快速查找系统文件，但对于刚创建的文件可能找不到（数据库通常每天自动更新一次）。你可以手动运行 `sudo updatedb` 来更新数据库。

`which` 查找命令的可执行文件位置（在 PATH 中搜索）：

```bash
$ which python3
/usr/bin/python3

$ which gcc
/usr/bin/gcc

$ which ros2
/opt/ros/humble/bin/ros2
```

`which` 只搜索 PATH 中的目录，告诉你当你输入某个命令时实际执行的是哪个文件。类似的命令还有 `whereis`（还会显示手册页和源码位置）和 `type`（还能识别别名和内置命令）。

==== 文件信息

有时你需要了解文件的更多信息，而不仅仅是内容。

`file` 命令识别文件的类型，它通过检查文件内容（而不是扩展名）来判断：

```bash
$ file main.cpp
main.cpp: C++ source, UTF-8 Unicode text

$ file /bin/ls
/bin/ls: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, ...

$ file image.png
image.png: PNG image data, 1920 x 1080, 8-bit/color RGBA, non-interlaced

$ file model.onnx
model.onnx: data

$ file archive.tar.gz
archive.tar.gz: gzip compressed data, ...
```

这在处理没有扩展名或扩展名错误的文件时特别有用。

`stat` 显示文件的详细元数据：

```bash
$ stat README.md
  File: README.md
  Size: 1234            Blocks: 8          IO Block: 4096   regular file
Device: 801h/2049d      Inode: 1234567     Links: 1
Access: (0644/-rw-r--r--)  Uid: ( 1000/   alice)   Gid: ( 1000/   alice)
Access: 2024-01-15 10:00:00.000000000 +0800
Modify: 2024-01-15 09:30:00.000000000 +0800
Change: 2024-01-15 09:30:00.000000000 +0800
 Birth: 2024-01-10 08:00:00.000000000 +0800
```

这显示了文件大小、inode 号、权限、所有者、三种时间戳（访问时间、修改时间、状态改变时间）和创建时间（如果文件系统支持）。

`du`（disk usage）显示文件或目录占用的磁盘空间：

```bash
# 显示当前目录的大小
$ du -sh .
256M    .

# 显示各子目录的大小
$ du -sh */
12M     build/
4.0K    config/
8.0K    include/
200M    models/
32M     src/

# 显示所有文件和目录的大小
$ du -ah

# 找出最大的目录
$ du -sh */ | sort -rh | head -5

# -d 限制深度
$ du -h -d 1
```

`-s` 表示汇总（summary），只显示总大小；`-h` 表示人类可读格式。

`df`（disk free）显示文件系统的磁盘空间使用情况：

```bash
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   45G   50G  48% /
/dev/sda2       500G  200G  275G  43% /home
tmpfs           7.8G     0  7.8G   0% /dev/shm
```

`df` 显示的是整个分区的使用情况，而 `du` 显示的是特定目录的大小。当磁盘空间不足时，先用 `df` 看哪个分区满了，再用 `du` 找出哪个目录占用最多空间。

==== 创建链接

链接让一个文件可以有多个名称或路径。我们在上一节介绍了链接的概念，这里讲解如何创建它们。

`ln`（link）命令创建链接，默认创建硬链接，加 `-s` 选项创建符号链接（软链接）：

```bash
# 创建符号链接（最常用）
$ ln -s /opt/ros/humble ~/ros

# 验证链接
$ ls -l ~/ros
lrwxrwxrwx 1 alice alice 15 Jan 15 10:00 /home/alice/ros -> /opt/ros/humble

# 现在可以用 ~/ros 代替 /opt/ros/humble
$ source ~/ros/setup.bash
```

符号链接的常见用途：

```bash
# 为常用的长路径创建短名称
$ ln -s ~/projects/robomaster_vision_2024 ~/rmv

# 切换不同版本的配置
$ ln -s config_competition.yaml config.yaml
# 需要切换时
$ ln -sf config_debug.yaml config.yaml   # -f 强制覆盖现有链接

# 让程序找到库
$ sudo ln -s /usr/local/cuda-11.8 /usr/local/cuda
```

创建硬链接（不常用，但有时有用）：

```bash
# 创建硬链接
$ ln original.txt hardlink.txt

# 两个文件共享相同的内容
$ echo "new content" >> original.txt
$ cat hardlink.txt
... 新内容也出现 ...
```

记住硬链接的限制：不能链接目录，不能跨文件系统。符号链接没有这些限制，所以更常用。

==== 压缩与解压

处理压缩文件是日常工作的一部分——下载的软件包、备份的文件、分享的资料经常是压缩格式的。

`tar`（tape archive）是最常用的归档工具。它本身只是打包，不压缩，但通常与压缩工具一起使用：

```bash
# 创建归档（不压缩）
$ tar cvf archive.tar dir/
# c = create 创建
# v = verbose 显示过程
# f = file 指定文件名

# 创建 gzip 压缩的归档（最常用）
$ tar cvzf archive.tar.gz dir/
# z = gzip 压缩

# 创建 bzip2 压缩的归档（压缩率更高但更慢）
$ tar cvjf archive.tar.bz2 dir/
# j = bzip2 压缩

# 创建 xz 压缩的归档（压缩率最高）
$ tar cvJf archive.tar.xz dir/
# J = xz 压缩
```

解压归档：

```bash
# 解压 tar.gz
$ tar xvzf archive.tar.gz
# x = extract 解压

# 解压 tar.bz2
$ tar xvjf archive.tar.bz2

# 解压 tar.xz
$ tar xvJf archive.tar.xz

# 解压到指定目录
$ tar xvzf archive.tar.gz -C /path/to/destination/

# 查看归档内容（不解压）
$ tar tvf archive.tar.gz
# t = list 列出内容
```

现代版本的 tar 可以自动检测压缩格式，所以解压时可以省略 z/j/J 选项：

```bash
$ tar xvf archive.tar.gz      # 自动检测 gzip
$ tar xvf archive.tar.xz      # 自动检测 xz
```

`gzip` 和 `gunzip` 用于压缩和解压单个文件：

```bash
# 压缩文件（原文件会被替换为 .gz 文件）
$ gzip largefile.log
$ ls
largefile.log.gz

# 解压
$ gunzip largefile.log.gz
# 或
$ gzip -d largefile.log.gz

# 保留原文件
$ gzip -k largefile.log

# 查看压缩文件内容（不解压）
$ zcat largefile.log.gz
$ zless largefile.log.gz     # 分页查看
$ zgrep "error" largefile.log.gz  # 在压缩文件中搜索
```

`zip` 和 `unzip` 处理 ZIP 格式，这是 Windows 世界的标准格式：

```bash
# 创建 zip 归档
$ zip -r archive.zip dir/
# -r = recursive 递归

# 解压 zip
$ unzip archive.zip

# 解压到指定目录
$ unzip archive.zip -d /path/to/destination/

# 查看 zip 内容
$ unzip -l archive.zip
```

各种压缩格式的比较：

- `.tar.gz` 或 `.tgz`：gzip 压缩，最常用，平衡了压缩率和速度
- `.tar.bz2` 或 `.tbz2`：bzip2 压缩，压缩率更高，但压缩/解压更慢
- `.tar.xz`：xz 压缩，压缩率最高，但最慢
- `.zip`：跨平台兼容性最好，Windows 原生支持

在 RoboMaster 开发中，你会经常下载 `.tar.gz` 格式的源码包，备份项目时也通常用这个格式：

```bash
# 下载并解压 OpenCV 源码
$ wget https://github.com/opencv/opencv/archive/4.8.0.tar.gz
$ tar xzf 4.8.0.tar.gz

# 备份项目
$ tar czf rm_vision_backup_$(date +%Y%m%d).tar.gz rm_vision/
```

最后一个命令使用了命令替换 `$(date +%Y%m%d)` 来生成带日期的文件名，如 `rm_vision_backup_20240115.tar.gz`。

文件与目录操作是 Linux 使用的基本功。这些命令你会每天使用，熟练程度直接影响工作效率。不需要一次记住所有选项——记住常用的几个，其他的需要时查帮助文档。随着实践的积累，这些命令会变成条件反射，让你在命令行中如鱼得水。


=== 文本编辑与处理
// 命令行下的文本操作
// - nano：新手友好的编辑器
// - vim：高效但需要学习的编辑器（基础操作）
// - 文本搜索：grep, grep -r, grep -E
// - 文本处理：sed, awk 入门
// - 排序去重统计：sort, uniq, wc
// - 文本比较：diff
// === 文本编辑与处理

在 Linux 的世界里，文本无处不在。配置文件是文本，源代码是文本，日志是文本，脚本是文本。掌握文本编辑和处理的技能，就掌握了 Linux 系统管理和开发的核心能力。本节将介绍两种命令行文本编辑器——适合新手的 nano 和功能强大的 vim，以及一系列文本处理工具——grep 搜索、sed 替换、awk 分析、sort 排序等。这些工具组合起来，可以完成几乎任何文本处理任务。

==== nano：新手友好的编辑器

如果你刚接触 Linux，需要在命令行中编辑文件，nano 是最友好的选择。它简单直观，屏幕底部显示常用快捷键，不需要记忆复杂的命令。

启动 nano 编辑文件：

```bash
$ nano filename.txt
```

如果文件不存在，nano 会创建一个新文件。打开后，你会看到一个简洁的界面：文件内容在中央，底部是快捷键提示。`^` 符号表示 Ctrl 键，所以 `^X` 表示 `Ctrl+X`。

在 nano 中，你可以直接开始输入文本，就像在普通的文本编辑器中一样。方向键移动光标，Backspace 删除字符，一切都很直观。

最常用的快捷键包括：

- `Ctrl+O`：保存文件（Write Out）。按下后会提示确认文件名，按 Enter 确认。
- `Ctrl+X`：退出 nano。如果文件有未保存的修改，会提示是否保存。
- `Ctrl+K`：剪切当前行。
- `Ctrl+U`：粘贴剪切的内容。
- `Ctrl+W`：搜索文本。输入要搜索的内容，按 Enter 跳转到第一个匹配处。`Ctrl+W` 再次按下可继续搜索下一个。
- `Ctrl+\`：搜索并替换。
- `Ctrl+G`：显示帮助信息。

一个典型的编辑流程是：打开文件，进行修改，`Ctrl+O` 保存，`Ctrl+X` 退出。如果修改后想放弃更改，直接 `Ctrl+X`，在提示保存时选择 `N`。

nano 的优点是上手零门槛，缺点是功能相对简单，对于大量编辑工作效率不高。它非常适合快速编辑配置文件、修改几行代码这样的小任务。当你 SSH 到服务器上需要改个配置时，nano 是最省心的选择。

```bash
# 编辑 SSH 配置
$ sudo nano /etc/ssh/sshd_config

# 编辑 bashrc
$ nano ~/.bashrc

# 快速创建并编辑新文件
$ nano notes.txt
```

==== vim：高效但需要学习的编辑器

vim（Vi IMproved）是 Linux 世界最著名的编辑器，以其强大的功能和陡峭的学习曲线闻名。几乎每个 Linux 系统都预装了 vim 或其前身 vi，所以掌握基本操作是很有价值的。而一旦熟练，vim 的编辑效率是其他编辑器难以企及的。

vim 与其他编辑器最大的不同是它的"模式"设计。vim 有多种模式，每种模式下按键的含义不同：

- *普通模式（Normal mode）*：默认模式，用于导航和执行命令。按键是命令而不是输入字符。
- *插入模式（Insert mode）*：用于输入文本，此时 vim 表现得像普通编辑器。
- *命令模式（Command mode）*：用于执行保存、退出等命令，以 `:` 开始。
- *可视模式（Visual mode）*：用于选择文本。

启动 vim：

```bash
$ vim filename.txt
```

打开文件后，你处于普通模式。此时按字母键不会输入字符，而是执行命令。这是新手最困惑的地方——"我怎么什么都输入不了？"

要输入文本，需要先进入插入模式。最常用的方式是按 `i`（在光标前插入）。进入插入模式后，左下角会显示 `-- INSERT --`，此时可以正常输入文本。编辑完成后，按 `Esc` 返回普通模式。

保存和退出需要进入命令模式。在普通模式下按 `:`，左下角会出现冒号等待输入命令：

- `:w`：保存（write）
- `:q`：退出（quit）
- `:wq` 或 `:x`：保存并退出
- `:q!`：不保存强制退出（放弃所有修改）
- `:wq!`：强制保存并退出（用于只读文件，需要权限）

一个最基本的 vim 使用流程：

```
vim file.txt    → 打开文件，处于普通模式
i               → 进入插入模式
(输入文本)
Esc             → 返回普通模式
:wq             → 保存并退出
```

这几个操作足以应付基本的编辑需求。但 vim 的威力在于普通模式下的丰富命令。

普通模式下的移动命令：

- `h`、`j`、`k`、`l`：左、下、上、右（可以用方向键代替，但原生玩家用这四个键）
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

vim 的学习曲线确实陡峭，但它的设计哲学——通过组合简单命令完成复杂操作——一旦掌握会非常高效。比如 `d2w` 表示"删除 2 个单词"，`y$` 表示"复制到行尾"，`ci"` 表示"修改引号内的内容"。这种命令组合的方式让 vim 用户可以在不离开键盘主区的情况下快速编辑。

对于 RoboMaster 开发者，建议至少掌握 vim 的基本操作。当你 SSH 到机器人的计算机上、或者在没有图形界面的环境中工作时，vim 可能是唯一的选择。即使你主要使用 VS Code 或其他 IDE，了解 vim 也是有价值的——很多工具（如 Git）默认使用 vim 编辑提交信息。

如果你想深入学习 vim，可以运行 `vimtutor` 命令，它提供了一个交互式的教程：

```bash
$ vimtutor
```

==== grep：文本搜索利器

`grep`（Global Regular Expression Print）是最常用的文本搜索工具。它在文件中搜索匹配特定模式的行，并将这些行输出。

基本用法：

```bash
# 在文件中搜索字符串
$ grep "error" logfile.txt
[所有包含 error 的行]

# 在多个文件中搜索
$ grep "TODO" *.cpp
main.cpp:42:    // TODO: implement this
detector.cpp:100:    // TODO: optimize performance

# -i 忽略大小写
$ grep -i "error" logfile.txt
Error: connection failed
ERROR: timeout
error: invalid input

# -n 显示行号
$ grep -n "error" logfile.txt
42:error: connection failed
157:error: timeout
```

递归搜索是开发中最常用的功能。`-r` 选项让 grep 搜索目录下的所有文件：

```bash
# 在当前目录及子目录中搜索
$ grep -r "ArmorDetector" .
./src/detector.cpp:class ArmorDetector {
./include/detector.hpp:class ArmorDetector;
./test/test_detector.cpp:TEST(ArmorDetector, Basic) {

# -r 配合其他选项
$ grep -rn "ArmorDetector" src/
src/detector.cpp:15:class ArmorDetector {
src/main.cpp:42:    ArmorDetector detector;

# --include 只搜索特定类型的文件
$ grep -rn "TODO" --include="*.cpp" --include="*.hpp" .

# --exclude 排除特定文件
$ grep -rn "password" --exclude="*.log" .

# --exclude-dir 排除目录
$ grep -rn "config" --exclude-dir=build --exclude-dir=.git .
```

上下文显示让你能看到匹配行的周围内容：

```bash
# -B 显示匹配行之前的 n 行（Before）
$ grep -B 2 "error" logfile.txt

# -A 显示匹配行之后的 n 行（After）
$ grep -A 3 "error" logfile.txt

# -C 显示前后各 n 行（Context）
$ grep -C 2 "error" logfile.txt
```

反向匹配显示不包含模式的行：

```bash
# -v 反向匹配
$ grep -v "debug" logfile.txt      # 显示不含 debug 的行

# 排除注释行
$ grep -v "^#" config.txt          # ^ 表示行首
$ grep -v "^//" code.cpp
```

grep 支持正则表达式，`-E` 选项启用扩展正则表达式（或使用 `egrep`）：

```bash
# 基本正则表达式
$ grep "error.*failed" logfile.txt   # . 匹配任意字符，* 匹配零个或多个

# -E 扩展正则表达式
$ grep -E "error|warning|fatal" logfile.txt  # | 表示或
$ grep -E "[0-9]{3}\.[0-9]{3}" data.txt      # 匹配 xxx.xxx 格式的数字

# 常用正则模式
$ grep "^#" config.txt       # 以 # 开头的行
$ grep "\.cpp$" filelist     # 以 .cpp 结尾的行
$ grep "^$" file.txt         # 空行
$ grep -v "^$" file.txt      # 非空行
```

grep 经常与其他命令通过管道组合使用：

```bash
# 在命令输出中搜索
$ ps aux | grep python
alice    12345  0.5  1.2 123456 78900 ?  S  10:00  0:30 python3 app.py

# 在历史命令中搜索
$ history | grep "git push"

# 统计匹配的行数
$ grep -c "error" logfile.txt
42

# 只显示匹配的文件名
$ grep -l "main" *.cpp
main.cpp
app.cpp

# 实时监控日志中的错误
$ tail -f app.log | grep --line-buffered "error"
```

`--line-buffered` 在管道中使用 grep 时很重要，它让 grep 逐行输出而不是等待缓冲区满。

==== sed：流式文本编辑

`sed`（Stream Editor）是一个强大的文本转换工具。它逐行读取输入，应用指定的编辑命令，然后输出结果。sed 最常用的功能是文本替换。

基本替换语法：

```bash
# 替换每行第一个匹配
$ sed 's/old/new/' file.txt
# s = substitute 替换命令
# old = 要查找的模式
# new = 替换成的内容

# 替换所有匹配（g = global）
$ sed 's/old/new/g' file.txt

# 替换并忽略大小写（i = case insensitive）
$ sed 's/error/ERROR/gi' file.txt
```

sed 默认将结果输出到标准输出，原文件不变。要直接修改文件，使用 `-i` 选项：

```bash
# 直接修改文件（危险，建议先备份）
$ sed -i 's/old/new/g' file.txt

# 创建备份后修改
$ sed -i.bak 's/old/new/g' file.txt
# 原文件被修改，备份保存为 file.txt.bak
```

sed 使用正则表达式，可以进行复杂的模式匹配：

```bash
# 删除行首空白
$ sed 's/^[ \t]*//' file.txt

# 删除行尾空白
$ sed 's/[ \t]*$//' file.txt

# 删除空行
$ sed '/^$/d' file.txt
# d = delete 删除命令

# 删除包含特定模式的行
$ sed '/pattern/d' file.txt

# 删除注释行
$ sed '/^#/d' config.txt
$ sed '/^\/\//d' code.cpp
```

限定替换范围：

```bash
# 只替换第 3 行
$ sed '3s/old/new/' file.txt

# 替换第 3 到第 5 行
$ sed '3,5s/old/new/g' file.txt

# 替换第 10 行到最后一行
$ sed '10,$s/old/new/g' file.txt

# 替换匹配某模式的行
$ sed '/error/s/old/new/g' file.txt
```

sed 的实际应用场景：

```bash
# 批量修改代码中的函数名
$ sed -i 's/oldFunction/newFunction/g' *.cpp

# 修改配置文件中的参数
$ sed -i 's/port=8080/port=9090/' config.ini

# 给每行添加前缀
$ sed 's/^/PREFIX: /' file.txt

# 给每行添加后缀
$ sed 's/$/ SUFFIX/' file.txt

# 在第 10 行后插入新行
$ sed '10a\This is a new line' file.txt
# a = append 追加

# 在第 10 行前插入新行
$ sed '10i\This is a new line' file.txt
# i = insert 插入

# 替换配置文件中的值（处理特殊字符）
$ sed -i "s|/old/path|/new/path|g" config.txt
# 使用 | 作为分隔符，避免与路径中的 / 冲突
```

sed 脚本可以包含多个命令：

```bash
# 多个命令用 -e 分隔
$ sed -e 's/foo/bar/g' -e 's/baz/qux/g' file.txt

# 或用分号分隔
$ sed 's/foo/bar/g; s/baz/qux/g' file.txt

# 从文件读取 sed 命令
$ sed -f script.sed file.txt
```

==== awk：强大的文本分析工具

`awk` 是一个完整的文本处理语言，特别擅长处理结构化的文本数据（如 CSV、日志文件）。它逐行读取输入，将每行分割成字段，然后对字段进行处理。

awk 的基本语法是 `awk 'pattern { action }' file`。如果某行匹配 pattern，就执行 action。

```bash
# 打印每行（相当于 cat）
$ awk '{ print }' file.txt

# 打印第一个字段（默认以空白分隔）
$ awk '{ print $1 }' file.txt

# 打印第一和第三个字段
$ awk '{ print $1, $3 }' file.txt

# $0 表示整行，$1, $2, ... 表示各个字段，$NF 表示最后一个字段
$ awk '{ print $NF }' file.txt      # 打印最后一个字段
$ awk '{ print $(NF-1) }' file.txt  # 打印倒数第二个字段
```

处理 CSV 或其他分隔符的文件：

```bash
# -F 指定字段分隔符
$ awk -F',' '{ print $1, $3 }' data.csv

# 冒号分隔（如 /etc/passwd）
$ awk -F':' '{ print $1, $7 }' /etc/passwd
# 输出用户名和 shell

# 多字符分隔符
$ awk -F'::' '{ print $1 }' file.txt
```

条件过滤：

```bash
# 只打印匹配模式的行
$ awk '/error/ { print }' logfile.txt

# 条件判断
$ awk '$3 > 100 { print $1, $3 }' data.txt  # 第三字段大于 100 的行

# 组合条件
$ awk '$3 > 100 && $2 == "active" { print }' data.txt

# 打印行号
$ awk '{ print NR, $0 }' file.txt  # NR = Number of Records（行号）
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
$ awk '{ printf "%-10s %5d\n", $1, $2 }' data.txt

# 添加表头
$ awk 'BEGIN { print "Name\tScore" } { print $1 "\t" $2 }' data.txt
# BEGIN 在处理任何行之前执行

# 添加表尾/汇总
$ awk '{ sum += $2 } END { print "Total:", sum }' data.txt
# END 在处理完所有行之后执行
```

实际应用示例：

```bash
# 统计日志中各类错误的数量
$ awk '/error/ { count[$4]++ } END { for (type in count) print type, count[type] }' app.log

# 计算文件中数字的平均值
$ awk '{ sum += $1; count++ } END { print sum/count }' numbers.txt

# 提取 CSV 特定列并计算
$ awk -F',' '{ sum += $3 } END { print "Average:", sum/NR }' data.csv

# 过滤并格式化 ps 输出
$ ps aux | awk '$3 > 1.0 { printf "%-10s %5.1f%%\n", $11, $3 }'
# 显示 CPU 使用率超过 1% 的进程

# 分析 ROS 2 日志
$ awk '/\[ERROR\]/ { print $1, $2, $0 }' ros2.log
```

awk 是一个完整的编程语言，支持变量、数组、循环、条件、函数等。对于复杂的文本分析任务，awk 比管道组合 grep、sed、cut 更加高效和清晰。

==== 排序、去重与统计

`sort` 对文本行进行排序：

```bash
# 默认按字母顺序排序
$ sort names.txt

# -n 按数字排序
$ sort -n numbers.txt

# -r 反向排序
$ sort -r names.txt
$ sort -rn numbers.txt  # 数字降序

# -k 按指定字段排序
$ sort -k 2 data.txt      # 按第二字段排序
$ sort -k 2 -n data.txt   # 按第二字段数字排序
$ sort -k 2,2 -k 1,1 data.txt  # 先按第二字段，相同则按第一字段

# -t 指定字段分隔符
$ sort -t',' -k 3 -n data.csv  # CSV 按第三列数字排序

# -u 排序并去重
$ sort -u names.txt

# 查找最大的几个文件
$ du -sh * | sort -rh | head -5
```

`uniq` 去除相邻的重复行（通常与 sort 配合使用）：

```bash
# 去重（必须先排序）
$ sort names.txt | uniq

# -c 统计每行出现的次数
$ sort names.txt | uniq -c
      3 Alice
      1 Bob
      2 Charlie

# -d 只显示重复的行
$ sort names.txt | uniq -d

# -u 只显示不重复的行
$ sort names.txt | uniq -u

# 统计最常出现的项
$ sort items.txt | uniq -c | sort -rn | head -10
```

`wc`（word count）统计行数、单词数、字符数：

```bash
# 默认显示行数、单词数、字节数
$ wc file.txt
  100   500  3000 file.txt

# -l 只显示行数
$ wc -l file.txt
100 file.txt

# -w 只显示单词数
$ wc -w file.txt

# -c 只显示字节数
$ wc -c file.txt

# -m 显示字符数（处理多字节字符）
$ wc -m file.txt

# 统计多个文件
$ wc -l *.cpp
  100 main.cpp
  200 detector.cpp
  150 tracker.cpp
  450 total

# 统计目录中的文件数
$ ls | wc -l

# 统计代码行数
$ find . -name "*.cpp" -exec cat {} + | wc -l
```

组合使用这些工具可以完成复杂的分析任务：

```bash
# 统计日志中各 IP 的访问次数
$ awk '{ print $1 }' access.log | sort | uniq -c | sort -rn | head -10

# 找出代码中使用最多的函数
$ grep -oh '\b[a-zA-Z_][a-zA-Z0-9_]*(' *.cpp | sort | uniq -c | sort -rn | head -20

# 统计各类型文件的数量
$ find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn
```

==== diff：文件比较

`diff` 比较两个文件的差异，这对于代码审查、配置比较、版本对比非常有用。

```bash
# 基本比较
$ diff file1.txt file2.txt
2c2
< old line
---
> new line
5a6
> added line
```

输出格式说明：`<` 表示第一个文件的内容，`>` 表示第二个文件的内容。`2c2` 表示第 2 行有变化（change），`5a6` 表示在第 5 行后添加了内容（add），`3d2` 表示第 3 行被删除（delete）。

更友好的输出格式：

```bash
# -u 统一格式（unified diff），更易读，也是 Git 使用的格式
$ diff -u file1.txt file2.txt
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
$ diff -y file1.txt file2.txt
line 1                line 1
old line            | new line
line 3                line 3

# --color 彩色显示（需要较新版本）
$ diff --color -u file1.txt file2.txt
```

比较目录：

```bash
# -r 递归比较目录
$ diff -r dir1/ dir2/

# -q 只显示哪些文件不同，不显示具体差异
$ diff -rq dir1/ dir2/
Files dir1/file.txt and dir2/file.txt differ
Only in dir1/: extra.txt
```

忽略某些差异：

```bash
# -w 忽略所有空白差异
$ diff -w file1.txt file2.txt

# -b 忽略空白数量变化
$ diff -b file1.txt file2.txt

# -B 忽略空行差异
$ diff -B file1.txt file2.txt

# -i 忽略大小写
$ diff -i file1.txt file2.txt
```

实际应用：

```bash
# 比较配置文件的变化
$ diff -u config.old config.new > changes.patch

# 应用补丁
$ patch < changes.patch

# 比较两个版本的代码
$ diff -ru old_version/ new_version/ > upgrade.patch

# 在代码审查中查看修改
$ git diff HEAD~1  # Git 使用 diff 格式显示变更
```

`colordiff` 是 `diff` 的彩色版本，更易于阅读：

```bash
$ sudo apt install colordiff
$ colordiff -u file1.txt file2.txt
```

文本编辑与处理是 Linux 命令行的核心能力。这些工具——从简单的 cat、grep 到强大的 sed、awk——构成了一个完整的文本处理工具箱。它们遵循 Unix 哲学：每个工具做好一件事，通过管道组合完成复杂任务。掌握这些工具，你就能高效地处理日志分析、配置修改、代码搜索、数据提取等各种文本相关的任务。在 RoboMaster 开发中，这些技能会在调试日志、分析数据、批量修改代码等场景中反复用到。


=== 用户与权限管理
// 多用户系统的安全基础
// - 用户与用户组
// - root 与 sudo
// - 文件权限：rwx 与数字表示（755, 644）
// - ls -l 输出解读
// - chmod, chown
// - 为什么脚本需要 chmod +x
// === 用户与权限管理

Linux 从诞生之初就是一个多用户操作系统。多个用户可以同时登录同一台机器，每个用户有自己的文件和进程，彼此隔离。这种设计来自 Unix 的时分系统传统——一台昂贵的计算机需要被多人共享使用。虽然今天的个人电脑通常只有一个使用者，但多用户模型仍然是 Linux 安全架构的基础。理解用户和权限的概念，不仅是系统管理的必备知识，也是理解为什么某些操作需要 `sudo`、为什么脚本需要 `chmod +x` 的关键。

==== 用户与用户组

在 Linux 中，每个用户都有一个唯一的用户名和用户 ID（UID）。用户信息存储在 `/etc/passwd` 文件中：

```bash
$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
...
alice:x:1000:1000:Alice:/home/alice:/bin/bash
bob:x:1001:1001:Bob:/home/bob:/bin/bash
```

每行代表一个用户，字段用冒号分隔：用户名、密码占位符（实际密码在 `/etc/shadow`）、UID、GID（主组 ID）、用户描述、家目录、登录 Shell。

UID 0 是特殊的，它属于 root 用户——系统的超级管理员，拥有无限制的权限。普通用户的 UID 通常从 1000 开始。系统服务使用的用户（如 `daemon`、`www-data`）通常有较小的 UID，且登录 Shell 设为 `/usr/sbin/nologin`，表示这些账户不能交互式登录。

用户组是用户的集合，用于简化权限管理。每个用户属于一个主组（primary group），还可以属于多个附加组（supplementary groups）。组信息存储在 `/etc/group` 中：

```bash
$ cat /etc/group
root:x:0:
sudo:x:27:alice
audio:x:29:alice,bob
video:x:44:alice,bob
alice:x:1000:
bob:x:1001:
```

用户组让权限管理更加灵活。比如，你可以创建一个 `robomaster` 组，把所有队员加入这个组，然后设置项目目录对这个组可读写。这样所有队员都能访问项目文件，而其他用户不能。

查看当前用户和组信息：

```bash
# 查看当前用户
$ whoami
alice

# 查看当前用户的 UID 和所属组
$ id
uid=1000(alice) gid=1000(alice) groups=1000(alice),27(sudo),29(audio),44(video)

# 查看其他用户的信息
$ id bob
uid=1001(bob) gid=1001(bob) groups=1001(bob),29(audio),44(video)

# 查看当前用户所属的所有组
$ groups
alice sudo audio video
```

用户和组的管理命令（需要 root 权限）：

```bash
# 创建新用户
$ sudo useradd -m -s /bin/bash newuser
# -m 创建家目录
# -s 指定登录 Shell

# 设置密码
$ sudo passwd newuser

# 更友好的创建用户命令（交互式）
$ sudo adduser newuser

# 删除用户
$ sudo userdel -r olduser
# -r 同时删除家目录

# 创建组
$ sudo groupadd robomaster

# 将用户添加到组
$ sudo usermod -aG robomaster alice
# -a 追加（不覆盖现有组）
# -G 指定附加组

# 从组中移除用户
$ sudo gpasswd -d alice robomaster
```

修改用户组后，需要重新登录才能生效。这是因为组信息在登录时读取，会话期间不会自动更新。

==== root 与 sudo

root 是 Linux 系统的超级用户，UID 为 0，拥有对系统的完全控制权。root 可以读写任何文件、终止任何进程、修改任何配置。这种无限制的权力是危险的——一个误操作就可能破坏整个系统。因此，现代 Linux 实践是：日常工作使用普通用户，只在需要时临时获取 root 权限。

`sudo`（superuser do）允许普通用户以 root 身份执行单个命令。使用 sudo 时需要输入当前用户的密码（不是 root 密码），验证是你本人在操作：

```bash
# 以 root 身份执行命令
$ sudo apt update

# 第一次使用会提示输入密码
[sudo] password for alice: 
...

# 短时间内再次使用不需要重新输入密码（默认 15 分钟）
$ sudo apt upgrade
```

sudo 的优势在于审计和控制。系统会记录谁在什么时候用 sudo 执行了什么命令（日志在 `/var/log/auth.log`），这对于安全审计很重要。管理员还可以精细控制哪些用户可以用 sudo 执行哪些命令，配置文件是 `/etc/sudoers`（用 `visudo` 编辑，它会检查语法错误）。

并非所有用户都能使用 sudo。在 Ubuntu 中，用户必须属于 `sudo` 组才能使用 sudo。安装系统时创建的第一个用户会自动加入这个组。

```bash
# 检查用户是否在 sudo 组
$ groups alice
alice sudo audio video

# 将用户加入 sudo 组（需要已有 sudo 权限的用户执行）
$ sudo usermod -aG sudo newuser
```

有时你需要以 root 身份执行多个命令，每次都输入 sudo 很繁琐。可以启动一个 root shell：

```bash
# 启动 root shell
$ sudo -i
root@hostname:~# 
# 提示符从 $ 变成 #，表示现在是 root

# 完成后退出
root@hostname:~# exit
$

# 或者用 sudo -s 保持当前环境
$ sudo -s
```

但要谨慎使用 root shell——在 root 权限下，`rm -rf /` 这样的命令会真的删除整个系统，没有任何阻拦。一个好习惯是只在必要时使用 sudo，完成后立即退出 root shell。

另一个常见场景是以 root 身份编辑文件：

```bash
# 编辑系统配置文件
$ sudo nano /etc/ssh/sshd_config

# 或者
$ sudo vim /etc/hosts
```

有些用户会犯一个错误：用 sudo 运行图形程序或在家目录创建文件。这会导致文件的所有者变成 root，之后普通用户无法修改：

```bash
# 错误做法
$ sudo vim ~/my_script.sh
# 现在 my_script.sh 的所有者是 root

# 正确做法：只在必要时用 sudo
$ vim ~/my_script.sh
```

==== 文件权限：rwx 模型

Linux 的文件权限模型简单而有效。每个文件有三组权限，分别针对：所有者（owner）、所属组（group）、其他人（others）。每组权限包含三种：读（read）、写（write）、执行（execute）。

用 `ls -l` 查看文件权限：

```bash
$ ls -l
-rw-r--r-- 1 alice alice  1234 Jan 15 10:00 document.txt
-rwxr-xr-x 1 alice alice  5678 Jan 15 10:00 script.sh
drwxr-xr-x 2 alice alice  4096 Jan 15 10:00 mydir
lrwxrwxrwx 1 alice alice    10 Jan 15 10:00 link -> target
```

第一列就是权限字符串，让我们详细解读 `-rwxr-xr-x`：

- 第 1 个字符：文件类型。`-` 普通文件，`d` 目录，`l` 符号链接，`c` 字符设备，`b` 块设备。
- 第 2-4 个字符（`rwx`）：所有者权限。这里是 `rwx`，表示所有者可以读、写、执行。
- 第 5-7 个字符（`r-x`）：所属组权限。这里是 `r-x`，表示组成员可以读、执行，但不能写。
- 第 8-10 个字符（`r-x`）：其他人权限。这里也是 `r-x`，表示其他人可以读、执行，但不能写。

权限字符的含义：

- `r`（read，值为 4）：
  - 对于文件：可以读取内容
  - 对于目录：可以列出目录内容（ls）
- `w`（write，值为 2）：
  - 对于文件：可以修改内容
  - 对于目录：可以在目录中创建、删除、重命名文件
- `x`（execute，值为 1）：
  - 对于文件：可以作为程序执行
  - 对于目录：可以进入目录（cd）
- `-`：没有该权限

目录权限的理解需要特别注意。要访问目录中的文件，你需要对目录有 `x` 权限（进入目录）。要列出目录内容，需要 `r` 权限。要在目录中创建或删除文件，需要 `w` 权限。一个常见的困惑是：即使你对某个文件有完全权限，如果对其所在目录没有 `x` 权限，你也无法访问该文件。

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

常见的权限设置：

- *755*：所有者完全控制，其他人可读可执行。用于可执行程序、脚本、公开目录。
- *644*：所有者可读写，其他人只读。用于普通文件、配置文件。
- *700*：只有所有者可访问。用于私密目录，如 `~/.ssh`。
- *600*：只有所有者可读写。用于私密文件，如 SSH 私钥。
- *777*：所有人完全控制。通常不推荐，安全隐患。
- *666*：所有人可读写。同样不推荐。

理解这些数字对于设置权限和理解文档很重要。当你看到"将权限设为 755"或"chmod 644"时，就知道这意味着什么。

==== chmod：修改权限

`chmod`（change mode）命令用于修改文件权限。它有两种语法：符号模式和数字模式。

数字模式直接指定完整的权限：

```bash
# 设置权限为 755（rwxr-xr-x）
$ chmod 755 script.sh

# 设置权限为 644（rw-r--r--）
$ chmod 644 document.txt

# 设置目录权限为 700（只有所有者可访问）
$ chmod 700 private_dir

# 递归修改目录及其内容
$ chmod -R 755 public_dir
```

符号模式更灵活，可以增加或删除特定权限：

```bash
# 语法：chmod [ugoa][+-=][rwx] file
# u=user(所有者), g=group(组), o=others(其他), a=all(所有)
# +=添加, -=删除, ==设置

# 给所有者添加执行权限
$ chmod u+x script.sh

# 给所有人添加读权限
$ chmod a+r document.txt

# 删除其他人的写权限
$ chmod o-w file.txt

# 给组添加读写权限
$ chmod g+rw shared_file.txt

# 组合操作
$ chmod u+x,g+r,o-w file.txt

# 设置精确权限（覆盖现有）
$ chmod u=rwx,g=rx,o=rx script.sh  # 等同于 755
```

符号模式的优势是可以只修改需要改变的部分，而不影响其他权限。比如 `chmod u+x` 只添加所有者的执行权限，不会改变其他权限位。

==== chown：修改所有者

`chown`（change owner）命令修改文件的所有者和所属组。这个命令通常需要 root 权限。

```bash
# 修改所有者
$ sudo chown bob file.txt

# 修改所有者和组
$ sudo chown bob:developers file.txt

# 只修改组（注意冒号在前）
$ sudo chown :developers file.txt
# 或者用 chgrp
$ sudo chgrp developers file.txt

# 递归修改目录及其内容
$ sudo chown -R alice:robomaster project/
```

一个常见场景是修复被 sudo 创建的文件：

```bash
# 误用 sudo 创建了文件
$ sudo touch important.txt
$ ls -l important.txt
-rw-r--r-- 1 root root 0 Jan 15 10:00 important.txt

# 现在普通用户无法修改
$ echo "content" >> important.txt
bash: important.txt: Permission denied

# 修复所有权
$ sudo chown alice:alice important.txt
$ echo "content" >> important.txt  # 现在可以了
```

==== 为什么脚本需要 chmod +x

当你写了一个 Shell 脚本，尝试运行时可能会遇到这样的错误：

```bash
$ ./my_script.sh
bash: ./my_script.sh: Permission denied
```

这是因为新创建的文件默认没有执行权限：

```bash
$ ls -l my_script.sh
-rw-r--r-- 1 alice alice 100 Jan 15 10:00 my_script.sh
```

注意权限是 `rw-r--r--`（644），没有 `x`。文件虽然内容是可执行的脚本，但操作系统不允许执行它。这是一个安全特性——防止你不小心把数据文件当作程序运行。

解决方法就是添加执行权限：

```bash
$ chmod +x my_script.sh
$ ls -l my_script.sh
-rwxr-xr-x 1 alice alice 100 Jan 15 10:00 my_script.sh

$ ./my_script.sh
Hello, World!
```

`chmod +x` 是 `chmod a+x` 的简写，给所有用户添加执行权限。如果你只想让自己能执行，可以用 `chmod u+x`。

有一个绕过方法是显式调用解释器：

```bash
$ bash my_script.sh    # 不需要执行权限
$ python3 script.py    # 同样不需要
```

这种方式不需要文件有执行权限，因为实际执行的是 `bash` 或 `python3`，脚本只是作为输入文件。但这不是推荐的做法——添加执行权限是正确的方式，也让文件的用途更明确。

对于编译型程序（如 C++ 编译出的二进制文件），编译器通常会自动设置执行权限：

```bash
$ g++ main.cpp -o program
$ ls -l program
-rwxr-xr-x 1 alice alice 12345 Jan 15 10:00 program

$ ./program  # 直接可以运行
```

==== 特殊权限位

除了基本的 rwx 权限，还有三个特殊权限位：SUID、SGID 和 Sticky Bit。它们在某些场景下很有用，但也带来安全风险，需要谨慎使用。

*SUID（Set User ID）*：当可执行文件设置了 SUID 位，任何用户执行该文件时，进程会以文件所有者的身份运行，而不是执行者的身份。最典型的例子是 `passwd` 命令：

```bash
$ ls -l /usr/bin/passwd
-rwsr-xr-x 1 root root 68208 Jan 15 10:00 /usr/bin/passwd
```

注意所有者权限中的 `s`（而不是 `x`）。普通用户运行 `passwd` 时，进程以 root 身份运行，因此能够修改 `/etc/shadow` 文件（存储密码的地方）。没有 SUID，普通用户无法修改自己的密码。

设置 SUID：

```bash
$ chmod u+s program
$ chmod 4755 program  # 4 表示 SUID
```

*SGID（Set Group ID）*：类似 SUID，但是以文件所属组的身份运行。对于目录，SGID 有特殊含义：在该目录下创建的新文件会继承目录的组，而不是创建者的主组。这对于团队共享目录很有用：

```bash
# 创建共享目录
$ sudo mkdir /shared/project
$ sudo chown :robomaster /shared/project
$ sudo chmod g+s /shared/project

# 现在在这个目录下创建的文件都属于 robomaster 组
$ touch /shared/project/newfile.txt
$ ls -l /shared/project/newfile.txt
-rw-r--r-- 1 alice robomaster 0 Jan 15 10:00 newfile.txt
```

*Sticky Bit*：对于目录，设置 Sticky Bit 后，只有文件所有者、目录所有者或 root 才能删除或重命名目录中的文件，即使其他用户对目录有写权限。`/tmp` 目录就设置了 Sticky Bit：

```bash
$ ls -ld /tmp
drwxrwxrwt 10 root root 4096 Jan 15 10:00 /tmp
```

注意其他人权限中的 `t`（而不是 `x`）。所有用户都可以在 `/tmp` 中创建文件，但只能删除自己的文件，不能删除别人的。

```bash
# 设置 Sticky Bit
$ chmod +t directory
$ chmod 1777 directory  # 1 表示 Sticky Bit
```

==== umask：默认权限

当你创建新文件或目录时，系统会使用一个默认权限。这个默认值由 `umask` 控制。umask 指定了要从完整权限中"屏蔽"掉的位。

```bash
$ umask
0022

# 对于文件，完整权限是 666（不包括执行位）
# 666 - 022 = 644 (rw-r--r--)

# 对于目录，完整权限是 777
# 777 - 022 = 755 (rwxr-xr-x)
```

常见的 umask 值：

- *022*：文件 644，目录 755。这是大多数系统的默认值，其他用户可读。
- *077*：文件 600，目录 700。更私密，其他用户无法访问。
- *002*：文件 664，目录 775。同组用户可写，适合团队协作。

修改 umask：

```bash
# 临时修改
$ umask 077

# 永久修改（添加到 ~/.bashrc）
$ echo "umask 077" >> ~/.bashrc
```

==== 实际场景中的权限管理

让我们看一些 RoboMaster 开发中常见的权限相关场景。

*访问串口设备*：USB 串口设备（如 `/dev/ttyUSB0`）默认只有 root 和 dialout 组可以访问：

```bash
$ ls -l /dev/ttyUSB0
crw-rw---- 1 root dialout 188, 0 Jan 15 10:00 /dev/ttyUSB0

# 普通用户无法访问
$ cat /dev/ttyUSB0
cat: /dev/ttyUSB0: Permission denied

# 解决方法：将用户加入 dialout 组
$ sudo usermod -aG dialout alice
# 重新登录后生效

$ groups
alice dialout ...
$ cat /dev/ttyUSB0  # 现在可以了
```

*共享项目目录*：团队成员需要共同编辑项目文件：

```bash
# 创建项目目录
$ sudo mkdir -p /home/shared/rm_vision
$ sudo chown :robomaster /home/shared/rm_vision
$ sudo chmod 2775 /home/shared/rm_vision  # SGID + rwxrwxr-x

# 确保团队成员都在 robomaster 组
$ sudo usermod -aG robomaster alice
$ sudo usermod -aG robomaster bob
```

*保护 SSH 密钥*：SSH 对私钥权限有严格要求：

```bash
$ chmod 700 ~/.ssh
$ chmod 600 ~/.ssh/id_rsa
$ chmod 644 ~/.ssh/id_rsa.pub
$ chmod 644 ~/.ssh/known_hosts
$ chmod 600 ~/.ssh/config

# 如果权限不对，SSH 会拒绝使用密钥
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/home/alice/.ssh/id_rsa' are too open.
```

*脚本和程序*：

```bash
# 创建脚本后添加执行权限
$ vim run_vision.sh
$ chmod +x run_vision.sh
$ ./run_vision.sh

# 安装自己的程序到 ~/.local/bin
$ cp my_tool ~/.local/bin/
$ chmod 755 ~/.local/bin/my_tool
```

用户与权限管理是 Linux 安全的基础。理解这些概念后，你就能明白为什么某些操作需要 sudo，为什么某些文件无法访问，以及如何正确设置权限让团队协作更顺畅。记住一个原则：给予最小必要的权限。不要随便 `chmod 777`，不要长期在 root shell 中工作，谨慎使用 SUID。这些习惯会让你的系统更加安全。


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

在 Windows 上安装软件，你需要找到官网、下载安装程序、运行安装向导、处理各种"下一步"和捆绑软件的选项。在 Linux 上，这一切被包管理器彻底改变了。一条命令就能安装软件，依赖自动解决，更新一键完成，卸载干净彻底。包管理器是 Linux 发行版的核心组件之一，理解它的工作原理和使用方法，是高效使用 Linux 的关键。本节以 Ubuntu 使用的 APT 包管理器为主，介绍软件的安装、更新、卸载，以及如何添加软件源和从源码编译安装。

==== 包管理器的概念

软件包（package）是将程序文件、库、配置、文档等打包在一起的归档文件。在 Debian/Ubuntu 系统上，软件包的格式是 `.deb`。包管理器负责安装、升级、卸载这些软件包，并自动处理包之间的依赖关系。

依赖是指一个软件需要其他软件才能运行。比如，一个图形程序可能依赖 Qt 库，一个 Python 程序依赖 Python 解释器。在没有包管理器的年代，安装软件需要手动下载并安装所有依赖，依赖又可能有自己的依赖，形成"依赖地狱"。包管理器自动分析依赖关系，一次性安装所有需要的包，大大简化了软件安装。

软件源（repository）是存放软件包的服务器。Ubuntu 官方维护了庞大的软件源，包含数万个软件包。当你运行 `apt install` 时，包管理器会从软件源下载并安装软件。软件源的配置决定了你能安装哪些软件，以及获取软件的速度（选择地理位置近的镜像可以加快下载）。

==== APT 基础操作

APT（Advanced Package Tool）是 Ubuntu 和其他 Debian 系发行版的高级包管理工具。它提供了友好的命令行界面，是日常软件管理的主要工具。

*更新软件包列表*

在安装或升级软件之前，应该先更新本地的软件包列表。这个列表记录了软件源中有哪些软件、什么版本：

```bash
$ sudo apt update
Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
Get:2 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [119 kB]
...
Reading package lists... Done
Building dependency tree... Done
42 packages can be upgraded. Run 'apt list --upgradable' to see them.
```

`apt update` 只是更新列表，不会安装或升级任何软件。它告诉你有多少包可以升级。

*升级已安装的软件*

更新列表后，可以升级所有已安装的软件到最新版本：

```bash
$ sudo apt upgrade
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

如果某些升级需要删除或安装新包（比如内核升级），`apt upgrade` 会跳过它们。要进行更激进的升级，使用 `apt full-upgrade`：

```bash
$ sudo apt full-upgrade
```

这是完整的系统更新命令，通常在重大版本升级时使用。

*安装软件*

安装软件是最常用的操作：

```bash
# 安装单个软件
$ sudo apt install vim

# 安装多个软件
$ sudo apt install git cmake build-essential

# 安装时不询问确认（脚本中常用）
$ sudo apt install -y package_name

# 重新安装已安装的软件
$ sudo apt reinstall package_name
```

`build-essential` 是一个元包（metapackage），它本身不包含软件，但依赖一组编译工具（gcc、g++、make 等）。安装它会自动安装所有这些工具，是 C/C++ 开发的必备。

*卸载软件*

卸载软件有两种方式：

```bash
# 卸载软件，保留配置文件
$ sudo apt remove package_name

# 完全卸载，包括配置文件
$ sudo apt purge package_name

# 卸载后清理不再需要的依赖
$ sudo apt autoremove
```

`remove` 和 `purge` 的区别在于是否删除配置文件。如果你打算将来重新安装并保留配置，用 `remove`；如果想彻底清除，用 `purge`。

`autoremove` 清理那些作为依赖被安装、但现在不再被任何已安装软件需要的包。定期运行它可以释放磁盘空间。

*搜索软件*

不确定软件包的确切名称？用 `apt search`：

```bash
$ apt search opencv
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
$ apt search opencv | grep -i "dev"
```

*查看软件包信息*

安装前想了解软件包的详细信息：

```bash
$ apt show libopencv-dev
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
$ apt list --installed

# 过滤特定软件
$ apt list --installed | grep opencv

# 列出可升级的软件
$ apt list --upgradable
```

*清理缓存*

APT 会缓存下载的 `.deb` 文件在 `/var/cache/apt/archives/`。时间长了可能占用大量空间：

```bash
# 查看缓存大小
$ du -sh /var/cache/apt/archives/
500M    /var/cache/apt/archives/

# 清理缓存（删除已安装软件的旧版本包）
$ sudo apt autoclean

# 清理所有缓存
$ sudo apt clean
```

==== dpkg：底层工具

`dpkg` 是 Debian 系统的底层包管理工具，APT 实际上是 dpkg 的前端。APT 处理依赖关系和从网络下载，dpkg 负责实际的包安装和管理。日常使用中你主要使用 APT，但有时需要直接用 dpkg。

*安装本地 .deb 文件*

有时你从网站下载了 `.deb` 文件，需要手动安装：

```bash
# 下载 deb 文件
$ wget https://example.com/software.deb

# 用 dpkg 安装
$ sudo dpkg -i software.deb

# 如果有依赖问题，用 apt 修复
$ sudo apt install -f
```

`apt install -f`（fix broken）会安装缺失的依赖。也可以直接用 APT 安装本地 deb 文件，它会自动处理依赖：

```bash
$ sudo apt install ./software.deb
```

注意路径前的 `./`，它告诉 APT 这是一个本地文件而不是软件源中的包名。

*查询已安装的包*

```bash
# 查看包是否安装
$ dpkg -l | grep package_name

# 查看包安装了哪些文件
$ dpkg -L package_name
/usr/bin/program
/usr/lib/libsomething.so
/usr/share/doc/package_name/README
...

# 查看某个文件属于哪个包
$ dpkg -S /usr/bin/vim
vim: /usr/bin/vim
```

这在排查问题时很有用——比如某个命令不工作，你可以查看它属于哪个包，然后重新安装。

*手动管理包*

```bash
# 卸载包
$ sudo dpkg -r package_name

# 完全卸载（包括配置）
$ sudo dpkg -P package_name

# 列出所有已安装的包
$ dpkg --get-selections
```

==== 软件源与 PPA

Ubuntu 官方软件源包含了大量软件，但有时你需要的软件不在官方源中，或者官方源的版本太旧。这时可以添加第三方软件源。

*软件源配置*

软件源配置在 `/etc/apt/sources.list` 和 `/etc/apt/sources.list.d/` 目录下：

```bash
$ cat /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
```

每行定义一个软件源：`deb` 表示二进制包源，URL 是服务器地址，后面是发行版代号和组件。组件的含义：

- `main`：Ubuntu 官方支持的自由软件
- `restricted`：官方支持的非自由软件（如显卡驱动）
- `universe`：社区维护的自由软件
- `multiverse`：非自由软件

*更换镜像源*

官方源服务器在国外，下载速度可能较慢。可以更换为国内镜像：

```bash
# 备份原配置
$ sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 编辑配置文件
$ sudo nano /etc/apt/sources.list
# 将 archive.ubuntu.com 替换为镜像地址，如：
# mirrors.aliyun.com
# mirrors.tuna.tsinghua.edu.cn
# mirrors.ustc.edu.cn

# 更新软件列表
$ sudo apt update
```

许多 Linux 发行版在安装时会提供镜像选择，或者有图形化的软件源设置工具。

*PPA：个人软件包存档*

PPA（Personal Package Archive）是 Ubuntu 的第三方软件源机制，允许开发者发布自己的软件包。很多最新版本的软件通过 PPA 提供。

```bash
# 添加 PPA
$ sudo add-apt-repository ppa:user/ppa-name
$ sudo apt update

# 例如，添加最新的 Git
$ sudo add-apt-repository ppa:git-core/ppa
$ sudo apt update
$ sudo apt install git

# 移除 PPA
$ sudo add-apt-repository --remove ppa:user/ppa-name
```

添加 PPA 时要谨慎——PPA 由第三方维护，软件质量和安全性没有官方保证。只添加你信任的 PPA。

*手动添加软件源*

有些软件（如 ROS 2、Docker）提供自己的软件源。添加过程通常包括：

```bash
# 1. 添加 GPG 密钥（验证软件包的签名）
$ curl -fsSL https://example.com/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/example.gpg

# 2. 添加软件源
$ echo "deb [signed-by=/usr/share/keyrings/example.gpg] https://example.com/apt stable main" | sudo tee /etc/apt/sources.list.d/example.list

# 3. 更新并安装
$ sudo apt update
$ sudo apt install software
```

这个过程看起来复杂，但软件的官方文档通常会提供完整的命令，复制粘贴即可。

==== 从源码编译安装

有时候，软件源中没有你需要的软件，或者你需要特定版本、特定编译选项。这时需要从源码编译安装。

*典型的编译安装流程*

大多数 C/C++ 项目遵循类似的编译流程：

```bash
# 1. 下载源码
$ wget https://example.com/software-1.0.tar.gz
$ tar xzf software-1.0.tar.gz
$ cd software-1.0

# 2. 安装编译依赖
$ sudo apt install build-essential cmake  # 基本工具
$ sudo apt install libxxx-dev             # 项目特定的依赖

# 3. 配置
$ mkdir build && cd build
$ cmake ..
# 或者对于使用 autotools 的项目
$ ./configure

# 4. 编译
$ make -j$(nproc)  # 使用所有 CPU 核心并行编译

# 5. 安装（到系统目录）
$ sudo make install

# 或者安装到自定义位置
$ cmake -DCMAKE_INSTALL_PREFIX=/opt/software ..
$ make -j$(nproc)
$ sudo make install
```

*安装编译依赖*

编译软件通常需要开发版本的库（带 `-dev` 后缀）：

```bash
# 例如，编译使用 OpenCV 的程序
$ sudo apt install libopencv-dev

# 编译使用 Eigen 的程序
$ sudo apt install libeigen3-dev

# 编译使用 Qt 的程序
$ sudo apt install qtbase5-dev
```

开发包包含头文件和静态链接所需的文件，运行时包只包含动态库。编译时需要开发包，运行时只需要运行时包。

*管理源码安装的软件*

从源码安装的软件不受包管理器管理，有几个问题：

- 卸载麻烦：需要到源码目录运行 `sudo make uninstall`（如果支持的话）
- 升级麻烦：需要重新下载、编译、安装
- 可能与系统软件冲突

一些建议：

```bash
# 安装到 /opt 或 /usr/local，与系统软件分开
$ cmake -DCMAKE_INSTALL_PREFIX=/opt/software-1.0 ..

# 或者使用 checkinstall 创建 deb 包
$ sudo apt install checkinstall
$ sudo checkinstall  # 代替 sudo make install
# 这会创建一个 deb 包并安装，之后可以用 dpkg 卸载
```

*编译 OpenCV（示例）*

OpenCV 是 RoboMaster 开发中最重要的库之一。虽然可以从软件源安装，但从源码编译可以启用更多功能（如 CUDA 加速）：

```bash
# 安装依赖
$ sudo apt install build-essential cmake git
$ sudo apt install libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev
$ sudo apt install libtbb-dev libjpeg-dev libpng-dev libtiff-dev
$ sudo apt install libv4l-dev libxvidcore-dev libx264-dev

# 下载源码
$ git clone https://github.com/opencv/opencv.git
$ git clone https://github.com/opencv/opencv_contrib.git
$ cd opencv
$ git checkout 4.8.0  # 切换到特定版本
$ cd ../opencv_contrib
$ git checkout 4.8.0

# 配置
$ cd ../opencv
$ mkdir build && cd build
$ cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
        -DWITH_TBB=ON \
        -DWITH_V4L=ON \
        -DWITH_OPENGL=ON \
        -DBUILD_EXAMPLES=OFF \
        ..

# 编译（可能需要较长时间）
$ make -j$(nproc)

# 安装
$ sudo make install
$ sudo ldconfig  # 更新库缓存
```

==== RoboMaster 常用软件安装

以下是 RoboMaster 开发中常用软件的安装方法：

*基础开发工具*

```bash
# 编译工具
$ sudo apt install build-essential cmake cmake-curses-gui ninja-build

# 版本控制
$ sudo apt install git git-lfs

# 编辑器和 IDE
$ sudo apt install vim
# VS Code 需要从官网下载或添加微软的软件源

# 调试工具
$ sudo apt install gdb valgrind

# 文档工具
$ sudo apt install doxygen graphviz
```

*核心库*

```bash
# OpenCV（从软件源安装）
$ sudo apt install libopencv-dev python3-opencv

# Eigen
$ sudo apt install libeigen3-dev

# fmt 和 spdlog
$ sudo apt install libfmt-dev libspdlog-dev

# yaml-cpp（配置文件解析）
$ sudo apt install libyaml-cpp-dev

# Ceres Solver（非线性优化）
$ sudo apt install libceres-dev

# Google Test
$ sudo apt install libgtest-dev
```

*ROS 2 安装*

ROS 2 的安装需要添加官方软件源：

```bash
# 设置 locale
$ sudo apt update && sudo apt install locales
$ sudo locale-gen en_US en_US.UTF-8
$ sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
$ export LANG=en_US.UTF-8

# 添加 ROS 2 软件源
$ sudo apt install software-properties-common
$ sudo add-apt-repository universe

$ sudo apt update && sudo apt install curl -y
$ sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 安装 ROS 2
$ sudo apt update
$ sudo apt install ros-humble-desktop  # 完整桌面版
# 或
$ sudo apt install ros-humble-ros-base  # 基础版（无 GUI 工具）

# 安装开发工具
$ sudo apt install ros-dev-tools

# 设置环境（添加到 ~/.bashrc）
$ echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
$ source ~/.bashrc
```

*常用 ROS 2 包*

```bash
# 图像相关
$ sudo apt install ros-humble-cv-bridge ros-humble-image-transport
$ sudo apt install ros-humble-camera-info-manager

# TF2
$ sudo apt install ros-humble-tf2 ros-humble-tf2-ros ros-humble-tf2-geometry-msgs

# 可视化
$ sudo apt install ros-humble-rviz2 ros-humble-rqt*

# 仿真
$ sudo apt install ros-humble-gazebo-ros-pkgs
```

*串口和硬件相关*

```bash
# 串口通信库
$ sudo apt install libserial-dev

# USB 设备权限
$ sudo usermod -aG dialout $USER  # 需要重新登录

# V4L2 相机工具
$ sudo apt install v4l-utils
$ v4l2-ctl --list-devices  # 列出摄像头
```

*NVIDIA 相关（如果有 NVIDIA GPU）*

```bash
# NVIDIA 驱动（推荐使用 Ubuntu 的驱动管理器）
$ sudo ubuntu-drivers autoinstall
# 或手动安装特定版本
$ sudo apt install nvidia-driver-535

# CUDA（从 NVIDIA 官网下载或使用软件源）
# 详见 NVIDIA 官方文档

# cuDNN
# 需要从 NVIDIA 开发者网站下载
```

==== 常见问题解决

*依赖问题*

```bash
# 依赖不满足
$ sudo apt install -f

# 包冲突
$ sudo apt --fix-broken install

# 强制修复损坏的包
$ sudo dpkg --configure -a
```

*锁文件问题*

如果看到"无法获取锁"的错误，说明另一个程序正在使用包管理器：

```bash
E: Could not get lock /var/lib/dpkg/lock-frontend

# 等待其他程序完成，或者如果确定没有其他程序在运行
$ sudo rm /var/lib/dpkg/lock-frontend
$ sudo rm /var/lib/dpkg/lock
$ sudo dpkg --configure -a
```

*包被保留*

```bash
# 查看被保留的包
$ apt-mark showhold

# 取消保留
$ sudo apt-mark unhold package_name
```

*清理系统*

```bash
# 删除不需要的依赖
$ sudo apt autoremove

# 清理下载缓存
$ sudo apt clean

# 删除旧内核（保留当前和上一个）
$ sudo apt autoremove --purge
```

软件包管理是 Linux 系统维护的核心技能。APT 让软件安装变得简单可靠，理解其工作原理可以帮助你解决各种问题。记住定期运行 `apt update && apt upgrade` 保持系统更新，这不仅能获得新功能，更重要的是获得安全补丁。对于 RoboMaster 开发，掌握软件包管理让你能够快速搭建开发环境，这是项目顺利进行的基础。


=== 进程与系统监控
// 管理运行中的程序
// - ps, top, htop
// - kill, killall, pkill
// - 前台后台：&, jobs, fg, bg
// - 系统资源：free, df, du
// - 系统服务：systemctl
// === 进程与系统监控

当你运行一个程序时，操作系统会创建一个进程来执行它。进程是程序的运行实例，拥有自己的内存空间、文件描述符和系统资源。Linux 是一个多任务操作系统，可以同时运行成百上千个进程。作为开发者，你需要了解如何查看系统中正在运行的进程、监控资源使用情况、终止行为异常的程序、管理后台任务。这些技能在调试程序、排查性能问题、管理机器人系统时都会用到。

==== 查看进程：ps

`ps`（process status）命令显示系统中的进程信息。它有许多选项，最常用的是 `aux` 组合：

```bash
$ ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1 169584 13256 ?        Ss   Jan15   0:03 /sbin/init
root         2  0.0  0.0      0     0 ?        S    Jan15   0:00 [kthreadd]
...
alice    12345  2.5  1.2 456789 98765 pts/0    Sl+  10:00   0:30 ./detector_node
alice    12400  0.0  0.0  12345  1234 pts/1    R+   10:30   0:00 ps aux
```

输出的各列含义：

- `USER`：进程所属用户
- `PID`：进程 ID，每个进程的唯一标识符
- `%CPU`：CPU 使用率
- `%MEM`：内存使用率
- `VSZ`：虚拟内存大小（KB）
- `RSS`：实际使用的物理内存（KB）
- `TTY`：关联的终端（`?` 表示没有关联终端，通常是后台服务）
- `STAT`：进程状态
- `START`：启动时间
- `TIME`：累计 CPU 时间
- `COMMAND`：启动命令

进程状态（STAT）的常见值：

- `R`：运行中（Running）
- `S`：睡眠（Sleeping），等待某个事件
- `D`：不可中断睡眠，通常在等待 I/O
- `T`：停止（Stopped）
- `Z`：僵尸进程（Zombie），已终止但父进程未回收
- `+`：前台进程组
- `l`：多线程
- `s`：会话领导者

`ps` 的输出是瞬时快照，显示命令执行那一刻的状态。常用的 `ps` 命令变体：

```bash
# 显示所有进程的详细信息
$ ps aux

# 显示进程树，展示父子关系
$ ps auxf
# 或
$ pstree

# 只显示特定用户的进程
$ ps -u alice

# 显示特定进程
$ ps -p 12345

# 显示特定命令的进程
$ ps aux | grep detector
alice    12345  2.5  1.2 456789 98765 pts/0    Sl+  10:00   0:30 ./detector_node
alice    12500  0.0  0.0  12345  1234 pts/1    S+   10:31   0:00 grep detector
```

注意 grep 自己也会出现在结果中。可以用 `grep -v grep` 排除它，或者使用更优雅的技巧 `grep [d]etector`（方括号让 grep 本身的命令行不匹配这个模式）。

`pgrep` 是专门用于查找进程的工具，比 `ps | grep` 更方便：

```bash
# 查找名称包含 detector 的进程
$ pgrep -a detector
12345 ./detector_node

# 只输出 PID
$ pgrep detector
12345

# 查找特定用户的进程
$ pgrep -u alice python
```

==== 实时监控：top 和 htop

`ps` 显示的是静态快照，而 `top` 提供实时更新的进程视图。它是系统监控的标准工具，每隔几秒刷新一次：

```bash
$ top
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

- *load average*：系统负载，三个数字分别是过去 1、5、15 分钟的平均值。在单核系统上，1.0 表示 CPU 满负载；在 4 核系统上，4.0 表示满负载。
- *Tasks*：进程统计——总数、运行中、睡眠、停止、僵尸
- *%Cpu(s)*：CPU 使用分解——us（用户空间）、sy（内核空间）、id（空闲）、wa（等待 I/O）等
- *Mem/Swap*：内存和交换空间使用情况

在 top 运行时，可以用按键交互：

- `q`：退出
- `h`：显示帮助
- `k`：杀死进程（输入 PID）
- `r`：调整进程优先级（renice）
- `M`：按内存使用排序
- `P`：按 CPU 使用排序
- `1`：显示每个 CPU 核心的使用情况
- `c`：显示完整命令行
- `f`：选择显示哪些列

`htop` 是 `top` 的增强版，提供彩色显示、鼠标支持、更直观的界面。它不是系统自带的，需要安装：

```bash
$ sudo apt install htop
$ htop
```

htop 的界面更加友好：顶部用彩色条形图显示每个 CPU 核心的使用率和内存使用情况，进程列表支持鼠标点击和滚动。底部显示常用操作的快捷键。

htop 的常用操作：

- `F1`：帮助
- `F2`：设置
- `F3`：搜索进程
- `F4`：过滤进程
- `F5`：树状视图
- `F6`：选择排序列
- `F9`：杀死进程
- `F10`：退出
- `Space`：标记进程（可以同时操作多个）
- `u`：只显示特定用户的进程
- `t`：切换树状/列表视图

对于 RoboMaster 开发，htop 是排查性能问题的利器。当机器人系统响应变慢时，打开 htop 可以立即看到哪个进程占用了大量 CPU 或内存。

==== 终止进程：kill、killall、pkill

当进程行为异常（如死循环、无响应）时，需要终止它。Linux 使用信号（signal）机制来控制进程。

`kill` 命令向指定 PID 的进程发送信号：

```bash
# 发送 SIGTERM（15），请求进程优雅终止
$ kill 12345

# 发送 SIGKILL（9），强制终止
$ kill -9 12345
# 或
$ kill -KILL 12345

# 发送 SIGHUP（1），通常用于重新加载配置
$ kill -HUP 12345
```

常用的信号：

- `SIGTERM`（15）：终止信号，默认信号。进程可以捕获这个信号并进行清理后退出。
- `SIGKILL`（9）：强制杀死信号，进程无法捕获或忽略，立即终止。
- `SIGINT`（2）：中断信号，相当于 Ctrl+C。
- `SIGSTOP`（19）：暂停进程，相当于 Ctrl+Z。
- `SIGCONT`（18）：继续运行暂停的进程。
- `SIGHUP`（1）：挂起信号，常用于通知守护进程重新加载配置。

一般流程是先尝试 SIGTERM，给进程机会进行清理（关闭文件、释放资源）。如果进程不响应，再使用 SIGKILL 强制终止：

```bash
# 先温和地请求终止
$ kill 12345

# 等待几秒，如果进程还在
$ ps -p 12345
# 如果还在，强制杀死
$ kill -9 12345
```

`killall` 根据进程名称终止所有匹配的进程：

```bash
# 终止所有名为 detector_node 的进程
$ killall detector_node

# 强制终止
$ killall -9 detector_node

# 交互式确认
$ killall -i detector_node
Kill detector_node(12345)? (y/N)
```

`pkill` 更灵活，支持模式匹配：

```bash
# 终止名称包含 detector 的进程
$ pkill detector

# 终止特定用户的进程
$ pkill -u alice python

# 只终止最新启动的匹配进程
$ pkill -n detector

# 只终止最老的匹配进程
$ pkill -o detector
```

在 RoboMaster 开发中，经常需要终止 ROS 2 节点。可以使用 ROS 2 自己的命令，也可以用系统命令：

```bash
# ROS 2 方式
$ ros2 node list
/detector_node
/tracker_node

# 系统方式
$ pkill -f "ros2 run"  # 终止所有 ros2 run 启动的进程
$ pkill detector_node
```

`-f` 选项让 pkill 匹配完整的命令行，而不仅仅是进程名。

==== 前台与后台

在终端中运行程序时，程序默认在前台运行，占据终端，你需要等它完成才能输入其他命令。但你可以让程序在后台运行，这样终端可以继续使用。

在命令末尾加 `&` 让程序在后台启动：

```bash
$ ./long_running_program &
[1] 12345
$  # 立即返回提示符，可以继续工作
```

`[1]` 是作业号，`12345` 是进程 ID。程序在后台运行，但它的输出仍然会显示在终端上（可能会打断你的输入）。

`jobs` 命令列出当前 Shell 的后台作业：

```bash
$ jobs
[1]+  Running                 ./long_running_program &
[2]-  Stopped                 vim file.txt
```

`+` 表示当前作业（最近操作的），`-` 表示上一个作业。

`fg`（foreground）把后台作业带回前台：

```bash
$ fg %1      # 把作业 1 带到前台
$ fg         # 把当前作业（+）带到前台
```

`bg`（background）让暂停的作业在后台继续运行：

```bash
# 运行一个程序
$ ./program
# 按 Ctrl+Z 暂停
^Z
[1]+  Stopped                 ./program

# 让它在后台继续运行
$ bg %1
[1]+ ./program &
```

这个技巧很有用：如果你运行了一个程序后发现它需要很长时间，不想开新终端，可以 Ctrl+Z 暂停，然后 bg 让它在后台继续。

后台进程仍然与终端关联。如果你关闭终端，后台进程也会收到 SIGHUP 信号并终止。要让进程在终端关闭后继续运行，使用 `nohup`：

```bash
$ nohup ./long_running_program &
nohup: ignoring input and appending output to 'nohup.out'
[1] 12345
```

`nohup` 让进程忽略 SIGHUP 信号，输出被重定向到 `nohup.out` 文件。

另一个选择是使用 `disown` 将已经在后台运行的作业与 Shell 解除关联：

```bash
$ ./program &
[1] 12345
$ disown %1
# 现在关闭终端也不会影响这个进程
```

对于需要长期运行的服务，更好的方式是使用 systemd 管理（后面会介绍），或者使用 `screen`/`tmux` 终端复用器。

==== 系统资源监控

*内存：free*

`free` 命令显示系统内存使用情况：

```bash
$ free -h
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

Linux 会积极使用空闲内存作为缓存来加速磁盘访问，所以 `free` 值很低不一定表示内存紧张。关键是 `available` 值——只要它还有足够的余量，系统就不会有内存压力。

Swap 是磁盘上的交换空间，当物理内存不足时使用。如果 Swap 使用量很高，说明系统内存紧张，性能可能会下降。

*磁盘空间：df*

`df`（disk free）显示文件系统的磁盘空间使用情况：

```bash
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   45G   50G  48% /
/dev/sda2       500G  200G  275G  43% /home
tmpfs           7.8G     0  7.8G   0% /dev/shm
/dev/sdb1       1.0T  500G  500G  50% /data
```

输出显示每个挂载的文件系统的大小、已用空间、可用空间和挂载点。

```bash
# 只显示本地文件系统，排除虚拟文件系统
$ df -h --local

# 显示特定目录所在的文件系统
$ df -h /home/alice/projects
```

*目录大小：du*

`du`（disk usage）显示目录或文件占用的磁盘空间：

```bash
# 显示当前目录的总大小
$ du -sh .
2.5G    .

# 显示各子目录的大小
$ du -sh */
500M    build/
1.5G    models/
200M    src/
300M    data/

# 显示所有文件和目录
$ du -ah

# 限制深度
$ du -h --max-depth=1

# 找出最大的目录/文件
$ du -sh * | sort -rh | head -10
```

当磁盘空间不足时，先用 `df` 确定哪个分区满了，再用 `du` 找出占用空间最多的目录：

```bash
$ df -h
# 发现 /home 分区快满了

$ cd /home
$ sudo du -sh */ | sort -rh | head
50G     alice/
20G     bob/
...

$ cd alice
$ du -sh */ | sort -rh | head
30G     .cache/
10G     projects/
...
```

*综合监控工具*

除了单独的命令，还有一些综合监控工具：

```bash
# vmstat：虚拟内存统计
$ vmstat 1      # 每秒刷新一次
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0      0 6000000 200000 4000000  0    0     5    10  200  500  5  2 92  1  0

# iostat：I/O 统计
$ iostat -xh 1
Device      r/s     w/s     rkB/s   wkB/s  %util
sda        10.00   20.00   500.0k   1.0M   5.00

# iotop：实时 I/O 监控（需要安装）
$ sudo apt install iotop
$ sudo iotop

# nethogs：网络流量监控（按进程）
$ sudo apt install nethogs
$ sudo nethogs
```

==== 系统服务：systemd 和 systemctl

现代 Linux 发行版使用 systemd 作为初始化系统和服务管理器。系统启动时，systemd 是第一个运行的进程（PID 1），负责启动和管理所有其他服务。

`systemctl` 是与 systemd 交互的命令。服务在 systemd 中被称为"单元"（unit），服务单元的后缀是 `.service`。

*查看服务状态*

```bash
# 查看服务状态
$ systemctl status ssh
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

状态输出包含丰富的信息：服务是否启动、是否设置为开机自启、主进程 PID、资源使用、最近的日志等。

*启动、停止、重启服务*

```bash
# 启动服务
$ sudo systemctl start ssh

# 停止服务
$ sudo systemctl stop ssh

# 重启服务
$ sudo systemctl restart ssh

# 重新加载配置（不中断服务）
$ sudo systemctl reload ssh

# 如果不确定是否支持 reload
$ sudo systemctl reload-or-restart ssh
```

*设置开机自启*

```bash
# 设置开机自启
$ sudo systemctl enable ssh

# 取消开机自启
$ sudo systemctl disable ssh

# 同时启动并设置开机自启
$ sudo systemctl enable --now ssh
```

*查看所有服务*

```bash
# 列出所有服务
$ systemctl list-units --type=service

# 列出所有服务（包括未运行的）
$ systemctl list-units --type=service --all

# 列出启用的服务
$ systemctl list-unit-files --type=service --state=enabled

# 列出失败的服务
$ systemctl --failed
```

*查看服务日志*

systemd 有自己的日志系统 journald，用 `journalctl` 查看：

```bash
# 查看特定服务的日志
$ journalctl -u ssh

# 查看最近的日志
$ journalctl -u ssh -n 50

# 实时追踪日志
$ journalctl -u ssh -f

# 查看本次启动以来的日志
$ journalctl -u ssh -b

# 查看特定时间范围的日志
$ journalctl -u ssh --since "2024-01-15 10:00:00" --until "2024-01-15 12:00:00"
```

*创建自己的服务*

你可以创建自己的 systemd 服务来管理 RoboMaster 程序。服务文件放在 `/etc/systemd/system/` 目录下：

```bash
$ sudo nano /etc/systemd/system/rm-vision.service
```

服务文件内容：

```ini
[Unit]
Description=RoboMaster Vision System
After=network.target

[Service]
Type=simple
User=alice
WorkingDirectory=/home/alice/ros2_ws
ExecStart=/bin/bash -c 'source /opt/ros/humble/setup.bash && source install/setup.bash && ros2 launch rm_vision vision_launch.py'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

配置说明：

- `[Unit]` 部分描述服务和依赖关系
- `After=network.target` 表示在网络服务启动后再启动
- `[Service]` 部分定义如何运行服务
- `Type=simple` 表示 ExecStart 启动的进程就是主进程
- `User` 指定运行服务的用户
- `Restart=on-failure` 表示失败时自动重启
- `[Install]` 部分定义如何启用服务

启用并启动服务：

```bash
# 重新加载 systemd 配置
$ sudo systemctl daemon-reload

# 启动服务
$ sudo systemctl start rm-vision

# 查看状态
$ sudo systemctl status rm-vision

# 设置开机自启
$ sudo systemctl enable rm-vision
```

这样，你的视觉系统就会在机器人开机时自动启动，崩溃后自动重启，非常适合比赛环境。

*常用系统服务*

一些 RoboMaster 开发中可能遇到的系统服务：

```bash
# SSH 服务
$ sudo systemctl status ssh

# 网络管理
$ sudo systemctl status NetworkManager

# 时间同步
$ sudo systemctl status systemd-timesyncd

# Docker（如果安装了）
$ sudo systemctl status docker

# 查看所有 ROS 相关服务（如果有）
$ systemctl list-units | grep ros
```

==== 实际应用场景

让我们看一些 RoboMaster 开发中的实际场景。

*排查程序占用过多资源*

```bash
# 发现系统变慢，打开 htop 查看
$ htop
# 发现 detector_node 占用 100% CPU

# 查看进程详情
$ ps aux | grep detector
alice    12345 99.0  5.0 456789 400000 pts/0 R+ 10:00 30:00 ./detector_node

# 可能是死循环，查看进程在做什么
$ strace -p 12345
# 或者用 gdb attach
$ gdb -p 12345

# 如果需要终止
$ kill 12345
```

*监控 ROS 2 节点资源使用*

```bash
# 查看所有 ROS 2 相关进程
$ ps aux | grep ros2
$ ps aux | grep -E "detector|tracker|aim"

# 实时监控
$ htop -p $(pgrep -d',' detector_node)
```

*处理僵尸进程*

```bash
# 查找僵尸进程
$ ps aux | grep Z
alice    12345  0.0  0.0      0     0 pts/0    Z    10:00   0:00 [defunct]

# 找到父进程
$ ps -o ppid= -p 12345
12300

# 通常需要终止父进程来清理僵尸进程
$ kill 12300
```

*释放磁盘空间*

```bash
# 检查磁盘使用
$ df -h
# /home 快满了

# 找大文件
$ du -sh ~/* | sort -rh | head
30G     /home/alice/ros2_ws
20G     /home/alice/.cache

# 清理 ROS 2 构建产物
$ cd ~/ros2_ws
$ rm -rf build/ install/ log/

# 清理系统缓存
$ sudo apt clean
$ sudo apt autoremove

# 清理用户缓存
$ rm -rf ~/.cache/pip
```

进程管理和系统监控是 Linux 系统管理的基础技能。掌握这些工具，你就能了解系统的运行状态，及时发现和解决问题。在 RoboMaster 开发中，这些技能会在调试性能问题、管理机器人服务、排查系统故障时反复用到。特别是 systemd 的使用，可以让你的机器人系统在开机时自动启动、异常时自动恢复，大大提高了系统的可靠性。


=== 网络与远程访问
// 连接与远程操作
// - 网络信息：ip addr, ping
// - 下载：wget, curl
// - SSH 远程连接与密钥认证
// - 文件传输：scp, rsync
// - 为什么机器人开发离不开 SSH
// === 网络与远程访问

机器人不会永远摆在你的桌面上，连着键盘和显示器等你操作。在实际的 RoboMaster 开发中，机器人上的计算机（如 Jetson 或工控机）通常没有直接连接的外设，你需要通过网络远程访问它。SSH（Secure Shell）是实现这一目标的核心工具——它让你能够从自己的笔记本连接到机器人的计算机，执行命令、编辑文件、运行程序，就像直接坐在那台机器前一样。本节将介绍网络基础知识、SSH 的使用方法、文件传输技巧，以及为什么掌握这些技能对机器人开发至关重要。

==== 查看网络信息

在连接网络之前，首先要了解本机的网络配置。`ip` 命令是现代 Linux 系统查看和配置网络的标准工具。

查看网络接口和 IP 地址：

```bash
$ ip addr
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

输出中显示了三个网络接口：`lo` 是本地回环接口（localhost），`enp0s3` 是有线网卡，`wlp2s0` 是无线网卡。每个接口显示了 MAC 地址（`link/ether`）和 IP 地址（`inet`）。

常用的 `ip` 命令变体：

```bash
# 简洁显示 IP 地址
$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 
enp0s3           UP             192.168.1.100/24 
wlp2s0           UP             192.168.1.101/24 

# 显示路由表
$ ip route
default via 192.168.1.1 dev enp0s3 proto dhcp metric 100 
192.168.1.0/24 dev enp0s3 proto kernel scope link src 192.168.1.100 

# 显示网络接口的链路状态
$ ip link
```

老式的 `ifconfig` 命令在某些系统上仍然可用，但已被 `ip` 取代。如果你看到用 `ifconfig` 的教程，知道它做类似的事情即可。

`ping` 命令测试网络连通性，通过发送 ICMP 数据包来检查目标主机是否可达：

```bash
$ ping 192.168.1.1
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=1.23 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=64 time=0.98 ms
64 bytes from 192.168.1.1: icmp_seq=3 ttl=64 time=1.05 ms
^C
--- 192.168.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.980/1.086/1.230/0.104 ms
```

Linux 的 `ping` 会持续运行直到你按 Ctrl+C 停止（与 Windows 不同，Windows 默认只发 4 个包）。输出显示了每个数据包的往返时间（RTT）和丢包率。

```bash
# 只发送指定数量的包
$ ping -c 4 192.168.1.1

# ping 域名
$ ping -c 4 google.com

# 指定间隔时间（秒）
$ ping -i 0.5 192.168.1.1
```

当网络连接出问题时，ping 是最基本的诊断工具：

```bash
# 检查本地网络栈
$ ping 127.0.0.1

# 检查网关（路由器）
$ ping 192.168.1.1

# 检查外部网络
$ ping 8.8.8.8

# 检查 DNS 解析
$ ping google.com
```

如果 ping 网关失败，问题可能在本地网络配置或物理连接；如果 ping 网关成功但外部失败，问题可能在路由器或上游网络；如果 IP 能 ping 通但域名不行，问题在 DNS。

其他有用的网络诊断工具：

```bash
# 追踪到目标的路由路径
$ traceroute google.com

# 显示网络连接和监听端口
$ ss -tuln
# -t TCP, -u UDP, -l 监听, -n 数字显示

# 查看 DNS 解析
$ nslookup google.com
$ dig google.com

# 查看主机名
$ hostname
$ hostname -I  # 显示所有 IP 地址
```

==== 下载文件：wget 和 curl

从网络下载文件是常见的任务，Linux 提供了两个强大的命令行工具。

`wget` 专注于下载文件，简单直接：

```bash
# 下载文件
$ wget https://example.com/file.tar.gz

# 下载并指定保存的文件名
$ wget -O myfile.tar.gz https://example.com/file.tar.gz

# 断点续传（下载中断后继续）
$ wget -c https://example.com/large_file.zip

# 后台下载
$ wget -b https://example.com/large_file.zip
# 日志保存在 wget-log

# 限速下载（避免占满带宽）
$ wget --limit-rate=1M https://example.com/file.zip

# 下载整个网站（镜像）
$ wget -r -np -k https://example.com/docs/
```

`curl` 功能更丰富，支持更多协议，常用于 API 调用和脚本：

```bash
# 下载文件（默认输出到标准输出）
$ curl https://example.com/file.txt

# 保存到文件
$ curl -o file.txt https://example.com/file.txt
$ curl -O https://example.com/file.txt  # 使用远程文件名

# 跟随重定向
$ curl -L https://example.com/redirect

# 显示响应头
$ curl -I https://example.com

# POST 请求
$ curl -X POST -d "data=value" https://api.example.com/endpoint

# 发送 JSON 数据
$ curl -X POST -H "Content-Type: application/json" \
       -d '{"key": "value"}' https://api.example.com/endpoint

# 带认证
$ curl -u username:password https://example.com/protected
```

在 RoboMaster 开发中，这些工具常用于：

```bash
# 下载预训练模型
$ wget https://github.com/xxx/releases/download/v1.0/model.onnx

# 下载 ROS 2 安装脚本
$ curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg

# 从 GitHub 下载源码
$ wget https://github.com/opencv/opencv/archive/4.8.0.tar.gz
```

==== SSH：远程连接的核心

SSH（Secure Shell）是远程登录和管理 Linux 系统的标准工具。它提供加密的通信通道，让你能够安全地在网络上执行命令。

*基本连接*

```bash
# 连接到远程主机
$ ssh username@hostname
$ ssh alice@192.168.1.50

# 使用非默认端口
$ ssh -p 2222 alice@192.168.1.50

# 首次连接会提示确认主机指纹
The authenticity of host '192.168.1.50 (192.168.1.50)' can't be established.
ED25519 key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

首次连接时，SSH 会显示远程主机的指纹并询问是否信任。确认后，主机的公钥会保存在 `~/.ssh/known_hosts` 中，之后连接不再询问。如果远程主机的密钥发生变化（可能是重装系统，也可能是中间人攻击），SSH 会警告并拒绝连接。

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
$ ssh alice@192.168.1.50 "ls -la"

# 远程执行多个命令
$ ssh alice@192.168.1.50 "cd ros2_ws && colcon build"

# 查看远程系统状态
$ ssh alice@192.168.1.50 "free -h && df -h"
```

*SSH 密钥认证*

每次连接都输入密码很麻烦，而且密码可能被暴力破解。SSH 密钥认证更安全也更方便——使用一对密钥（公钥和私钥）代替密码。

生成密钥对：

```bash
$ ssh-keygen -t ed25519 -C "your_email@example.com"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/alice/.ssh/id_ed25519): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/alice/.ssh/id_ed25519
Your public key has been saved in /home/alice/.ssh/id_ed25519.pub
```

这会在 `~/.ssh/` 目录生成两个文件：`id_ed25519`（私钥，必须保密）和 `id_ed25519.pub`（公钥，可以分享）。passphrase 是可选的额外保护——即使私钥被盗，没有 passphrase 也无法使用。

将公钥复制到远程主机：

```bash
$ ssh-copy-id alice@192.168.1.50
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s)
...
Number of key(s) added: 1
```

这会把你的公钥添加到远程主机的 `~/.ssh/authorized_keys` 文件。之后连接就不需要密码了：

```bash
$ ssh alice@192.168.1.50
# 直接进入，无需密码
alice@robot:~$
```

如果没有 `ssh-copy-id`，可以手动复制：

```bash
# 查看公钥
$ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxx... your_email@example.com

# 在远程主机上
$ mkdir -p ~/.ssh
$ chmod 700 ~/.ssh
$ echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxx..." >> ~/.ssh/authorized_keys
$ chmod 600 ~/.ssh/authorized_keys
```

权限设置很重要——SSH 会拒绝使用权限过于开放的密钥文件。

*SSH 配置文件*

频繁连接多台机器时，每次输入完整的用户名和地址很繁琐。可以在 `~/.ssh/config` 中配置别名：

```bash
$ nano ~/.ssh/config
```

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
$ ssh robot    # 相当于 ssh alice@192.168.1.50
$ ssh jetson   # 相当于 ssh nvidia@192.168.1.60 -i ~/.ssh/jetson_key
```

`ServerAliveInterval` 让 SSH 定期发送心跳包，防止连接因空闲超时被断开。

*SSH 端口转发*

SSH 可以创建加密隧道，转发端口流量。这在访问远程服务时很有用。

本地端口转发——把远程服务映射到本地：

```bash
# 将远程的 ROS 2 话题可视化工具（运行在 8080 端口）映射到本地
$ ssh -L 8080:localhost:8080 alice@robot
# 现在访问 localhost:8080 就是访问远程的 8080

# 访问远程机器上的 Jupyter Notebook
$ ssh -L 8888:localhost:8888 alice@robot
```

远程端口转发——把本地服务映射到远程：

```bash
# 让远程机器能访问本地的服务
$ ssh -R 3000:localhost:3000 alice@robot
```

动态端口转发——创建 SOCKS 代理：

```bash
$ ssh -D 1080 alice@robot
# 本地 1080 端口成为 SOCKS 代理
```

==== 文件传输：scp 和 rsync

`scp`（secure copy）通过 SSH 复制文件，用法类似 `cp`：

```bash
# 上传文件到远程
$ scp file.txt alice@192.168.1.50:/home/alice/
$ scp file.txt robot:~/  # 使用 SSH 配置的别名

# 下载文件到本地
$ scp alice@192.168.1.50:/home/alice/data.csv ./
$ scp robot:~/results.txt ./

# 复制整个目录（-r 递归）
$ scp -r project/ robot:~/

# 使用非默认端口
$ scp -P 2222 file.txt robot:~/
```

`scp` 简单直接，但每次都会完整传输文件。对于大目录或频繁同步，`rsync` 更高效——它只传输有变化的部分。

```bash
# 同步目录到远程
$ rsync -avz project/ robot:~/project/
# -a 归档模式（保留权限、时间等）
# -v 显示详细信息
# -z 压缩传输

# 从远程同步到本地
$ rsync -avz robot:~/data/ ./data/

# 显示进度
$ rsync -avz --progress large_file.zip robot:~/

# 删除远程有但本地没有的文件（镜像同步）
$ rsync -avz --delete project/ robot:~/project/

# 排除某些文件
$ rsync -avz --exclude='build/' --exclude='*.log' project/ robot:~/project/

# 试运行（不实际传输，只显示会做什么）
$ rsync -avzn project/ robot:~/project/
```

`rsync` 的增量同步特别适合开发场景：

```bash
# 修改代码后，只同步变化的文件
$ rsync -avz ~/ros2_ws/src/ robot:~/ros2_ws/src/

# 同步后在远程编译
$ ssh robot "cd ros2_ws && colcon build"
```

对于更复杂的文件同步需求，可以考虑使用 `unison`（双向同步）或设置网络文件系统（NFS、SSHFS）。

*SSHFS：挂载远程目录*

SSHFS 可以把远程目录挂载到本地，像访问本地文件一样访问远程文件：

```bash
# 安装 sshfs
$ sudo apt install sshfs

# 创建挂载点
$ mkdir ~/remote_robot

# 挂载远程目录
$ sshfs robot:/home/alice/ros2_ws ~/remote_robot

# 现在可以直接访问
$ ls ~/remote_robot
build  install  log  src

# 卸载
$ fusermount -u ~/remote_robot
```

这对于用本地 IDE（如 VS Code）编辑远程代码非常方便。VS Code 也有 Remote-SSH 扩展，提供更集成的体验。

==== 为什么机器人开发离不开 SSH

在 RoboMaster 开发中，SSH 不是可选的技能，而是必需的。这有几个原因。

首先，机器人上的计算机通常没有显示器和键盘。机器人需要轻量化，不可能带着显示器跑。即使在调试时临时接上显示器，操作起来也很不方便。SSH 让你可以舒适地坐在自己的工位上，用自己熟悉的键盘和屏幕操作机器人。

其次，机器人可能在运动中。你不能一边追着机器人跑，一边敲键盘。通过无线 SSH 连接，机器人可以自由移动，你可以远程观察它的状态、查看日志、调整参数。

第三，调试需要同时观察多个方面。你可能需要同时查看视觉节点的输出、控制节点的日志、系统资源使用情况。在本地终端开多个窗口，分别 SSH 到机器人执行不同的命令，比在机器人上切换窗口方便得多。

第四，团队协作。多人可能需要同时访问同一台机器人进行调试。SSH 天然支持多用户同时登录，每个人在自己的终端工作，互不干扰。

一个典型的调试场景：

```bash
# 终端 1：查看检测节点的输出
$ ssh robot
$ ros2 topic echo /detector/armors

# 终端 2：监控系统资源
$ ssh robot
$ htop

# 终端 3：实时查看日志
$ ssh robot
$ tail -f ~/ros2_ws/log/latest/detector_node.log

# 终端 4：运行可视化工具
$ ssh -X robot  # -X 启用 X11 转发
$ rqt_image_view
```

SSH 的 X11 转发（`-X` 选项）允许在远程运行图形程序，窗口显示在本地。这对于运行 rqt、rviz 等可视化工具很有用，不过性能可能不如本地运行。

使用 `tmux` 或 `screen` 可以让远程会话在断开后继续运行：

```bash
# 在机器人上启动 tmux 会话
$ ssh robot
$ tmux new -s vision

# 运行程序
$ ros2 launch rm_vision vision_launch.py

# 按 Ctrl+B 然后 D 分离会话
# 断开 SSH 连接，程序继续运行

# 重新连接
$ ssh robot
$ tmux attach -t vision
```

这对于长时间运行的测试特别有用——即使网络断开，程序也不会中断。

==== 网络配置技巧

在 RoboMaster 场景中，网络配置有一些常见的模式。

*固定 IP 配置*

在比赛或测试环境中，通常需要给机器人分配固定 IP，以便可靠地连接：

```bash
# 使用 netplan（Ubuntu 18.04+）
$ sudo nano /etc/netplan/01-network-config.yaml
```

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.1.50/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

```bash
$ sudo netplan apply
```

*多机器人网络*

多台机器人组成网络时，需要规划 IP 地址和 ROS 2 域 ID：

```bash
# 机器人 1：192.168.1.50，ROS_DOMAIN_ID=1
# 机器人 2：192.168.1.51，ROS_DOMAIN_ID=2
# 控制站：192.168.1.100

# 在各机器的 .bashrc 中设置
export ROS_DOMAIN_ID=1
```

*无线热点*

机器人可以创建自己的无线热点，便于笔记本直接连接：

```bash
# 使用 nmcli 创建热点
$ sudo nmcli device wifi hotspot ssid "RoboMaster" password "password123"
```

SSH 是连接物理世界（机器人）和你的开发环境的桥梁。熟练使用 SSH，你就能随时随地访问和控制机器人，不受物理位置的限制。这是从"能让机器人动起来"到"能高效开发机器人"的关键一步。


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

当你发现自己反复输入相同的命令序列时，就是学习 Shell 脚本的时机了。Shell 脚本是将多个命令组合在一起的程序，可以自动执行重复性任务。编译项目、部署代码、备份文件、初始化环境——这些日常工作都可以用脚本自动化。脚本不仅节省时间，还能减少人为错误，让复杂的操作变得可重复、可分享。本节将带你从零开始编写 Shell 脚本，掌握变量、条件、循环、函数等基本概念，最后通过几个实用示例展示如何用脚本解决实际问题。

==== 第一个脚本与 Shebang

让我们从最简单的脚本开始。用你喜欢的编辑器创建一个文件：

```bash
$ nano hello.sh
```

输入以下内容：

```bash
#!/bin/bash

echo "Hello, RoboMaster!"
echo "Current time: $(date)"
echo "Current directory: $(pwd)"
```

保存并退出。第一行 `#!/bin/bash` 称为 shebang（或 hashbang），它告诉系统用哪个解释器执行这个脚本。`#!` 后面是解释器的路径，这里是 `/bin/bash`。没有 shebang，系统可能不知道如何执行你的脚本，或者用错误的解释器执行。

赋予脚本执行权限并运行：

```bash
$ chmod +x hello.sh
$ ./hello.sh
Hello, RoboMaster!
Current time: Mon Jan 15 10:30:00 CST 2024
Current directory: /home/alice/scripts
```

`$(command)` 是命令替换语法，它执行括号内的命令并将输出插入到该位置。这让你可以在脚本中动态获取信息。

你也可以显式用 bash 运行脚本，这时不需要执行权限：

```bash
$ bash hello.sh
```

但养成添加 shebang 和执行权限的习惯更好——这让脚本成为独立的可执行程序。

关于 shebang 的一些变体：

```bash
#!/bin/bash          # 使用 bash
#!/bin/sh            # 使用系统默认 shell（可能是 dash，更严格）
#!/usr/bin/env bash  # 更可移植，使用 PATH 中找到的 bash
#!/usr/bin/env python3  # Python 脚本也用同样的方式
```

`#!/usr/bin/env bash` 的好处是不硬编码 bash 的路径，在不同系统上更通用。

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

变量名区分大小写，习惯上普通变量用小写，环境变量用大写。

命令的输出可以赋值给变量：

```bash
#!/bin/bash

# 命令替换
current_date=$(date +%Y-%m-%d)
file_count=$(ls | wc -l)
git_branch=$(git branch --show-current 2>/dev/null || echo "not a git repo")

echo "Date: $current_date"
echo "Files in current directory: $file_count"
echo "Git branch: $git_branch"
```

一些特殊变量在脚本中很有用：

```bash
$0          # 脚本名称
$1, $2, ... # 命令行参数
$#          # 参数个数
$@          # 所有参数（作为独立的字符串）
$*          # 所有参数（作为一个字符串）
$?          # 上一个命令的退出状态
$$          # 当前脚本的进程 ID
$USER       # 当前用户名
$HOME       # 用户主目录
$PWD        # 当前工作目录
```

*用户输入*

`read` 命令从用户获取输入：

```bash
#!/bin/bash

echo -n "Enter your name: "  # -n 不换行
read username

echo -n "Enter project name: "
read project

echo "Hello, $username! Setting up $project..."

# 带提示的读取
read -p "Continue? [y/n] " answer
if [[ "$answer" == "y" ]]; then
    echo "Proceeding..."
fi

# 隐藏输入（用于密码）
read -s -p "Enter password: " password
echo  # 换行
```

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
    echo "Config file not found, creating default..."
    touch "$file"
fi
```

`[[ ]]` 是 Bash 的条件测试语法，比传统的 `[ ]` 更强大，支持更多操作符，也更不容易出错（比如变量为空时不会报语法错误）。

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
    echo "Workspace not found, creating..."
    mkdir -p "$workspace/src"
fi

if [[ -x "/opt/ros/humble/setup.bash" ]]; then
    source /opt/ros/humble/setup.bash
else
    echo "ROS 2 not installed!"
    exit 1
fi
```

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

read -p "Enter ROS distro [humble/iron]: " distro

if [[ -z "$distro" ]]; then
    distro="humble"
    echo "Using default: $distro"
fi

if [[ "$distro" == "humble" || "$distro" == "iron" ]]; then
    echo "Setting up ROS 2 $distro..."
    source "/opt/ros/$distro/setup.bash"
else
    echo "Unknown distro: $distro"
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

cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2)}')

if (( cpu_usage > 80 )); then
    echo "Warning: High CPU usage: ${cpu_usage}%"
elif (( cpu_usage > 50 )); then
    echo "CPU usage moderate: ${cpu_usage}%"
else
    echo "CPU usage normal: ${cpu_usage}%"
fi
```

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

# 遍历文件
for file in *.cpp; do
    echo "Processing $file..."
    # 对每个文件执行操作
done

# 遍历命令输出
for pkg in $(ros2 pkg list); do
    echo "Found package: $pkg"
done

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

# 使用 seq 命令
for i in $(seq 1 10); do
    echo "Number: $i"
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

# 无限循环（常用于监控脚本）
while true; do
    echo "Checking system status..."
    # 检查某些条件
    sleep 5
done
```

等待条件满足：

```bash
#!/bin/bash

# 等待 ROS 2 节点启动
echo "Waiting for detector_node..."
while ! ros2 node list 2>/dev/null | grep -q "detector_node"; do
    sleep 1
done
echo "detector_node is running!"

# 等待文件出现
while [[ ! -f "/tmp/ready.flag" ]]; do
    echo "Waiting for initialization..."
    sleep 2
done
echo "System ready!"
```

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
    echo "Hello, $1!"  # $1 是第一个参数
}

# 调用函数
greet "Alice"
greet "Bob"

# 带多个参数的函数
log_message() {
    local level="$1"    # local 声明局部变量
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message"
}

log_message "INFO" "Starting application"
log_message "ERROR" "Connection failed"
```

函数可以返回值，但只能返回 0-255 的整数作为退出状态。要返回其他值，用 `echo` 输出并捕获：

```bash
#!/bin/bash

# 返回退出状态
is_ros_installed() {
    if [[ -d "/opt/ros" ]]; then
        return 0  # 成功/真
    else
        return 1  # 失败/假
    fi
}

if is_ros_installed; then
    echo "ROS is installed"
fi

# 返回字符串值
get_ros_distro() {
    if [[ -d "/opt/ros/humble" ]]; then
        echo "humble"
    elif [[ -d "/opt/ros/iron" ]]; then
        echo "iron"
    else
        echo "unknown"
    fi
}

distro=$(get_ros_distro)
echo "Detected ROS 2 distro: $distro"

# 返回计算结果
add_numbers() {
    local a=$1
    local b=$2
    echo $((a + b))
}

result=$(add_numbers 5 3)
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
echo "All arguments: $@"
echo "Number of arguments: $#"

# 检查参数
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <project_name> [build_type]"
    exit 1
fi

project_name="$1"
build_type="${2:-Release}"  # 默认值

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
    echo "Usage: $0 [-v] [-o output_dir] [-c config_file] <input>"
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
shift $((OPTIND - 1))

# 检查必需参数
if [[ $# -lt 1 ]]; then
    echo "Error: Missing input file"
    show_help
    exit 1
fi

input_file="$1"

# 使用参数
echo "Input: $input_file"
echo "Output: $output_dir"
echo "Config: $config_file"
echo "Verbose: $verbose"
```

*退出状态*

每个命令执行后都有一个退出状态码（0 表示成功，非 0 表示失败）。脚本也应该返回适当的退出状态：

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

使用 `set` 可以改变脚本的行为：

```bash
#!/bin/bash

set -e  # 任何命令失败立即退出
set -u  # 使用未定义变量时报错
set -o pipefail  # 管道中任何命令失败则整体失败

# 通常组合使用
set -euo pipefail

# 现在任何错误都会导致脚本退出
cd /nonexistent_dir  # 这里会失败并退出
echo "This won't be printed"
```

==== 实用脚本示例

让我们看几个 RoboMaster 开发中实用的脚本。

*编译脚本*

```bash
#!/bin/bash
# build.sh - ROS 2 工作空间编译脚本

set -euo pipefail

# 配置
WORKSPACE="${HOME}/ros2_ws"
ROS_DISTRO="${ROS_DISTRO:-humble}"
BUILD_TYPE="${1:-Release}"
PARALLEL_JOBS=$(nproc)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境
check_environment() {
    if [[ ! -d "/opt/ros/$ROS_DISTRO" ]]; then
        log_error "ROS 2 $ROS_DISTRO not found!"
        exit 1
    fi

    if [[ ! -d "$WORKSPACE" ]]; then
        log_error "Workspace not found: $WORKSPACE"
        exit 1
    fi
}

# 清理构建
clean_build() {
    log_info "Cleaning build directories..."
    rm -rf "$WORKSPACE/build" "$WORKSPACE/install" "$WORKSPACE/log"
}

# 编译
build() {
    log_info "Building workspace in $BUILD_TYPE mode..."
    
    cd "$WORKSPACE"
    source "/opt/ros/$ROS_DISTRO/setup.bash"
    
    colcon build \
        --cmake-args "-DCMAKE_BUILD_TYPE=$BUILD_TYPE" \
        --parallel-workers "$PARALLEL_JOBS" \
        --symlink-install
    
    if [[ $? -eq 0 ]]; then
        log_info "Build completed successfully!"
    else
        log_error "Build failed!"
        exit 1
    fi
}

# 主流程
main() {
    log_info "ROS 2 Build Script"
    log_info "Workspace: $WORKSPACE"
    log_info "ROS Distro: $ROS_DISTRO"
    log_info "Build Type: $BUILD_TYPE"
    
    check_environment
    
    if [[ "${2:-}" == "--clean" ]]; then
        clean_build
    fi
    
    build
    
    log_info "To use the workspace, run:"
    echo "  source $WORKSPACE/install/setup.bash"
}

main "$@"
```

*环境初始化脚本*

```bash
#!/bin/bash
# setup_dev.sh - 开发环境初始化脚本

set -euo pipefail

echo "========================================="
echo "RoboMaster Development Environment Setup"
echo "========================================="

# 检查是否为 root
if [[ $EUID -eq 0 ]]; then
    echo "Please don't run this script as root"
    exit 1
fi

# 更新系统
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 安装基础工具
echo "Installing development tools..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    vim \
    curl \
    wget \
    htop \
    tree \
    python3-pip

# 安装 ROS 2 依赖
echo "Installing ROS 2 dependencies..."
sudo apt install -y \
    libopencv-dev \
    libeigen3-dev \
    libfmt-dev \
    libspdlog-dev \
    libyaml-cpp-dev

# 检查 ROS 2
if [[ ! -d "/opt/ros/humble" ]]; then
    echo "ROS 2 Humble not found. Please install it first."
    echo "See: https://docs.ros.org/en/humble/Installation.html"
else
    echo "ROS 2 Humble found."
fi

# 创建工作空间
WORKSPACE="$HOME/ros2_ws"
if [[ ! -d "$WORKSPACE" ]]; then
    echo "Creating workspace at $WORKSPACE..."
    mkdir -p "$WORKSPACE/src"
fi

# 配置 bashrc
if ! grep -q "source /opt/ros/humble/setup.bash" ~/.bashrc; then
    echo "Configuring .bashrc..."
    {
        echo ""
        echo "# ROS 2 Setup"
        echo "source /opt/ros/humble/setup.bash"
        echo "source $WORKSPACE/install/setup.bash 2>/dev/null || true"
        echo "export ROS_DOMAIN_ID=0"
    } >> ~/.bashrc
fi

# 配置 Git（如果未配置）
if [[ -z "$(git config --global user.name)" ]]; then
    read -p "Enter your Git username: " git_name
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
fi

# 添加用户到必要的组
sudo usermod -aG dialout "$USER"
sudo usermod -aG video "$USER"

echo ""
echo "========================================="
echo "Setup complete!"
echo "Please log out and log back in for group changes to take effect."
echo "Then run: source ~/.bashrc"
echo "========================================="
```

*备份脚本*

```bash
#!/bin/bash
# backup.sh - 项目备份脚本

set -euo pipefail

# 配置
SOURCE_DIR="${1:-$HOME/ros2_ws}"
BACKUP_DIR="${2:-$HOME/backups}"
MAX_BACKUPS=5

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 生成备份文件名
timestamp=$(date +%Y%m%d_%H%M%S)
project_name=$(basename "$SOURCE_DIR")
backup_file="$BACKUP_DIR/${project_name}_${timestamp}.tar.gz"

echo "Backing up $SOURCE_DIR..."
echo "Destination: $backup_file"

# 创建备份（排除构建目录和大文件）
tar czf "$backup_file" \
    --exclude='build' \
    --exclude='install' \
    --exclude='log' \
    --exclude='.git' \
    --exclude='*.bag' \
    --exclude='*.onnx' \
    -C "$(dirname "$SOURCE_DIR")" \
    "$(basename "$SOURCE_DIR")"

# 显示备份大小
backup_size=$(du -h "$backup_file" | cut -f1)
echo "Backup created: $backup_file ($backup_size)"

# 清理旧备份
backup_count=$(ls -1 "$BACKUP_DIR/${project_name}_"*.tar.gz 2>/dev/null | wc -l)
if (( backup_count > MAX_BACKUPS )); then
    echo "Cleaning old backups (keeping $MAX_BACKUPS)..."
    ls -1t "$BACKUP_DIR/${project_name}_"*.tar.gz | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f
fi

echo "Backup complete!"
```

*启动脚本*

```bash
#!/bin/bash
# launch_robot.sh - 机器人系统启动脚本

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/robot_logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 创建日志目录
mkdir -p "$LOG_DIR"

# 设置环境
source /opt/ros/humble/setup.bash
source "$HOME/ros2_ws/install/setup.bash"

# 清理函数
cleanup() {
    echo "Shutting down..."
    # 终止所有相关进程
    pkill -f "ros2" || true
    echo "Cleanup complete"
}

# 注册清理函数
trap cleanup EXIT

# 检查串口权限
if [[ ! -r "/dev/ttyUSB0" ]]; then
    echo "Warning: Cannot access /dev/ttyUSB0"
    echo "Run: sudo usermod -aG dialout $USER"
fi

# 启动节点
echo "Starting robot system..."
echo "Logs: $LOG_DIR/robot_$TIMESTAMP.log"

ros2 launch rm_bringup robot_launch.py 2>&1 | tee "$LOG_DIR/robot_$TIMESTAMP.log"
```

Shell 脚本是提高工作效率的利器。从简单的命令组合开始，逐渐添加变量、条件、循环、函数，你可以构建出功能强大的自动化工具。好的脚本应该有清晰的注释、恰当的错误处理、友好的输出信息。随着经验积累，你会建立起自己的脚本库，让重复性工作变得轻松愉快。记住，如果某件事你需要做两次以上，就值得写一个脚本来自动化它。


=== 开发环境配置
// 打造高效的开发环境
// - Shell 配置：.bashrc, .zshrc, alias
// - Oh My Zsh 美化
// - tmux 终端复用
// - VS Code 远程开发
// - CMake 项目构建流程
// - 常见问题排查
// === 开发环境配置

工具决定效率。一个精心配置的开发环境可以让你的工作事半功倍，而一个混乱的环境会让简单的任务变得繁琐。本节将带你从 Shell 配置开始，逐步打造一个高效、舒适的 Linux 开发环境。我们会配置命令行提示符和别名、介绍 Zsh 和 Oh My Zsh 的美化方案、学习 tmux 终端复用、设置 VS Code 远程开发，最后梳理 CMake 项目的完整构建流程。这些配置一次到位，将长期提升你的开发体验。

==== Shell 配置

Shell 的行为由配置文件控制。对于 Bash，最重要的配置文件是 `~/.bashrc`，它在每次启动交互式 Shell 时执行。

*理解配置文件*

Bash 有几个配置文件，在不同场景下加载：

- `~/.bashrc`：交互式非登录 Shell（如打开终端窗口）
- `~/.bash_profile` 或 `~/.profile`：登录 Shell（如 SSH 登录、TTY 登录）
- `~/.bash_logout`：退出登录 Shell 时执行

大多数情况下，你只需要编辑 `~/.bashrc`。为了确保登录 Shell 也能加载它，通常在 `~/.profile` 中添加：

```bash
# ~/.profile
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
```

*定制 .bashrc*

一个典型的 `.bashrc` 配置：

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
shopt -s checkwinsize            # 自动调整窗口大小
shopt -s globstar                # * 匹配多级目录
shopt -s cdspell                 # 自动纠正 cd 的拼写错误

# ========== 提示符配置 ==========
# 带颜色的提示符：用户@主机:目录$
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# 带 Git 分支的提示符
parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '

# ========== 别名 ==========
# 文件操作
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'

# 安全操作
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# 快捷操作
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git 别名
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

# ROS 2 别名
alias cb='colcon build --symlink-install'
alias cbs='colcon build --symlink-install --packages-select'
alias cbd='colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Debug'
alias cbr='colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release'
alias st='source install/setup.bash'

# 系统监控
alias ports='ss -tuln'
alias meminfo='free -h'
alias diskinfo='df -h'

# ========== 环境变量 ==========
export EDITOR=vim
export VISUAL=vim
export PATH="$HOME/.local/bin:$PATH"

# ROS 2 环境
if [ -f /opt/ros/humble/setup.bash ]; then
    source /opt/ros/humble/setup.bash
fi

# 工作空间环境
if [ -f ~/ros2_ws/install/setup.bash ]; then
    source ~/ros2_ws/install/setup.bash
fi

export ROS_DOMAIN_ID=0

# ========== 自定义函数 ==========
# 创建并进入目录
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# 快速查找文件
ff() {
    find . -name "*$1*"
}

# 快速查找内容
fg() {
    grep -rn "$1" .
}

# ROS 2 工作空间快速切换
ws() {
    local workspace="${1:-ros2_ws}"
    cd "$HOME/$workspace" && source install/setup.bash 2>/dev/null
    echo "Switched to $workspace"
}
```

修改 `.bashrc` 后，执行 `source ~/.bashrc` 使更改生效，或打开新终端。

*别名的威力*

别名是提高效率的简单方法。把常用的长命令定义成短别名：

```bash
# 项目特定的别名
alias rmv='cd ~/ros2_ws/src/rm_vision'
alias rmc='cd ~/ros2_ws/src/rm_control'

# 编译特定包
alias build_vision='colcon build --packages-select rm_vision rm_detector rm_tracker'

# 启动常用的 launch 文件
alias launch_robot='ros2 launch rm_bringup robot.launch.py'
alias launch_sim='ros2 launch rm_gazebo simulation.launch.py'

# 连接机器人
alias ssh_robot='ssh alice@192.168.1.50'

# 查看特定话题
alias echo_armor='ros2 topic echo /detector/armors'
```

==== Zsh 与 Oh My Zsh

Zsh（Z Shell）是 Bash 的现代替代品，提供更强大的自动补全、更好的脚本支持和丰富的自定义能力。Oh My Zsh 是一个 Zsh 配置框架，让 Zsh 的配置变得简单。

*安装 Zsh*

```bash
# 安装 Zsh
$ sudo apt install zsh

# 验证安装
$ zsh --version
zsh 5.8.1

# 设为默认 Shell
$ chsh -s $(which zsh)
# 需要重新登录生效
```

*安装 Oh My Zsh*

```bash
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

安装后，Zsh 配置文件是 `~/.zshrc`。Oh My Zsh 提供了主题和插件系统。

*配置主题*

Oh My Zsh 自带很多主题。编辑 `~/.zshrc`：

```bash
# 使用 agnoster 主题（需要 Powerline 字体）
ZSH_THEME="agnoster"

# 或者使用简洁的 robbyrussell（默认）
ZSH_THEME="robbyrussell"

# 或者随机主题
ZSH_THEME="random"
```

推荐安装 Powerlevel10k 主题，它提供漂亮的提示符和丰富的信息显示：

```bash
# 安装 Powerlevel10k
$ git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# 在 ~/.zshrc 中设置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 重启终端，会自动启动配置向导
```

如果字符显示为方块，需要安装 Nerd Fonts：

```bash
# 下载并安装字体（以 MesloLGS NF 为例）
$ mkdir -p ~/.local/share/fonts
$ cd ~/.local/share/fonts
$ curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
$ fc-cache -fv

# 然后在终端设置中选择这个字体
```

*配置插件*

Oh My Zsh 的插件提供额外的功能。编辑 `~/.zshrc`：

```bash
plugins=(
    git                  # Git 别名和补全
    sudo                 # 双击 Esc 在命令前加 sudo
    history             # 历史命令相关
    colored-man-pages   # 彩色 man 页面
    command-not-found   # 提示安装缺失的命令
    extract             # 智能解压（x 命令）
    z                   # 目录跳转（z dirname）
)
```

两个强烈推荐的第三方插件：

```bash
# zsh-autosuggestions：基于历史的命令建议
$ git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-syntax-highlighting：命令语法高亮
$ git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 添加到插件列表
plugins=(
    git
    sudo
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
)
```

*迁移 Bash 配置*

如果你从 Bash 迁移到 Zsh，大部分配置可以直接复制。在 `~/.zshrc` 末尾添加：

```bash
# 加载 ROS 2
source /opt/ros/humble/setup.zsh

# 工作空间
source ~/ros2_ws/install/setup.zsh 2>/dev/null

# 别名（大部分与 Bash 相同）
alias ll='ls -alF'
alias cb='colcon build --symlink-install'
# ...其他别名

# 自定义函数也可以直接复制
mkcd() {
    mkdir -p "$1" && cd "$1"
}
```

注意 ROS 2 的 setup 文件有 `.zsh` 版本。

==== tmux 终端复用

tmux（Terminal Multiplexer）让你在一个终端窗口中运行多个会话。更重要的是，会话可以在断开连接后继续运行——这对于远程开发至关重要。

*安装和基本概念*

```bash
$ sudo apt install tmux
```

tmux 有三个层次的概念：

- *会话（Session）*：一组窗口的集合，可以独立于终端存在
- *窗口（Window）*：类似于标签页，每个会话可以有多个窗口
- *面板（Pane）*：窗口内的分割区域

*基本操作*

```bash
# 启动新会话
$ tmux

# 启动命名会话
$ tmux new -s robot

# 列出会话
$ tmux ls

# 连接到会话
$ tmux attach -t robot
# 或简写
$ tmux a -t robot

# 断开会话（会话继续运行）
# 在 tmux 中按 Ctrl+B 然后 D

# 关闭会话
$ tmux kill-session -t robot
```

tmux 的所有快捷键都以前缀键开始，默认是 `Ctrl+B`。按下前缀键后，再按其他键执行操作。

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

面板管理：
- `%`：垂直分割（左右）
- `"`：水平分割（上下）
- `方向键`：在面板间移动
- `x`：关闭当前面板
- `z`：最大化/恢复当前面板
- `空格`：切换面板布局

其他：
- `?`：显示帮助
- `[`：进入复制模式（可滚动查看历史）
- `]`：粘贴

*tmux 配置*

创建 `~/.tmux.conf` 自定义 tmux：

```bash
# ~/.tmux.conf

# 更改前缀键为 Ctrl+A（更容易按）
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# 启用鼠标支持
set -g mouse on

# 从 1 开始编号（0 太远了）
set -g base-index 1
setw -g pane-base-index 1

# 更直观的分割快捷键
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# 使用 Alt+方向键切换面板（无需前缀）
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# 快速重载配置
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# 256 色支持
set -g default-terminal "screen-256color"

# 增加历史记录
set -g history-limit 10000

# 减少命令延迟
set -sg escape-time 0

# 状态栏美化
set -g status-style bg=black,fg=white
set -g status-left '[#S] '
set -g status-right '%H:%M %d-%b-%y'
```

*RoboMaster 开发的 tmux 工作流*

一个典型的机器人开发 tmux 布局：

```bash
# 创建会话
$ tmux new -s robot

# 窗口 1：代码编辑（默认窗口）
$ vim ~/ros2_ws/src/rm_vision/...

# 创建窗口 2：编译和运行
Ctrl+B c
$ cd ~/ros2_ws && colcon build

# 创建窗口 3：监控（分割成多个面板）
Ctrl+B c
Ctrl+B %                    # 垂直分割
$ htop                       # 左侧：系统监控
Ctrl+B 方向键切换到右侧
Ctrl+B "                    # 水平分割
$ ros2 topic echo /armors   # 右上：话题监控
Ctrl+B 方向键切换到右下
$ tail -f ~/ros2_ws/log/latest/*.log  # 右下：日志

# 断开会话（会话保持运行）
Ctrl+B d

# 重新连接
$ tmux a -t robot
```

==== VS Code 远程开发

VS Code 的 Remote-SSH 扩展让你可以在本地编辑远程服务器上的代码，同时享受完整的 IDE 功能。

*安装和配置*

1. 在本地 VS Code 中安装 "Remote - SSH" 扩展

2. 配置 SSH（确保已设置密钥认证）：
```bash
# ~/.ssh/config
Host robot
    HostName 192.168.1.50
    User alice
    IdentityFile ~/.ssh/id_ed25519
```

3. 在 VS Code 中连接：
   - 按 `F1` 或 `Ctrl+Shift+P`
   - 输入 "Remote-SSH: Connect to Host"
   - 选择配置的主机

4. 首次连接时，VS Code 会在远程主机安装服务器组件

*远程开发工作流*

连接后，VS Code 的所有功能都在远程运行：

- 文件浏览器显示远程文件系统
- 终端是远程 Shell
- 扩展在远程执行（需要在远程重新安装一些扩展）
- Git 集成使用远程仓库

推荐在远程安装的扩展：
- C/C++（微软官方）
- CMake Tools
- Python
- ROS（如果开发 ROS 2）

*配置 VS Code for ROS 2*

在远程项目中创建 `.vscode/settings.json`：

```json
{
    "C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools",
    "cmake.configureOnOpen": true,
    "cmake.buildDirectory": "${workspaceFolder}/build",
    "files.associations": {
        "*.launch.py": "python",
        "*.xacro": "xml"
    },
    "python.analysis.extraPaths": [
        "/opt/ros/humble/lib/python3.10/site-packages",
        "${workspaceFolder}/install/lib/python3.10/site-packages"
    ],
    "terminal.integrated.env.linux": {
        "PYTHONPATH": "/opt/ros/humble/lib/python3.10/site-packages:${workspaceFolder}/install/lib/python3.10/site-packages"
    }
}
```

创建 `.vscode/c_cpp_properties.json`：

```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/*",
                "/opt/ros/humble/include/*",
                "/usr/include/*"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/g++",
            "cStandard": "c17",
            "cppStandard": "c++17",
            "intelliSenseMode": "linux-gcc-x64",
            "configurationProvider": "ms-vscode.cmake-tools"
        }
    ],
    "version": 4
}
```

==== CMake 项目构建流程

CMake 是 C/C++ 项目的标准构建系统，理解其工作流程对于 RoboMaster 开发很重要。

*标准 CMake 流程*

```bash
# 1. 创建构建目录（外部构建）
$ mkdir build && cd build

# 2. 配置（生成构建系统）
$ cmake ..
# 或指定选项
$ cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        ..

# 3. 编译
$ make -j$(nproc)
# 或使用 cmake 统一接口
$ cmake --build . --parallel

# 4. 安装（可选）
$ sudo make install
# 或
$ cmake --install .
```

*常用 CMake 选项*

```bash
# 构建类型
-DCMAKE_BUILD_TYPE=Debug|Release|RelWithDebInfo|MinSizeRel

# 安装路径
-DCMAKE_INSTALL_PREFIX=/path/to/install

# 指定编译器
-DCMAKE_C_COMPILER=gcc-11
-DCMAKE_CXX_COMPILER=g++-11

# 指定生成器
-G "Ninja"        # 使用 Ninja（比 Make 快）
-G "Unix Makefiles"  # 默认

# 自定义选项（项目定义的）
-DWITH_CUDA=ON
-DBUILD_TESTS=OFF
```

*ccmake 交互式配置*

```bash
$ sudo apt install cmake-curses-gui
$ ccmake ..
```

ccmake 提供文本界面，让你可以浏览和修改所有 CMake 选项，非常方便探索项目的配置选项。

*ROS 2 colcon 构建*

ROS 2 使用 colcon 管理多包工作空间，它在底层调用 CMake：

```bash
# 进入工作空间
$ cd ~/ros2_ws

# 构建所有包
$ colcon build

# 常用选项
$ colcon build --symlink-install           # 符号链接安装（便于开发）
$ colcon build --packages-select pkg1 pkg2  # 只构建指定包
$ colcon build --packages-up-to pkg1        # 构建包及其依赖
$ colcon build --cmake-args -DCMAKE_BUILD_TYPE=Debug

# 清理
$ rm -rf build/ install/ log/

# 构建后 source
$ source install/setup.bash
```

*调试构建问题*

```bash
# 详细输出
$ colcon build --event-handlers console_direct+

# 查看 CMake 配置输出
$ cat build/<package>/CMakeCache.txt

# 单独配置某个包（用于调试）
$ cd build/<package>
$ cmake ../../src/<package> -DCMAKE_BUILD_TYPE=Debug

# 查看编译命令
$ cmake --build . --verbose
```

==== 常见问题排查

*找不到库或头文件*

```bash
# 错误：fatal error: opencv2/opencv.hpp: No such file or directory

# 解决：安装开发包
$ sudo apt install libopencv-dev

# 检查头文件位置
$ dpkg -L libopencv-dev | grep opencv.hpp

# 在 CMakeLists.txt 中正确 find_package
find_package(OpenCV REQUIRED)
target_link_libraries(my_target ${OpenCV_LIBS})
target_include_directories(my_target PRIVATE ${OpenCV_INCLUDE_DIRS})
```

*链接错误*

```bash
# 错误：undefined reference to `cv::imread(...)'

# 原因：没有链接库
# 解决：在 CMakeLists.txt 中添加 target_link_libraries

# 检查库是否安装
$ ldconfig -p | grep opencv
```

*运行时找不到共享库*

```bash
# 错误：error while loading shared libraries: libxxx.so

# 方法 1：添加到 LD_LIBRARY_PATH
$ export LD_LIBRARY_PATH=/path/to/lib:$LD_LIBRARY_PATH

# 方法 2：添加到系统库路径
$ echo "/path/to/lib" | sudo tee /etc/ld.so.conf.d/mylib.conf
$ sudo ldconfig

# 方法 3：安装到标准位置
$ sudo make install
$ sudo ldconfig
```

*ROS 2 包找不到*

```bash
# 错误：Package 'xxx' not found

# 检查是否 source 了环境
$ echo $AMENT_PREFIX_PATH

# source ROS 2 和工作空间
$ source /opt/ros/humble/setup.bash
$ source ~/ros2_ws/install/setup.bash

# 检查包是否安装
$ ros2 pkg list | grep xxx

# 重新构建
$ colcon build --packages-select xxx
```

*串口权限问题*

```bash
# 错误：Permission denied: '/dev/ttyUSB0'

# 解决：添加用户到 dialout 组
$ sudo usermod -aG dialout $USER
# 重新登录

# 临时解决
$ sudo chmod 666 /dev/ttyUSB0
```

*SSH 连接问题*

```bash
# 问题：Connection refused

# 检查 SSH 服务
$ sudo systemctl status ssh
$ sudo systemctl start ssh

# 检查防火墙
$ sudo ufw status
$ sudo ufw allow ssh

# 问题：Host key verification failed
# 解决：删除旧的 known_hosts 条目
$ ssh-keygen -R hostname
```

*内存不足导致编译失败*

```bash
# 错误：c++: fatal error: Killed signal terminated program cc1plus

# 原因：内存不足，编译器被 OOM killer 杀死

# 解决 1：减少并行编译数
$ colcon build --parallel-workers 2

# 解决 2：增加 swap
$ sudo fallocate -l 4G /swapfile
$ sudo chmod 600 /swapfile
$ sudo mkswap /swapfile
$ sudo swapon /swapfile
```

*Git 子模块问题*

```bash
# 克隆后子模块为空
$ git submodule update --init --recursive

# 子模块更新
$ git submodule update --remote

# 重置子模块
$ git submodule deinit -f .
$ git submodule update --init
```

一个配置良好的开发环境是高效工作的基础。花时间配置好 Shell、编辑器、终端复用，这些投入会在日后的开发中反复回报你。记住，最好的配置是适合你自己工作流程的配置——从这里的建议开始，逐渐调整成你喜欢的样子。
