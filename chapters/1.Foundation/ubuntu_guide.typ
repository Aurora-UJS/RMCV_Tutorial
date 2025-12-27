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

=== 文件系统与目录结构
// Linux 的文件组织方式
// - 根目录 / 与目录树
// - 重要目录详解：/home, /etc, /usr, /opt, /var, /tmp, /dev, /proc
// - 绝对路径与相对路径
// - 特殊路径：. .. ~ -
// - 文件类型：普通文件、目录、链接、设备
// - 隐藏文件（.开头）

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

=== 文本编辑与处理
// 命令行下的文本操作
// - nano：新手友好的编辑器
// - vim：高效但需要学习的编辑器（基础操作）
// - 文本搜索：grep, grep -r, grep -E
// - 文本处理：sed, awk 入门
// - 排序去重统计：sort, uniq, wc
// - 文本比较：diff

=== 用户与权限管理
// 多用户系统的安全基础
// - 用户与用户组
// - root 与 sudo
// - 文件权限：rwx 与数字表示（755, 644）
// - ls -l 输出解读
// - chmod, chown
// - 为什么脚本需要 chmod +x

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

=== 进程与系统监控
// 管理运行中的程序
// - ps, top, htop
// - kill, killall, pkill
// - 前台后台：&, jobs, fg, bg
// - 系统资源：free, df, du
// - 系统服务：systemctl

=== 网络与远程访问
// 连接与远程操作
// - 网络信息：ip addr, ping
// - 下载：wget, curl
// - SSH 远程连接与密钥认证
// - 文件传输：scp, rsync
// - 为什么机器人开发离不开 SSH

=== Shell 脚本入门
// 自动化你的工作
// - 第一个脚本与 shebang
// - 变量与用户输入
// - 条件判断：if, test, [[ ]]
// - 循环：for, while
// - 函数
// - 命令行参数与退出状态
// - 实用脚本示例（编译、初始化、备份）

=== 开发环境配置
// 打造高效的开发环境
// - Shell 配置：.bashrc, .zshrc, alias
// - Oh My Zsh 美化
// - tmux 终端复用
// - VS Code 远程开发
// - CMake 项目构建流程
// - 常见问题排查