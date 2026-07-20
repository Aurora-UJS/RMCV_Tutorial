#!/usr/bin/env python3
"""端到端延迟预算的两个面：各环节的量级区间，以及抖动折算成的落点误差。

产出 chapters/5.Advanced/images/adv-perf-latency-budget.png。

数据来源（必须随图一起进书，不得含糊）：
  左图各环节的量级区间有三个来源，脚本里逐条标了 src 字段：
    "cite"  —— 引自本书实战技术篇「弹道解算」一章的延迟预算表（量级，非本次实测）；
    "meas"  —— 本次实测（环境：g++ 13.3.0 / OpenCV 4.6.0 / ROS 2 Jazzy /
               i7-13790F 16C24T / 内核 7.0.0-28）；
    "deriv" —— 按物理关系推导（排队等待 = (D-1) 个帧间隔，D=5、100 fps）；
    "ext"   —— 外部公开测量（Jetson Orin NX + YOLOv8n 640 FP16，arXiv:2502.15737）。
  右图是纯推导：e = v * sigma，不是实测落点散布。装甲板半宽取小装甲 135 mm 的一半。

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
# owner: "vision" 视觉侧能动 / "ec" 电控与机械 / "phys" 被建模的物理量
STAGES = [
    ("Exposure",            0.5,  10.0, "vision", "cite"),
    ("Transfer + driver",   1.0,   5.0, "vision", "cite"),
    ("Queueing (D=5)",      0.0,  40.0, "vision", "deriv"),
    ("Pre-processing",      0.24,  0.84, "vision", "meas"),
    ("Inference (FP16)",   15.0,  20.0, "vision", "ext"),
    ("PnP + filter",        0.5,   1.5, "vision", "cite"),
    ("Node-to-node",        0.0016, 0.379, "vision", "meas"),
    ("Pack + serial",       3.0,  15.0, "vision", "cite"),
    ("Gimbal response",    20.0,  60.0, "ec",     "cite"),
    ("Feeder dead time",   60.0, 150.0, "ec",     "cite"),
    ("Bullet flight",     100.0, 600.0, "phys",   "cite"),
]

COLOR = {"vision": BLUE, "ec": GRAY, "phys": MAGENTA}
SRC_TAG = {"cite": "cited", "meas": "measured", "deriv": "derived", "ext": "external"}

fig, (axL, axR) = plt.subplots(1, 2, figsize=(13.4, 5.2))

# ---------------- 左图：各环节量级区间（对数横轴） ----------------
ys = np.arange(len(STAGES))[::-1]
for y, (label, lo, hi, owner, src) in zip(ys, STAGES):
    lo_p = max(lo, 1e-3)                      # 对数轴上给 0 一个可画的下界
    axL.plot([lo_p, hi], [y, y], lw=7, color=COLOR[owner], alpha=0.45,
             solid_capstyle="butt", zorder=2)
    axL.plot([lo_p, hi], [y, y], lw=1.4, color=COLOR[owner], zorder=3)
    axL.plot([lo_p, hi], [y, y], ls="none", marker="|", ms=11,
             color=COLOR[owner], zorder=4)
    axL.text(hi * 1.35, y, SRC_TAG[src], va="center", ha="left",
             fontsize=7.5, color=GRAY, style="italic")

axL.set_yticks(ys)
axL.set_yticklabels([s[0] for s in STAGES])
axL.set_xscale("log")
axL.set_xlim(5e-4, 6e3)
axL.set_ylim(-0.8, len(STAGES) - 0.2)
axL.set_xlabel("latency magnitude (ms, log scale)")
axL.grid(axis="x", ls=":", lw=0.6, color=GRAY, alpha=0.55)
axL.set_axisbelow(True)
for s in ("top", "right"):
    axL.spines[s].set_visible(False)
axL.set_title("(a) where the milliseconds live\nbar length = uncertainty: the longer, the harder to fold into a constant",
              fontsize=10, loc="left")
axL.legend(handles=[
    Line2D([], [], color=BLUE, lw=5, alpha=0.6, label="vision side (yours to cut)"),
    Line2D([], [], color=GRAY, lw=5, alpha=0.6, label="EC / mechanical"),
    Line2D([], [], color=MAGENTA, lw=5, alpha=0.6, label="modelled physics"),
], loc="upper left", frameon=False, fontsize=8, bbox_to_anchor=(0.0, 0.30))

# ---------------- 右图：抖动折算落点误差 e = v * sigma ----------------
sigma = np.linspace(0, 60, 400)               # ms
ARMOR_HALF = 67.5                             # mm，小装甲板 135 mm 的一半
SPEEDS = [(1.0, GRAY, "1.0 m/s  (slow strafe)"),
          (2.5, BLUE, "2.5 m/s  (spin 10 rad/s, r=0.25 m)"),
          (6.0, MAGENTA, "6.0 m/s  (spin 24 rad/s, r=0.25 m)")]

for v, c, lab in SPEEDS:
    axR.plot(sigma, v * sigma, color=c, lw=2.2, label=lab)   # v[m/s]*sigma[ms] = mm
    budget = ARMOR_HALF / v
    if budget <= sigma[-1]:
        axR.plot([budget], [ARMOR_HALF], marker="o", ms=7, color=c,
                 mec="white", mew=1.2, zorder=5)
        axR.annotate(f"{budget:.0f} ms", xy=(budget, ARMOR_HALF),
                     xytext=(budget + 1.5, ARMOR_HALF + 22),
                     color=c, fontsize=9, fontweight="bold",
                     arrowprops=dict(arrowstyle="-", color=c, lw=0.9))

axR.axhline(ARMOR_HALF, ls="--", lw=1.3, color="k", alpha=0.75)
axR.text(59, ARMOR_HALF + 6, "half armour width  67.5 mm", ha="right",
         fontsize=8.5, color="k")
axR.axhspan(0, ARMOR_HALF, color=BLUE, alpha=0.05)

axR.set_xlim(0, 60)
axR.set_ylim(0, 300)
axR.set_xlabel(r"un-compensated jitter  $\sigma$  (ms)")
axR.set_ylabel(r"residual miss  $e = v\,\sigma$  (mm)")
axR.grid(ls=":", lw=0.6, color=GRAY, alpha=0.55)
axR.set_axisbelow(True)
for s in ("top", "right"):
    axR.spines[s].set_visible(False)
axR.set_title("(b) jitter is what compensation cannot absorb\nread it: pick a target speed, the dot is your jitter budget  (derived)",
              fontsize=10, loc="left")
axR.legend(loc="upper left", frameon=False, fontsize=8.5)

fig.suptitle("Latency budget for COMPRESSION: mean is compensable, jitter is not",
             fontsize=12.5, fontweight="bold", x=0.012, ha="left", y=0.995)
fig.tight_layout(rect=(0, 0, 1, 0.94))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=150)
print("wrote", OUT)
