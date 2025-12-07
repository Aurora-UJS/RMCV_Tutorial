#import "/template/template.typ": *

本书主要针对基础篇的内容。

== 初识 Linux
#include "introduction_to_linux.typ"
// - Linux 发展历史
// - 为什么 RoboMaster 用 Linux
// - Linux vs Windows
// - 发行版选择
== 环境准备
#include "install_ubuntu.typ"
// - Ubuntu 安装方式（虚拟机/双系统/WSL2）
// - 基础配置（输入法、网络、驱动）
// - 开发环境搭建（VSCode、Terminal）


== Linux & Ubuntu 操作
#include "ubuntu_guide.typ"
// - 文件系统与目录结构
// - 命令行基础操作
// - 软件包管理
// - 权限与用户管理
// - Shell 脚本入门


== 计算机系统基础
// - 进程与线程
// - 内存管理（栈、堆）
// - 文件系统
// - 网络通信基础
// - 为什么需要了解这些？（引出 C++ 内存管理、多线程）
// 为后续 C++ 和软件工程打基础
#include "computer_system_basics.typ"

== C++ 语言基础
#include "cpp_syntax.typ"

== CMake 与构建系统
// - 编译原理简介
// - CMake 基础语法
// - 多文件项目组织
// - 链接外部库
// - ROS 包的 CMakeLists.txt
#include "cmake_guide.typ"

== 软件工程基础
#include "software_engineering.typ"
// - 代码规范（Google C++ Style）
// - 设计模式（常用的几种）
// - 单元测试
// - 调试技巧（GDB、日志）
// - 性能分析
// - 文档编写
== Git 版本控制
// - Git 基本概念
// - 本地仓库操作
// - GitHub/GitLab 远程协作
// - 分支管理
// - 团队工作流（PR、Code Review）
// - .gitignore 与 submodule
// 建议单独成章，RoboMaster 团队协作必备
//#include "git_guide.typ"

== ROS/ROS2入门
// - ROS 架构与概念
// - 话题、服务、动作
// - 创建节点与发布订阅
// - launch 文件
// - ROS 工具（rqt、rviz）
// - 实战：简单的视觉/决策节点



#blockquote[
  Euler's identity is $e^(pi i) + 1 = 0$. Do you really believe that they charged an armed enemy, or treated their children, their own flesh and blood, so cruelly, without a thought for their own interest or advantage? Such is Schrödinger's equation in

  $ i planck.reduce frac(diff, diff t) Psi lr((x comma t)) eq lr([minus frac(planck.reduce^2, 2 m) frac(diff^2, diff x^2) plus V lr((x comma t))]) Psi lr((x comma t)) $ 

  #blockquote[
    But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?
  ]
]

But I must explain to you how all this mistaken idea of reprobating pleasure and extolling pain arose. Increase ease-of-use to where `variable` and `print()` shall be of use.

#figure(caption: [Example `python` code printing text.])[
```python
if a != b:
  print("Hello world!")
else if a == b:
  print("Goodbye world!")
else:
  print("This is a long sentence where I ramble until I get 80 characters here.")
```
] <py-test>
