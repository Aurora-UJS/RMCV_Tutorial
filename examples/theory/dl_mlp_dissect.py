# 图：拆解基础篇的 mlp.onnx 数字分类器——三个仓库视频候选的前向结果
# 复刻 examples/cpp/lightbar_pipeline.cpp 的提取流程（Python 版）：
# 从 examples/test.mp4 的 7.0 s 帧提取灯条候选并配对，把候选区域透视矫正
# 成 20x28 二值小图，喂给真实的 mlp.onnx，画出 9 类 softmax 概率。
# 产出：chapters/2.Theory/images/theory-dl-mlp-dissect.png
import cv2
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT = REPO_ROOT / "chapters/2.Theory/images/theory-dl-mlp-dissect.png"
NAMES = ["1", "2", "3", "4", "5", "outpost", "guard", "base", "negative"]

# --- 1) 取帧、二值化、找灯条（与基础篇 C++ 判据一致） ---
cap = cv2.VideoCapture(str(REPO_ROOT / "examples/test.mp4"))
cap.set(cv2.CAP_PROP_POS_MSEC, 7000)
ok, frame = cap.read()
assert ok
gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
_, binary = cv2.threshold(gray, 160, 255, cv2.THRESH_BINARY)
contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

lights = []
for c in contours:
    if len(c) < 5:
        continue
    pts = sorted(cv2.boxPoints(cv2.minAreaRect(c)), key=lambda p: p[1])
    top, bottom = (pts[0] + pts[1]) / 2, (pts[2] + pts[3]) / 2
    length = np.linalg.norm(top - bottom)
    width = np.linalg.norm(pts[0] - pts[1])
    if length < 8:
        continue
    ratio = width / length
    tilt = np.degrees(np.arctan2(abs(top[0] - bottom[0]), abs(top[1] - bottom[1])))
    if not (0.1 < ratio < 0.4 and tilt < 40):
        continue
    mask = np.zeros(gray.shape, np.uint8)
    cv2.drawContours(mask, [c], -1, 255, -1)
    color = "BLUE" if frame[:, :, 0][mask > 0].sum() > frame[:, :, 2][mask > 0].sum() else "RED"
    lights.append(dict(top=top, bottom=bottom, center=(top + bottom) / 2,
                       length=length, color=color))

# --- 2) 蓝色灯条两两配对（敌方为蓝） ---
blues = [l for l in lights if l["color"] == "BLUE"]
cands = []
for i in range(len(blues)):
    for j in range(i + 1, len(blues)):
        a, b = blues[i], blues[j]
        if min(a["length"], b["length"]) / max(a["length"], b["length"]) < 0.7:
            continue
        avg = (a["length"] + b["length"]) / 2
        dist = np.linalg.norm(a["center"] - b["center"]) / avg
        small, large = 0.8 <= dist < 3.2, 3.2 <= dist < 5.5
        if not (small or large):
            continue
        d = a["center"] - b["center"]
        if abs(np.degrees(np.arctan(d[1] / d[0]))) >= 35:
            continue
        left, right = (a, b) if a["center"][0] < b["center"][0] else (b, a)
        cands.append((left, right, "SMALL" if small else "LARGE"))

# --- 3) 透视矫正成 20x28 二值图，跑真实的 mlp.onnx ---
net = cv2.dnn.readNetFromONNX(str(REPO_ROOT / "examples/cpp/model/mlp.onnx"))
results = []
for left, right, typ in cands:
    light_len, warp_h = 12, 28
    warp_w = 32 if typ == "SMALL" else 54
    top_y = (warp_h - light_len) // 2 - 1
    bottom_y = top_y + light_len
    src = np.float32([left["bottom"], left["top"], right["top"], right["bottom"]])
    dst = np.float32([[0, bottom_y], [0, top_y],
                      [warp_w - 1, top_y], [warp_w - 1, bottom_y]])
    num = cv2.warpPerspective(frame, cv2.getPerspectiveTransform(src, dst),
                              (warp_w, warp_h))
    num = num[:, (warp_w - 20) // 2:(warp_w - 20) // 2 + 20]
    num = cv2.cvtColor(num, cv2.COLOR_BGR2GRAY)
    _, num = cv2.threshold(num, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)
    net.setInput(cv2.dnn.blobFromImage((num / 255.0).astype(np.float32)))
    out = net.forward().flatten()
    p = np.exp(out - out.max())          # 数值稳定的 softmax，与 C++ 版一致
    p /= p.sum()
    results.append((num, p))
    print(f"-> {NAMES[p.argmax()]} {p.max() * 100:.1f}%")

# 选三个有代表性的候选：哨兵图案、数字 3、负样本（杂光配对）
order = []
for want in ["guard", "3", "negative"]:
    for k, (_, p) in enumerate(results):
        if NAMES[p.argmax()] == want and k not in order:
            order.append(k)
            break

# --- 4) 画图：上排输入小图，下排 9 类概率 ---
BLUE, GRAY = "#0072B2", "#c4c4c4"
fig, axes = plt.subplots(2, 3, figsize=(10, 5.2), dpi=150,
                         gridspec_kw=dict(height_ratios=[1.15, 1]))
for col, k in enumerate(order):
    num, p = results[k]
    win = int(p.argmax())
    ax = axes[0, col]
    ax.imshow(num, cmap="gray", interpolation="nearest")
    ax.set_title(f"input {num.shape[1]}$\\times${num.shape[0]} binary", fontsize=10)
    ax.set_xticks([])
    ax.set_yticks([])

    ax = axes[1, col]
    colors = [BLUE if i == win else GRAY for i in range(9)]
    ax.bar(range(9), p, color=colors)
    ax.set_ylim(0, 1.12)
    ax.set_xticks(range(9))
    ax.set_xticklabels(NAMES, rotation=45, fontsize=7.5, ha="right")
    ax.text(win, p[win] + 0.03, f"{NAMES[win]}\n{p[win]:.1%}",
            ha="center", fontsize=9, color=BLUE)
    ax.set_yticks([0, 0.5, 1.0])
    ax.grid(axis="y", alpha=0.25, linewidth=0.5)
    if col == 0:
        ax.set_ylabel("softmax output", fontsize=9)
fig.suptitle("mlp.onnx outputs for three candidates from the repository video",
             fontsize=11.5)
fig.tight_layout(rect=[0, 0, 1, 0.97])
fig.savefig(OUTPUT, bbox_inches="tight")
print("saved")
