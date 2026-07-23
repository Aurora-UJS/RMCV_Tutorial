#import "/template/template.typ": *

#show: ilm.with(
  title: [RoboMaster \ 视觉从入门到入土],
  author: "Misaka21",
  date: datetime(year: 2025, month: 06, day: 25),
  abstract: [
    面向 RoboMaster 视觉组新队员的基础与工程实践教程。
  ],
  preface: [
    #align(center + horizon)[
      希望这本书能帮你少走一些弯路，把想法一步步带到赛场上。
    ]
  ],
  table-of-contents: outline(depth: 3),
  figure-index: (enabled: true),
  table-index: (enabled: true),
  listing-index: (enabled: true),
)

//TODO：自喵测试？持续集成？
= 基础篇
#include "chapters/1.Foundation/index.typ"
= 数学理论篇
#include "chapters/2.Theory/index.typ"
= 实战技术篇
#include "chapters/3.Practice/index.typ"
= RoboMaster应用篇
#include "chapters/4.Application/index.typ"
= 进阶篇
#include"chapters/5.Advanced/index.typ"
= 项目分析
#include"chapters/6.Projects/index.typ"


/*
= RMCS部分算法分析
#include "chapters/algorithm/omni_wheel.typ"
#include "chapters/algorithm/steering_wheel.typ"

= 通讯架构分析
#include "chapters/communication/communication.typ"
*/
