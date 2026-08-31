#import "/template/template.typ": *

前六篇讨论的是「视觉系统怎么做对」。这一篇讨论的是「一群人怎么把它做出来，并且让下一届还能接着做」。

内容分两层。前半是个人的工程环境：Ubuntu 与工具链、终端与 Shell、编辑器、以及 2025 年之后无法回避的 AI 编码代理。后半是团队的协作机制：分支与提交约定、代码评审在学生战队里的真实作用、赛季节奏与知识交接。

这一篇不重复第一篇《Git 版本控制》的内容。那一章讲 Git 是什么、命令怎么用；这一章讲这些机制在 RoboMaster 战队这个特定约束下应该怎么用，以及为什么和企业的做法不一样。两章配合阅读。

篇中出现的所有配置、版本号和命令，都在一台 Ubuntu 24.04 + ROS 2 Jazzy 的开发机上实际运行过，版本记录在各节表格中。工具会更新，命令可能失效；遇到不一致时以官方文档为准，本篇提供的是选型理由和排错思路。

== 开发环境与工具链
#include "environment.typ"

== 编辑器与远程开发
#include "editor_vscode.typ"

== 与 AI 编码代理协作
#include "ai_agent.typ"

== 队内协作机制
#include "team_workflow.typ"

== 赛季节奏与知识传承
#include "season_rhythm.typ"
