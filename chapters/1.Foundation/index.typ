#import "/template/template.typ": *

基础篇面向刚接触 RoboMaster 视觉开发的读者，依次介绍 Linux 环境、计算机系统、C++、CMake、软件工程、Git 和 ROS 2。各章既讲基本概念，也说明这些工具在机器人开发中的实际用途。

== 初识 Linux
#include "introduction_to_linux.typ"
== 环境准备
#include "install_ubuntu.typ"


== Linux & Ubuntu 操作
#include "ubuntu_guide.typ"
// - 文件系统与目录结构
// - 命令行基础操作
// - 软件包管理
// - 权限与用户管理
// - Shell 脚本入门


== 计算机系统基础
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
#include "git_guide.typ"

== ROS/ROS2 入门
// - ROS 架构与概念
// - 话题、服务、动作
// - 创建节点与发布订阅
// - launch 文件
// - ROS 工具（rqt、rviz）
// - 实战：简单的视觉/决策节点
#include "ros_guide.typ"

