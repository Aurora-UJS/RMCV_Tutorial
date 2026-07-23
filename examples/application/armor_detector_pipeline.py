# 图：上场级装甲板识别器的两条工程路线与统一接口
# 教学点：无论走"传统级联"还是"CNN 四点回归"，识别器最终都交出同一样东西——
#   类别 + 按约定排序的四个像素点 → PnP(IPPE) → 类别 + 相机系位姿，再送给跟踪器。
# 参数活在配置文件里（顶栏），鲁棒性工程贴在流水线下方（底栏）。
# 纯示意图（matplotlib patch 手绘布局），不依赖任何外部数据，可复现。
# 产出：chapters/4.Application/images/app-armor-detector-pipeline.png
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from pathlib import Path

C_TRAD = "#1f6fb2"   # 传统路线蓝
C_CNN = "#7a4fb5"    # CNN 路线紫
C_SHARE = "#e07b00"  # 共用接口橙
C_IO = "#444444"     # 输入输出灰
C_PARAM = "#2a7a2a"  # 参数绿
C_ROBUST = "#c02020" # 鲁棒性红

fig, ax = plt.subplots(figsize=(10.2, 5.4))
ax.set_xlim(0, 100)
ax.set_ylim(0, 100)
ax.axis("off")


def box(x, y, w, h, text, edge, face="white", fs=8.6, tw="normal"):
    ax.add_patch(FancyBboxPatch(
        (x, y), w, h, boxstyle="round,pad=0.4,rounding_size=2.2",
        linewidth=1.7, edgecolor=edge, facecolor=face))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            fontsize=fs, color="#111111", fontweight=tw)


def arrow(x1, y1, x2, y2, color="#555555"):
    ax.add_patch(FancyArrowPatch(
        (x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=13,
        linewidth=1.6, color=color, shrinkA=1, shrinkB=1))


# ---- 输入 ----
box(1.5, 45, 13, 14, "image frame\n+ camera_info\n(camera module)", C_IO,
    face="#f0f0f0")

# ---- 传统级联路线（上车道）----
ax.text(17, 90, "Traditional cascade route  (CPU, reported 1-3 ms)",
        fontsize=9.5, color=C_TRAD, fontweight="bold")
tw, th, ty = 15.5, 12, 70
box(17, ty, tw, th, "threshold\n(binarize)", C_TRAD)
box(35.5, ty, tw, th, "findLights\ngeometry + color vote", C_TRAD)
box(54, ty, tw, th, "matchLights\npair by geometry", C_TRAD)
box(72.5, ty, 14.5, th, "MLP classify\n20x28, softmax", C_TRAD)
arrow(32.5, ty + th / 2, 35.5, ty + th / 2, C_TRAD)
arrow(51, ty + th / 2, 54, ty + th / 2, C_TRAD)
arrow(69.5, ty + th / 2, 72.5, ty + th / 2, C_TRAD)

# ---- CNN 四点路线（下车道）----
ax.text(17, 8.5, "CNN keypoint route  (accelerator, reported 5.5-6 ms)",
        fontsize=9.5, color=C_CNN, fontweight="bold")
by = 16
box(17, by, 33.5, th, "YOLO four-point net\n(OpenVINO, LATENCY mode)", C_CNN)
box(54, by, 20, th, "order 4 keypoints\nto match the 3D model", C_CNN)
arrow(50.5, by + th / 2, 54, by + th / 2, C_CNN)

# 输入 → 两条路线
arrow(14.5, 55, 17, ty + th / 2, C_IO)
arrow(14.5, 49, 17, by + th / 2, C_IO)

# ---- 统一接口：四点 → PnP → 位姿 ----
sx, sy, sw, sh = 76.5, 43, 22, 18
box(sx, sy, sw, sh, "class + 4 ordered points\nPnP (IPPE)\nclass + camera-frame pose",
    C_SHARE, face="#fff4e6", fs=8.4, tw="bold")
# 两条路线汇入接口（漏斗）
arrow(87, ty, sx + sw / 2, sy + sh, C_TRAD)          # 传统路线末端 ↘
arrow(74, by + th, sx + 4, sy, C_CNN)                # CNN 路线末端 ↗

# ---- 输出 → tracker ----
ax.annotate("armors (class + type + pose)\n=> tracker  (next chapter)",
            xy=(93, 41), xytext=(93, 32.5), ha="center", va="top",
            fontsize=8.8, color=C_IO, fontweight="bold")
arrow(93, 43, 93, 39.5)

# ---- 顶栏：参数配置化 ----
ax.add_patch(FancyBboxPatch((16.5, 84.5), 71, 3.4,
             boxstyle="round,pad=0.2,rounding_size=1.5",
             linewidth=0, facecolor="#e8f3e8"))
ax.text(52, 86.2,
        "Parameters live in config (yaml), NOT in code: binary_thres, "
        "light/armor ratios, classifier threshold - retuned per imaging domain",
        ha="center", va="center", fontsize=8.0, color=C_PARAM, style="italic")

# ---- 底栏：鲁棒性工程 ----
ax.add_patch(FancyBboxPatch((16.5, 2.0), 71, 3.4,
             boxstyle="round,pad=0.2,rounding_size=1.5",
             linewidth=0, facecolor="#fbeaea"))
ax.text(52, 3.7,
        "Robustness checks: dedup shared lightbars . negative class . "
        "type/name consistency . half-lit & extinguished lights . multi-target select",
        ha="center", va="center", fontsize=8.0, color=C_ROBUST, style="italic")

ax.set_title(
    "Two detection routes, one contract: class + ordered points -> PnP -> class + pose",
    fontsize=11, pad=10)
fig.tight_layout()
repo = Path(__file__).resolve().parents[2]
out = repo / "chapters" / "4.Application" / "images" / "app-armor-detector-pipeline.png"
fig.savefig(out, dpi=150, bbox_inches="tight")
print("saved", out)
