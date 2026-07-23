#!/usr/bin/env python3
"""端到端延迟预算的两个视图：各环节量级与残余时间误差。

产出 chapters/5.Advanced/images/adv-perf-latency-budget.png。

数据来源（必须随图一起进书，不得含糊）：
  左图只画有数值端点的行，脚本里逐条标了 src 字段：
    "prior"  —— 本书「弹道解算」一章给出的聚合量级，非本次实测；
    "record" —— 本章遗留的 OpenCV / ROS 2 汇总值，没有采样程序与原始样本；
    "ext"    —— 外部论文报告的 FP16 平均迭代时间（Jetson Orin NX、
                 YOLOv8n 640、TensorRT，arXiv:2502.15737）。
  区间可能跨线程设置、消息大小或通信路径，不能解释为逐帧抖动。排队、
  云台跟随与供弹缺少可通用的数值端点，所以只留在正文表格中。
  右图是纯推导：|e| = |v * delta_t|，不是实测落点散布。67.5 mm 是
  135 mm 参考跨度的一半，仅用作几何示例，不代表开火判据。

配色沿用全书：蓝 #3B6FD4、品红 #D6336C、灰 #8A8A8A。
"""
from pathlib import Path

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 9.5, "axes.linewidth": 0.8})

OUT = (Path(__file__).resolve().parents[2]
       / "chapters" / "5.Advanced" / "images" / "adv-perf-latency-budget.png")

# (标签, 下界 ms, 上界 ms, 归属, 来源)
# owner: "vision" 视觉与通信 / "phys" 被建模的物理量
STAGES = [
    ("Exposure reference -> image ready", 1.0, 20.0, "vision", "prior"),
    ("Pre-processing (retained rows)", 0.188, 0.838, "vision", "record"),
    ("Inference FP16 mean", 17.44, 17.44, "vision", "ext"),
    ("Node-to-node (retained rows)", 0.0008, 0.6756, "vision", "record"),
    ("Pack + serial", 2.0, 15.0, "vision", "prior"),
    ("Bullet flight", 100.0, 600.0, "phys", "prior"),
]

COLOR = {"vision": BLUE, "phys": MAGENTA}
SRC_TAG = {"prior": "prior chapter", "record": "retained record", "ext": "external mean"}

fig, (axL, axR) = plt.subplots(1, 2, figsize=(13.4, 5.2))

# ---------------- 左图：各环节量级区间（对数横轴） ----------------
ys = np.arange(len(STAGES))[::-1]
for y, (label, lo, hi, owner, src) in zip(ys, STAGES):
    axL.plot([lo, hi], [y, y], lw=7, color=COLOR[owner], alpha=0.45,
             solid_capstyle="butt", zorder=2)
    axL.plot([lo, hi], [y, y], lw=1.4, color=COLOR[owner], zorder=3)
    axL.plot([lo, hi], [y, y], ls="none", marker="|", ms=11,
             color=COLOR[owner], zorder=4)
    axL.text(hi * 1.35, y, SRC_TAG[src], va="center", ha="left",
             fontsize=7.5, color=GRAY, style="italic")

axL.set_yticks(ys)
axL.set_yticklabels([s[0] for s in STAGES])
axL.set_xscale("log")
axL.set_xlim(5e-4, 3e3)
axL.set_ylim(-0.8, len(STAGES) - 0.2)
axL.set_xlabel("latency magnitude (ms, log scale)")
axL.grid(axis="x", ls=":", lw=0.6, color=GRAY, alpha=0.55)
axL.set_axisbelow(True)
for s in ("top", "right"):
    axL.spines[s].set_visible(False)
axL.set_title("(a) selected time values with numeric endpoints\n"
              "range width is source scope, not frame-to-frame jitter",
              fontsize=10, loc="left")
axL.legend(handles=[
    Line2D([], [], color=BLUE, lw=5, alpha=0.6, label="vision and communication"),
    Line2D([], [], color=MAGENTA, lw=5, alpha=0.6, label="modelled flight time"),
], loc="lower left", frameon=False, fontsize=8)

# ---------------- 右图：残余时间误差折算位置误差 ----------------
delta_t = np.linspace(0, 60, 400)              # |delta_t|, ms
REFERENCE_HALF_SPAN = 67.5                    # mm，135 mm 参考跨度的一半
SPEEDS = [(1.0, GRAY, "1.0 m/s  (constant lateral speed)"),
          (2.5, BLUE, "2.5 m/s  (spin 10 rad/s, r=0.25 m)"),
          (6.0, MAGENTA, "6.0 m/s  (spin 24 rad/s, r=0.25 m)")]

for v, c, lab in SPEEDS:
    axR.plot(delta_t, v * delta_t, color=c, lw=2.2, label=lab)
    budget = REFERENCE_HALF_SPAN / v
    if budget <= delta_t[-1]:
        axR.plot([budget], [REFERENCE_HALF_SPAN], marker="o", ms=7, color=c,
                 mec="white", mew=1.2, zorder=5)
        axR.annotate(f"{budget:.0f} ms", xy=(budget, REFERENCE_HALF_SPAN),
                     xytext=(budget + 1.5, REFERENCE_HALF_SPAN + 22),
                     color=c, fontsize=9, fontweight="bold",
                     arrowprops=dict(arrowstyle="-", color=c, lw=0.9))

axR.axhline(REFERENCE_HALF_SPAN, ls="--", lw=1.3, color="k", alpha=0.75)
axR.text(59, REFERENCE_HALF_SPAN + 6, "half of 135 mm reference span", ha="right",
         fontsize=8.5, color="k")
axR.axhspan(0, REFERENCE_HALF_SPAN, color=BLUE, alpha=0.05)

axR.set_xlim(0, 60)
axR.set_ylim(0, 300)
axR.set_xlabel(r"residual time error  $|\delta t|$  (ms)")
axR.set_ylabel(r"first-order position error  $|e| = |v\,\delta t|$  (mm)")
axR.grid(ls=":", lw=0.6, color=GRAY, alpha=0.55)
axR.set_axisbelow(True)
for s in ("top", "right"):
    axR.spines[s].set_visible(False)
axR.set_title("(b) first-order conversion at constant lateral speed\n"
              "dots use a 67.5 mm illustrative tolerance",
              fontsize=10, loc="left")
axR.legend(loc="upper left", frameon=False, fontsize=8.5)

fig.suptitle("Selected time values and residual timing error",
             fontsize=12.5, fontweight="bold", x=0.012, ha="left", y=0.995)
fig.tight_layout(rect=(0, 0, 1, 0.94))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=150, metadata={"Software": "Matplotlib"})
plt.close(fig)
print("wrote", OUT)
