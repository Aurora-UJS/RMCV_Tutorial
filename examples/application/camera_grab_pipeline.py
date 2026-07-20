"""SDK grab pipeline + auto-reconnect state flow for an industrial camera.

Draws the canonical path from SDK init to a cv::Mat, plus the capture-thread
loop with its failure -> stop/start recovery branch.  The structure follows
the common Daheng/Galaxy ROS2 driver pattern (MIT/Apache): a blocking enumerate
loop until a camera appears, an explicit "turn OFF auto-exposure/gain then set
fixed values" step, Bayer demosaic on every frame, and a bounded reconnect that
gives up after N consecutive failures.

Output: chapters/4.Application/images/app-camera-grab-pipeline.png
"""
import os
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

fig, ax = plt.subplots(figsize=(9.6, 7.0))
ax.set_xlim(-4, 100)
ax.set_ylim(-8, 102)
ax.axis("off")

BLUE = "#e8f0fb"; BLUE_E = "#1f5fa8"
GREEN = "#e6f4ea"; GREEN_E = "#1e7d3a"
RED = "#fbe9e7"; RED_E = "#c0392b"
GREY = "#eeeeee"; GREY_E = "#555555"


def box(x, y, w, h, text, fc, ec, fs=10, weight="normal"):
    ax.add_patch(FancyBboxPatch((x, y), w, h,
                 boxstyle="round,pad=0.6,rounding_size=2",
                 fc=fc, ec=ec, lw=1.6))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            fontsize=fs, color="#111111", weight=weight, zorder=5)


def arrow(x1, y1, x2, y2, color="#333333", text=None, tx=0, ty=0, ls="-"):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2),
                 arrowstyle="-|>", mutation_scale=15, lw=1.6, color=color,
                 linestyle=ls, shrinkA=1, shrinkB=1))
    if text:
        ax.text((x1 + x2) / 2 + tx, (y1 + y2) / 2 + ty, text,
                ha="center", va="center", fontsize=8.5, color=color)


# ---- setup column (left) ----
box(6, 86, 30, 9, "GXInitLib()\ninit SDK", BLUE, BLUE_E, weight="bold")
box(6, 70, 30, 10, "enumerate devices\n(block until found)", BLUE, BLUE_E)
box(6, 54, 30, 9, "open by index / SN", BLUE, BLUE_E)
box(2, 34, 38, 15,
    "configure once\n• auto-exposure/gain OFF, set fixed\n"
    "• white balance  • PixelFormat=BayerRG8\n• trigger mode (free-run / hard)",
    BLUE, BLUE_E, fs=9)
box(6, 20, 30, 9, "AcquisitionStart", GREEN, GREEN_E, weight="bold")

arrow(21, 86, 21, 80)
# self loop on enumerate (left side, curved)
ax.add_patch(FancyArrowPatch((6, 73), (6, 77), connectionstyle="arc3,rad=-1.1",
             color=GREY_E, arrowstyle="-|>", mutation_scale=12, lw=1.3))
ax.text(-3.6, 75, "no cam\nwait 1s", ha="center", va="center", fontsize=7.5, color=GREY_E)
arrow(21, 70, 21, 63)
arrow(21, 54, 21, 49)
arrow(21, 34, 21, 29)

# ---- capture loop column (right) ----
box(58, 78, 36, 9, "capture thread loop", GREY, GREY_E, weight="bold")
box(58, 62, 36, 9, "GXGetImage(timeout)", GREEN, GREEN_E)
box(58, 44, 40, 11,
    "Bayer → BGR demosaic\nDxRaw8toRGB24 / cvtColor", GREEN, GREEN_E, fs=9)
box(60, 28, 36, 9, "publish  →  cv::Mat\nfail_count = 0", GREEN, GREEN_E, fs=9)
box(58, 8, 40, 10,
    "AcquisitionStop + Start\nfail_count++   (soft recover)", RED, RED_E, fs=9)

# start -> capture loop
arrow(36, 24.5, 58, 82, color=GREEN_E)
arrow(76, 78, 76, 71)
# get image -> success down
arrow(76, 62, 76, 55, color=GREEN_E, text="ok", tx=4)
arrow(76, 44, 78, 37, color=GREEN_E)
# loop back to GetImage after publish
ax.add_patch(FancyArrowPatch((96, 32.5), (99, 32.5), color=GREEN_E, arrowstyle="-"))
ax.add_patch(FancyArrowPatch((99, 32.5), (99, 66.5), color=GREEN_E, arrowstyle="-"))
ax.add_patch(FancyArrowPatch((99, 66.5), (94, 66.5), color=GREEN_E, arrowstyle="-|>", mutation_scale=13))
ax.text(99.5, 49, "next\nframe", ha="left", va="center", fontsize=8, color=GREEN_E)
# get image -> fail branch (left/down to recover)
arrow(58, 63, 52, 18, color=RED_E, text="timeout /\nfail", tx=-4, ty=6)
# recover -> back to GetImage
ax.add_patch(FancyArrowPatch((58, 13), (50, 13), color=RED_E, arrowstyle="-"))
ax.add_patch(FancyArrowPatch((50, 13), (50, 66.5), color=RED_E, arrowstyle="-"))
ax.add_patch(FancyArrowPatch((50, 66.5), (58, 66.5), color=RED_E, arrowstyle="-|>", mutation_scale=13))
ax.text(48.5, 40, "retry", ha="center", va="center", fontsize=8, color=RED_E, rotation=90)
# give up
box(58, -2, 40, 7, "fail_count > N  →  shutdown / reopen", "#fff4d6", "#b8860b", fs=8.5)
arrow(78, 8, 78, 5, color="#b8860b")

ax.set_title("From SDK to cv::Mat: the grab pipeline and its bounded auto-reconnect\n"
             "green = happy path (one frame in, one cv::Mat out) | red = a dropped frame "
             "self-heals via stop/start; only N-in-a-row escalates",
             fontsize=11, loc="center")

out = os.path.join(os.path.dirname(__file__), "..", "..",
                   "chapters", "4.Application", "images", "app-camera-grab-pipeline.png")
out = os.path.abspath(out)
os.makedirs(os.path.dirname(out), exist_ok=True)
fig.tight_layout()
fig.savefig(out, dpi=150, bbox_inches="tight")
print("wrote", out)
