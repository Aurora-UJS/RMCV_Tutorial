=== Linux 的前世今生
// 从 Unix 到 Linux 的历史脉络
// - Unix 的诞生（1969，贝尔实验室，Ken Thompson & Dennis Ritchie）
// - Unix 哲学：小而美、组合、文本流
// - Unix 的分裂与商业化
// - Richard Stallman 与 GNU 计划（1983）
// - 自由软件运动与 GPL 协议
// - Linus Torvalds 与 Linux 内核（1991）
// - "I'm doing a (free) operating system (just a hobby)"
// - Linux 内核 + GNU 工具 = 完整操作系统
// - 开源社区的力量：从爱好项目到主导世界

=== 为什么 RoboMaster 开发选择 Linux
// 机器人开发者的必然选择
// - ROS/ROS2 原生运行在 Linux 上
// - 开源生态：OpenCV、PCL、Eigen 等库的最佳支持
// - 实时性与性能：更好的系统控制能力
// - 嵌入式友好：树莓派、Jetson 都运行 Linux
// - 服务器主导：部署、仿真环境
// - 开发工具链完善：GCC、GDB、CMake
// - 免费且可定制
// - 学习 Linux 是程序员的必备技能

=== Linux 与 Windows 的差异
// 两种不同的设计哲学
// - 开源 vs 闭源
// - 文件系统差异：目录树 vs 盘符
// - 路径分隔符：/ vs \
// - 大小写敏感 vs 不敏感
// - 可执行文件：无扩展名要求 vs .exe
// - 软件安装：包管理器 vs 安装向导
// - 命令行文化 vs 图形界面文化
// - 权限模型差异
// - 系统配置：文本文件 vs 注册表
// - "一切皆文件"的哲学
// - 常见的适应期困惑与解决

=== Linux 发行版选择
// 找到适合你的发行版
// - 什么是发行版：内核 + 软件包 + 桌面环境 + 包管理器
// - 主流发行版家族：
//   Debian 系（Ubuntu、Linux Mint）
//   Red Hat 系（Fedora、CentOS）
//   Arch 系（Manjaro）
// - Ubuntu：为什么是 RoboMaster 的首选
//   对新手友好
//   ROS 官方支持
//   LTS 版本稳定
//   社区庞大、文档丰富
// - Ubuntu 版本选择：22.04 LTS vs 24.04 LTS
// - 桌面环境：GNOME、KDE、XFCE

=== 安装 Linux 的方式
// 根据需求选择安装方案
// - 双系统安装
//   优点：原生性能、完整体验
//   缺点：需要分区、切换不便
//   适合：长期深度使用
// - 虚拟机（VMware / VirtualBox）
//   优点：安全隔离、快照恢复、同时使用
//   缺点：性能损耗、资源占用
//   适合：学习入门、轻度使用
// - WSL / WSL2（Windows Subsystem for Linux）
//   优点：与 Windows 无缝集成、启动快
//   缺点：GUI 支持有限、USB 设备访问受限
//   适合：命令行开发、不需要硬件访问
// - 各方案的详细安装指南
// - 推荐配置与注意事项