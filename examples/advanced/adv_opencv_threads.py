#!/usr/bin/env python3
"""OpenCV 线程数扫描：同时比较墙上时间与聚合 CPU 时间。

产出 chapters/5.Advanced/images/adv-perf-opencv-threads.png。

数据来源：一份遗留的本地汇总记录，负载注明为 cvtColor + GaussianBlur +
threshold（1280x1024），环境注明为 g++ 13.3.0 / OpenCV 4.6.0（TBB）/
Intel i7-13790F（16C24T，P/E 异构）/ Linux 7.0.0-28。仓库没有保留采样
程序、原始样本、样本量、统计量定义或“聚合 CPU 时间”的具体计时接口。
本脚本只负责重绘 DATA，不能重新采样；若要复测，应另写基准并替换整组记录。

注意 24 是本机 cv::getNumThreads() 的返回值，即"不设置"的测试档。
4 是供整机联合负载继续复测的本机候选，不是跨平台推荐值。

配色沿用全书：蓝 #3B6FD4、品红 #D6336C、灰 #8A8A8A。
"""
from pathlib import Path

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 10, "axes.linewidth": 0.8})

OUT = (Path(__file__).resolve().parents[2]
       / "chapters" / "5.Advanced" / "images" / "adv-perf-opencv-threads.png")

# threads, wall ms, CPU ms  （加速比与并行效率由此算出，不另填，避免两处不一致）
DATA = np.array([
    [1,  0.838, 0.911],
    [2,  0.422, 0.872],
    [4,  0.238, 1.060],
    [8,  0.249, 2.040],
    [24, 0.188, 3.570],
])
th, wall, cpu = DATA[:, 0], DATA[:, 1], DATA[:, 2]
speedup = wall[0] / wall
eff = speedup / th

CANDIDATE, LOCAL_DEFAULT = 4, 24
x = np.arange(len(th))

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12.6, 4.8))

# ---------------- 左：墙上时间 vs CPU 时间 ----------------
ax1.fill_between(x, wall, cpu, color=MAGENTA, alpha=0.10, zorder=1,
                 label="difference between CPU and wall time")
ax1.plot(x, wall, color=BLUE, lw=2.6, marker="o", ms=7, mec="white", mew=1.2,
         label="wall time", zorder=3)
ax1.plot(x, cpu, color=MAGENTA, lw=2.6, marker="s", ms=7, mec="white", mew=1.2,
         label="aggregate CPU time", zorder=3)

for xi, w, c in zip(x, wall, cpu):
    ax1.annotate(f"{w:.3f}", (xi, w), xytext=(0, -15), textcoords="offset points",
                 ha="center", fontsize=8, color=BLUE)
    ax1.annotate(f"{c:.3f}", (xi, c), xytext=(0, 8), textcoords="offset points",
                 ha="center", fontsize=8, color=MAGENTA)

i_rec, i_def = list(th).index(CANDIDATE), list(th).index(LOCAL_DEFAULT)
ax1.axvline(i_rec, color=BLUE, ls="-", lw=1.1, alpha=0.55, zorder=0)
ax1.axvline(i_def, color=GRAY, ls="--", lw=1.3, alpha=0.9, zorder=0)
ax1.text(i_rec - 0.08, 2.35, "candidate to remeasure\nsetNumThreads(4)", color=BLUE,
         fontsize=8.5, va="top", ha="right")
ax1.text(i_def - 0.10, 3.95, "retained default value\n24 threads", color=GRAY,
         fontsize=8.5, va="top", ha="right")

ax1.annotate(f"4 -> 24 threads:  wall -{(1 - wall[i_def]/wall[i_rec])*100:.0f}%,"
             f"  CPU x{cpu[i_def]/cpu[i_rec]:.1f}",
             xy=(i_def - 0.05, cpu[i_def] - 0.12), xytext=(1.30, 2.55),
             fontsize=9.5, fontweight="bold", color=MAGENTA,
             arrowprops=dict(arrowstyle="->", color=MAGENTA, lw=1.3))

ax1.set_xticks(x)
ax1.set_xticklabels([int(t) for t in th])
ax1.set_xlabel("cv::setNumThreads(n)")
ax1.set_ylabel("time per pre-processing pass (ms)")
ax1.set_ylim(-0.22, 4.15)
ax1.grid(axis="y", ls=":", lw=0.6, color=GRAY, alpha=0.55)
ax1.set_axisbelow(True)
for s in ("top", "right"):
    ax1.spines[s].set_visible(False)
ax1.legend(loc="upper left", frameon=False, fontsize=9)
ax1.set_title("(a) wall and aggregate CPU time in the retained record",
              fontsize=10.5, loc="left")

# ---------------- 右：加速比与并行效率 ----------------
ax2.plot(x, speedup, color=BLUE, lw=2.6, marker="o", ms=7, mec="white", mew=1.2,
         label="speed-up (x), left axis", zorder=3)
ax2.set_ylim(0, 6.2)
ax2.set_ylabel("speed-up (x)", color=BLUE)
ax2.tick_params(axis="y", colors=BLUE)

ax2b = ax2.twinx()
ax2b.bar(x, eff * 100, width=0.42, color=MAGENTA, alpha=0.28, zorder=0,
         label="parallel efficiency (%), right axis")
ax2b.set_ylim(0, 128)
ax2b.set_ylabel("parallel efficiency (%)", color=MAGENTA)
ax2b.tick_params(axis="y", colors=MAGENTA)
ax2b.spines["top"].set_visible(False)
for xi, e in zip(x, eff):
    ax2b.annotate(f"{e*100:.0f}%", (xi, e * 100), xytext=(0, 3),
                  textcoords="offset points", ha="center", fontsize=8.5,
                  color=MAGENTA)

ax2.annotate("4 to 8 in the retained record:\nsimilar wall time, CPU time about 1.9x",
             xy=(3, speedup[3] + 0.12), xytext=(1.05, 5.35), fontsize=9, color="k",
             arrowprops=dict(arrowstyle="->", color="k", lw=1.1))

ax2.set_xticks(x)
ax2.set_xticklabels([int(t) for t in th])
ax2.set_xlabel("cv::setNumThreads(n)")
ax2.grid(axis="y", ls=":", lw=0.6, color=GRAY, alpha=0.55)
ax2.set_axisbelow(True)
for s in ("top",):
    ax2.spines[s].set_visible(False)
h1, l1 = ax2.get_legend_handles_labels()
h2, l2 = ax2b.get_legend_handles_labels()
ax2.legend(h1 + h2, l1 + l2, loc="lower left", frameon=False, fontsize=8.5)
ax2.set_title("(b) speed-up and derived parallel efficiency",
              fontsize=10.5, loc="left")

fig.suptitle("Retained OpenCV thread-scan summary for one workload",
             fontsize=12.5, fontweight="bold", x=0.012, ha="left", y=0.995)
fig.tight_layout(rect=(0, 0, 1, 0.93))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=150, metadata={"Software": "Matplotlib"})
plt.close(fig)
print("wrote", OUT)
