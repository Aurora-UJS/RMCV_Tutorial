#import "/template/template.typ": *

#show: ilm.with(
  title: [RoboMaster \ 视觉从入门到入土],
  author: "Neomelt",
  date: datetime(year: 2025, month: 06, day: 25),
  abstract: [
    面向 RoboMaster 视觉组新队员的教程，内容涵盖开发基础、算法原理、系统实现、调试验证与开源项目阅读。
  ],
  preface: [
    #align(center + horizon)[
      #block(width: 78%)[
        #align(center)[
          #text(size: 16pt, weight: "bold")[写在前面]

          #v(1em)
          希望这本书能帮你少走一些弯路，把想法一步步带到赛场上。
        ]

        #v(1.6em)
        #align(left)[
          #set par(first-line-indent: 2em, justify: true)

          本书依次讨论开发环境与语言基础、算法理论、工程实现、系统应用、进阶场景与项目分析。第一次阅读可以按目录顺序建立整体认识；遇到具体问题时，也可以沿章节中的交叉引用回查相关原理和工具。

          公式推导、仿真结果、开源项目自述和实机测量所能说明的范围并不相同。涉及赛季规则、硬件参数和性能数字时，应同时核对文中注明的版本、条件与验证方式，再决定是否用于自己的系统。
        ]
      ]
    ]
  ],
  table-of-contents: outline(depth: 3),
  figure-index: (enabled: true),
  table-index: (enabled: true),
  listing-index: (enabled: true),
)

= 基础篇
#include "chapters/1.Foundation/index.typ"
= 数学理论篇
#include "chapters/2.Theory/index.typ"
= 实战技术篇
#include "chapters/3.Practice/index.typ"
= RoboMaster应用篇
#include "chapters/4.Application/index.typ"
= 进阶篇
#include "chapters/5.Advanced/index.typ"
= 项目分析
#include "chapters/6.Projects/index.typ"


/*
= RMCS部分算法分析
#include "chapters/algorithm/omni_wheel.typ"
#include "chapters/algorithm/steering_wheel.typ"

= 通讯架构分析
#include "chapters/communication/communication.typ"
*/
