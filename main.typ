#import "/template/template.typ": *

#show: ilm.with(
  title: [RoboMaster \ 视觉从入门到入土],
  author: "Misaka21",
  date: datetime(year: 2025, month: 06, day: 25),
  abstract: [
    Turn drawings of imagination into racetrack realization.
  ],
  preface: [
    #align(center + horizon)[
      Thank you for using this book #emoji.heart,\ I hope you like it #emoji.face.smile
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


#definition(
  "Stokes' theorem",
  footer: "Information extracted from a well-known public encyclopedia"
)[
  Let $Sigma$ be a smooth oriented surface in $RR^3$ with boundary $partial Sigma
  equiv Gamma$. If a vector field $iboxed(bold(F)(x,y,z))=(F_x (x,y,z), F_y (x,y,z),
  F_z (x,y,z))$ is defined and has continuous first order partial derivatives
  in a region containing $Sigma$, then

  $ integral.double_Sigma (bold(nabla) times bold(F)) dot bold(Sigma) =
  dboxed(integral.cont_(partial Sigma) bold(F) dot dif bold(Gamma)) $ 
]

#blockquote[
  这是引用内容。
  可以放多行文本。
]
/*
= RMCS部分算法分析
#include "chapters/algorithm/omni_wheel.typ"
#include "chapters/algorithm/steering_wheel.typ"

= 通讯架构分析
#include "chapters/communication/communication.typ"
*/