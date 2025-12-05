#import "/template/template.typ": *


#show raw.where(block: true): set block(inset: (left: 2em))

=== 软件包管理


Ubuntu 使用 APT (Advanced Package Tool) 管理软件安装。

/ 更新软件列表:
```bash
sudo apt update          # 更新软件包列表
```

/ 安装软件:

```bash
sudo apt install package-name        # 安装单个软件
sudo apt install pkg1 pkg2 pkg3      # 安装多个软件
sudo apt install -y package-name     # 跳过确认,自动安装
```

/ 搜索软件:

```bash
apt search keyword       # 搜索软件包
apt show package-name    # 查看软件包详情
```

/ 升级软件:

```bash
sudo apt upgrade         # 升级所有已安装的软件
```

/ 卸载软件:

```bash
sudo apt remove package-name      # 卸载软件
sudo apt autoremove               # 清理无用依赖
```

/ RoboMaster 常用软件安装:

```bash
# 编译工具链
sudo apt install build-essential cmake git

# ROS 开发工具
sudo apt install python3-pip python3-rosdep

# 视觉处理库
sudo apt install libopencv-dev libeigen3-dev

# 调试工具
sudo apt install gdb valgrind

# 串口工具
sudo apt install minicom
```

/ 软件源配置 (加速下载):

使用国内镜像源可以大幅提高下载速度:

```bash
# 备份原始配置
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 替换为清华源 (推荐)
sudo sed -i 's|//.*archive.ubuntu.com|//mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list

# 更新软件列表
sudo apt update
```

=== 文件与目录操作

/ 查看目录内容:

```bash
ls              # 列出文件
ls -l           # 详细信息(权限、大小、时间)
ls -a           # 显示隐藏文件
ls -lh          # 人类可读的文件大小
ls -lah         # 组合使用:详细+隐藏+可读大小
```

#table(
columns: (1fr, 2fr),
[*命令*], [*说明*],
[`ll`], [等同于 `ls -l` 的快捷方式],
[`tree`], [树状显示目录结构(需安装)],
)

/ 文件内容查看:

```bash
cat file.txt           # 显示完整内容
less file.txt          # 分页查看(适合大文件)
head -n 10 file.txt    # 查看前10行
tail -n 10 file.txt    # 查看后10行
tail -f log.txt        # 实时查看日志(ROS调试常用!)
```

/ less 快捷键:

#table(
columns: (1fr, 2fr)),
[*按键*], [*功能*],
[`Space` / `f`], [向下翻页],
[`b`], [向上翻页],
[`j` / `↓`], [向下一行],
[`k` / `↑`], [向上一行],
[`g` / `G`], [跳转到开头/结尾],
[`/pattern`], [搜索内容],
[`n` / `N`], [下一个/上一个搜索结果],
[`q`], [退出],
)

/ 文件编辑:

/ Nano (推荐初学者):

```bash
nano file.txt          # 打开/创建文件
# Ctrl+O 保存, Ctrl+X 退出
```

/ VSCode (推荐开发):

```bash
code .                 # 在当前目录打开 VSCode
code file.cpp          # 打开指定文件
```

/ 目录导航:

```bash
pwd                    # 显示当前路径
cd /path/to/directory  # 切换到指定目录
cd ~                   # 回到主目录
cd ..                  # 上级目录
cd -                   # 返回上次目录
```

/ 重要目录:

#table(
columns: (1fr, 2fr),
[*路径*], [*说明*],
[`~`], [用户主目录 (`/home/username`)],
[`/`], [根目录],
[`/opt`], [第三方软件安装位置(ROS常在这里)],
[`/dev`], [设备文件(串口 `/dev/ttyUSB0`)],
[`/etc`], [系统配置文件],
[`/tmp`], [临时文件],
)

/ 文件操作:

/ 创建:

```bash
mkdir folder           # 创建目录
mkdir -p a/b/c         # 创建多级目录
touch file.txt         # 创建空文件
```

/ 复制:

```bash
cp file1.txt file2.txt          # 复制文件
cp file.txt /path/to/dest/      # 复制到目录
cp -r folder1/ folder2/         # 复制整个目录
```

/ 移动/重命名:

```bash
mv file1.txt file2.txt          # 重命名
mv file.txt /path/to/dest/      # 移动文件
mv folder1/ folder2/            # 移动/重命名目录
```

/ 删除:

```bash
rm file.txt                     # 删除文件
rm -r folder/                   # 删除目录及内容
rm -f file.txt                  # 强制删除
rm -rf folder/                  # 强制递归删除(危险!请小心使用)
```

#box(
fill: rgb("#fff3cd"),
inset: 10pt,
radius: 4pt,
[*⚠️ 警告*: `rm -rf` 删除后无法恢复\! 使用前务必确认路径正确。特别注意空格位置,`rm -rf / home/folder` 会删除整个系统\!]
)

/ 查找文件:

```bash
find . -name "*.cpp"              # 查找当前目录下所有.cpp文件
find ~ -name "config.yaml"        # 在主目录查找config.yaml
find /opt/ros -type f -name "*.h" # 查找头文件
```

/ find 常用选项:

#table(
columns: (1fr, 2fr),
[*选项*], [*说明*],
[`-name 'pattern'`], [按文件名查找],
[`-type f`], [只查找文件],
[`-type d`], [只查找目录],
[`-size +100M`], [大于100MB的文件],
)

/ 通配符:

#table(
columns: (1fr, 2fr),
[*模式*], [*匹配*],
[`*`], [任意字符串],
[`*.cpp`], [所有C++源文件],
[`test_*.py`], [test\_ 开头的Python文件],
[`?`], [单个字符],
[`file?.txt`], [file1.txt, fileA.txt等],
[`[abc]`], [a、b或c中的一个],
[`*.[ch]`], [.c 或 .h 文件],
)

/ 通配符使用示例:

```bash
rm *.o              # 删除所有.o文件
cp *.cpp src/       # 复制所有.cpp文件到src目录
ls test_*.py        # 列出所有test_开头的Python文件
```

=== 压缩与解压

/ tar 命令:

tar 是 Linux 下最常用的打包和压缩工具。

/ 基本用法:

```bash
# 打包(不压缩)
tar -cf archive.tar file1 file2 folder/

# 打包并压缩(推荐使用 -a 自动识别)
tar -caf archive.tar.gz files/      # gzip压缩
tar -caf archive.tar.xz files/      # xz压缩(更高压缩率)
tar -caf archive.tar.zst files/     # zstd压缩(更快速度)

# 解压(自动识别压缩格式)
tar -xf archive.tar.gz              # 解压到当前目录
tar -xf archive.tar.gz -C dest/     # 解压到指定目录

# 查看内容(不解压)
tar -tf archive.tar.gz              # 列出文件
tar -tvf archive.tar.gz             # 详细列出(含大小、时间)
```

/ 常用选项:

#table(
columns: (auto, 1fr),
[*选项*], [*说明*],
[`-c`], [创建(create)],
[`-x`], [解压(extract)],
[`-t`], [查看(list)],
[`-f`], [指定文件名(file)],
[`-v`], [详细输出(verbose)],
[`-a`], [自动识别压缩格式(推荐)],
[`-C`], [指定输出目录],
[`-z`], [gzip压缩],
[`-j`], [bzip2压缩],
[`-J`], [xz压缩],
)

#box(
fill: rgb("#d1ecf1"),
inset: 10pt,
radius: 4pt,
[*提示*: 建议总是使用 `-a` 选项,让 tar 自动根据文件后缀选择压缩算法,避免记忆复杂的选项。]
)

/ 压缩文件后缀对照:

#table(
columns: (auto, auto, 1fr),
[*后缀*], [*压缩算法*], [*特点*],
[`.tar`], [无压缩], [仅打包],
[`.tar.gz` / `.tgz`], [gzip], [最常用,速度快],
[`.tar.xz`], [xz], [压缩率高,速度慢],
[`.tar.zst`], [zstd], [速度最快,压缩率好],
[`.tar.bz2`], [bzip2], [已较少使用],
)

=== 文件权限管理

/ 查看权限:

```bash
ls -l file.txt
# -rw-r--r-- 1 user group 1024 Dec 5 10:30 file.txt
#  ↑  ↑  ↑
#  所有者 组 其他人
```

/ 权限说明:

#table(
columns: (auto, auto, 1fr),
[*符号*], [*数字*], [*含义*],
[`r`], [4], [读取(read)],
[`w`], [2], [写入(write)],
[`x`], [1], [执行(execute)],
[`-`], [0], [无权限],
)

/ 常见权限组合:

#table(
columns: (auto, auto, 1fr),
[*数字*], [*符号*], [*说明*],
[`644`], [`rw-r--r--`], [文件:所有者可读写,其他人只读],
[`755`], [`rwxr-xr-x`], [程序:所有者可执行,其他人可读可执行],
[`700`], [`rwx------`], [仅所有者可访问],
)

/ 修改权限:

```bash
chmod +x script.sh         # 添加执行权限
chmod 755 program          # 设置为 rwxr-xr-x
chmod 644 config.yaml      # 设置为 rw-r--r--
```

/ RoboMaster 串口权限配置:

```bash
# 添加当前用户到 dialout 组(串口访问权限)
sudo usermod -aG dialout $USER

# 需要重新登录后生效,或执行:
newgrp dialout

# 临时修改串口权限(重启后失效)
sudo chmod 666 /dev/ttyUSB0
```

=== 查看帮助文档

/ 命令帮助:

```bash
command --help        # 快速查看命令帮助
man command           # 详细手册(按 q 退出)
tldr command          # 简明示例(需安装)
```

/ 安装 tldr:

```bash
sudo apt install tldr
tldr --update         # 首次使用需更新
```

/ tldr 使用示例:

```bash
tldr tar              # 查看 tar 命令的常用示例
tldr find             # 查看 find 命令的使用方法
```

#box(
fill: rgb("#d1ecf1"),
inset: 10pt,
radius: 4pt,
[*提示*: `tldr` 提供简明实用的命令示例,特别适合快速上手。`man` 则提供完整详细的文档,适合深入学习。]
)

=== 实用技巧

/ 命令历史:

```bash
history               # 查看命令历史
!123                  # 执行历史中第123条命令
!!                    # 执行上一条命令
!ssh                  # 执行最近一条以ssh开头的命令
Ctrl+R                # 搜索历史命令(推荐!)
```

/ Tab 自动补全:

  - 按 `Tab` 键自动补全命令或文件名
  - 按两次 `Tab` 显示所有可能的补全选项
  - *这是最重要的快捷键\!*

/ 终端快捷键:

#table(
columns: (auto, 1fr),
[*快捷键*], [*功能*],
[`Ctrl+C`], [中断当前命令],
[`Ctrl+D`], [退出终端/结束输入],
[`Ctrl+L`], [清屏(等同于 `clear`)],
[`Ctrl+A`], [光标移到行首],
[`Ctrl+E`], [光标移到行尾],
[`Ctrl+U`], [删除光标前的内容],
[`Ctrl+K`], [删除光标后的内容],
[`Ctrl+W`], [删除光标前的一个单词],
)

/ 多命令执行:

```bash
# 顺序执行(无论成功与否)
command1; command2; command3

# 仅当前一个成功时执行下一个
command1 && command2 && command3

# 前一个失败时才执行下一个
command1 || command2

# 后台运行
command &

# 不挂断运行(退出终端后继续运行)
nohup command &
```

/ 输出重定向:

```bash
command > file.txt              # 输出到文件(覆盖)
command >> file.txt             # 追加到文件
command 2> error.log            # 错误输出到文件
command > output.txt 2>&1       # 标准输出和错误都输出到文件
```

=== RoboMaster 常见操作场景

/ 创建工作空间:

```bash
# 创建 ROS 工作空间
mkdir -p ~/robomaster_ws/src
cd ~/robomaster_ws/src
catkin_init_workspace
cd ..
catkin_make
```

/ 查看日志:

```bash
# 实时查看 ROS 日志
tail -f ~/.ros/log/latest/rosout.log

# 查看串口通信
sudo minicom -D /dev/ttyUSB0 -b 115200
```

/ 文件传输:

```bash
# 使用 scp 传输文件到远程机器人
scp file.txt user@192.168.1.100:/home/user/

# 传输整个目录
scp -r folder/ user@192.168.1.100:/path/
```

/ 快速备份:

```bash
# 备份配置文件
cp config.yaml config.yaml.backup

# 备份整个项目
tar -caf backup_$(date +%Y%m%d).tar.gz ~/robomaster_ws/src/
```

=== 练习任务

/ *基础操作*:

  - 创建目录 `~/practice`,在其中创建5个文件
  - 使用通配符一次性删除所有 `.txt` 文件
  - 查看剩余文件的详细信息

/ *软件管理*:

  - 安装 `tree` 命令并使用
  - 搜索包含 "opencv" 的软件包
  - 查看 `git` 软件包的详细信息

/ *压缩操作*:

  - 将 `/etc/apt/sources.list` 打包压缩
  - 解压到新目录并查看内容
  - 练习使用不同压缩算法

/ *权限管理*:

  - 创建一个 Shell 脚本并添加执行权限
  - 将自己添加到 `dialout` 组

/ *综合应用*:

  - 创建 ROS 工作空间目录结构
  - 使用 `find` 查找所有 `.launch` 文件
  - 编写一键备份脚本

=== 常见问题排查

/ 权限被拒绝:

```bash
# 问题: Permission denied
# 解决: 使用 sudo 或检查文件权限
sudo command
chmod +x file
```

/ 命令未找到:

```bash
# 问题: command not found
# 解决: 检查是否安装,或检查 PATH
which command
echo $PATH
```

/ 串口无法访问:

```bash
# 检查串口设备
ls -l /dev/ttyUSB*

# 添加权限
sudo usermod -aG dialout $USER
# 重新登录生效
```

/ 磁盘空间不足:

```bash
# 查看磁盘使用情况
df -h

# 查找大文件
du -sh * | sort -h

# 清理 APT 缓存
sudo apt clean
sudo apt autoremove
```
