# 图：二值化阈值的敏感性——阈值扫描下灯条候选与装甲板配对的数量
# 复用基础篇/理论篇同一段流水线（examples/theory/dl_mlp_dissect.py 的提取逻辑），
# 对 examples/test.mp4 的同一帧（7.0 s，与 mlp 拆解图同源）扫描 binary_thres：
#   - 统计通过几何判据的“灯条候选”数与通过简化配对判据的“装甲板对”数；
#   - 为隔离阈值影响，不执行颜色投票、第三灯条否决和数字分类；
#   - 展示低阈值会保留更多背景、高阈值会丢失灯条候选，并标出
#     代码默认 160 与实战 yaml 80 两个取值。
# 产出：chapters/4.Application/images/app-armor-binary-sweep.png
import cv2
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def find_lights(gray, thres):
    """按基础篇 C++ 判据在给定阈值下找灯条候选，返回灯条列表。"""
    _, binary = cv2.threshold(gray, thres, 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    n_contour = 0
    lights = []
    for c in contours:
        if len(c) < 5:
            continue
        n_contour += 1
        pts = sorted(cv2.boxPoints(cv2.minAreaRect(c)), key=lambda p: p[1])
        top, bottom = (pts[0] + pts[1]) / 2, (pts[2] + pts[3]) / 2
        length = np.linalg.norm(top - bottom)
        width = np.linalg.norm(pts[0] - pts[1])
        if length < 1e-3:
            continue
        ratio = width / length
        tilt = np.degrees(np.arctan2(abs(top[0] - bottom[0]), abs(top[1] - bottom[1])))
        if not (0.1 < ratio < 0.4 and tilt < 40):
            continue
        lights.append(dict(top=top, bottom=bottom, center=(top + bottom) / 2, length=length))
    return n_contour, lights


def count_armors(lights):
    """按基础篇配对判据统计装甲板对数（不分颜色，纯几何）。"""
    n = 0
    for i in range(len(lights)):
        for j in range(i + 1, len(lights)):
            a, b = lights[i], lights[j]
            if min(a["length"], b["length"]) / max(a["length"], b["length"]) < 0.7:
                continue
            avg = (a["length"] + b["length"]) / 2
            dist = np.linalg.norm(a["center"] - b["center"]) / avg
            if not (0.8 <= dist < 5.5):
                continue
            d = a["center"] - b["center"]
            if abs(np.degrees(np.arctan(d[1] / (d[0] + 1e-9)))) >= 35:
                continue
            n += 1
    return n


cap = cv2.VideoCapture(str(REPO / "examples" / "test.mp4"))
cap.set(cv2.CAP_PROP_POS_MSEC, 7000)
ok, frame = cap.read()
assert ok, "无法读取测试帧"
gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

thresholds = np.arange(30, 251, 5)
n_contours, n_lights, n_armors = [], [], []
for t in thresholds:
    nc, lights = find_lights(gray, int(t))
    n_contours.append(nc)
    n_lights.append(len(lights))
    n_armors.append(count_armors(lights))

fig, ax = plt.subplots(figsize=(9.2, 4.6))
ax.plot(thresholds, n_contours, color="#B0B0B0", lw=1.6, ls=":",
        label="raw white blobs (contours >= 5 pts)")
ax.plot(thresholds, n_lights, color="#1f6fb2", lw=2.6,
        label="light candidates (pass geometry)")
ax.plot(thresholds, n_armors, color="#e07b00", lw=2.6, marker="o", ms=3,
        label="armor pairs (pass matching)")

# 两个参考阈值
for x, txt, col in [(80, "field yaml = 80", "#c02020"), (160, "code default = 160", "#2a7a2a")]:
    ax.axvline(x, color=col, lw=1.4, ls="--", alpha=0.8)
    ax.text(x, ax.get_ylim()[1] * 0.02, f" {txt}", color=col, rotation=90,
            va="bottom", ha="right", fontsize=8.5)

ax.set_xlabel("binary_thres (gray level)")
ax.set_ylabel("count on one frame")
ax.set_title("Binarization threshold sweep on one ordinary-exposure frame\n"
             "lower thresholds retain more background; higher thresholds can remove light candidates",
             fontsize=11)
ax.set_xlim(30, 250)
ax.set_ylim(bottom=0)
ax.grid(alpha=0.25)
ax.legend(loc="upper right", fontsize=8.5, framealpha=0.9)
fig.tight_layout()
out = REPO / "chapters" / "4.Application" / "images" / "app-armor-binary-sweep.png"
fig.savefig(out, dpi=150)
print("saved", out)

# 打印关键点的真实数字，供正文引用
for t in [60, 80, 120, 160, 200, 220]:
    nc, lights = find_lights(gray, t)
    print(f"thres={t:3d}  contours={nc:4d}  lights={len(lights):3d}  armors={count_armors(lights)}")
