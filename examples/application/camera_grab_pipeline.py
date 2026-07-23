"""Vendor-neutral SDK grab pipeline and bounded recovery state flow.

The diagram separates a successful borrowed-buffer-to-owned-cv::Mat path from
error classification and threshold-based recovery.  Error classes, thresholds,
parameter names, and reopen behavior must be adapted to the camera SDK and
tested device.

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
box(6, 86, 30, 9, "initialize camera SDK", BLUE, BLUE_E, weight="bold")
box(6, 70, 30, 10, "enumerate devices + select serial\n(no match: report + backoff)", BLUE, BLUE_E, fs=9)
box(6, 54, 30, 9, "open selected device", BLUE, BLUE_E)
box(2, 34, 38, 15,
    "configure / reapply after reopen\n• lock validated exposure and gain\n"
    "• lock white balance  • set PixelFormat\n• set and read back trigger mode",
    BLUE, BLUE_E, fs=9)
box(6, 20, 30, 9, "start acquisition", GREEN, GREEN_E, weight="bold")

arrow(21, 86, 21, 80)
# self loop on enumerate (left side, curved)
ax.add_patch(FancyArrowPatch((6, 73), (6, 77), connectionstyle="arc3,rad=-1.1",
             color=GREY_E, arrowstyle="-|>", mutation_scale=12, lw=1.3))
ax.text(-3.6, 75, "no device\nbackoff", ha="center", va="center", fontsize=7.5, color=GREY_E)
arrow(21, 70, 21, 63)
arrow(21, 54, 21, 49)
arrow(21, 34, 21, 29)

# ---- capture loop column (right) ----
box(58, 78, 36, 9, "capture thread loop", GREY, GREY_E, weight="bold")
box(58, 62, 36, 9, "get SDK image buffer (timeout)", GREEN, GREEN_E, fs=9)
box(58, 43, 40, 12,
    "validate pixel format + row stride\nborrowed Bayer → owned BGR\ncvtColor / SDK converter",
    GREEN, GREEN_E, fs=8.7)
box(60, 26, 36, 11,
    "return SDK buffer\npublish / enqueue owned cv::Mat\nfail_count = 0",
    GREEN, GREEN_E, fs=8.7)
box(58, 7, 40, 12,
    "classify + log SDK result\nexpected trigger wait → retry\nrecoverable error → fail_count++",
    RED, RED_E, fs=8.7)

# start -> capture loop
arrow(36, 24.5, 58, 82, color=GREEN_E)
arrow(76, 78, 76, 71)
# get image -> success down
arrow(76, 62, 76, 55, color=GREEN_E, text="ok", tx=4)
arrow(76, 43, 78, 37, color=GREEN_E)
# loop back to GetImage after publish
ax.add_patch(FancyArrowPatch((96, 31.5), (99, 31.5), color=GREEN_E, arrowstyle="-"))
ax.add_patch(FancyArrowPatch((99, 31.5), (99, 66.5), color=GREEN_E, arrowstyle="-"))
ax.add_patch(FancyArrowPatch((99, 66.5), (94, 66.5), color=GREEN_E, arrowstyle="-|>", mutation_scale=13))
ax.text(99.5, 49, "next\nframe", ha="left", va="center", fontsize=8, color=GREEN_E)
# get image -> fail branch (left/down to recover)
arrow(58, 63, 58, 19, color=RED_E, text="timeout /\nerror", tx=-5, ty=1)
# expected wait or recoverable error below threshold -> back to GetImage
ax.add_patch(FancyArrowPatch((58, 13), (50, 13), color=RED_E, arrowstyle="-"))
ax.add_patch(FancyArrowPatch((50, 13), (50, 66.5), color=RED_E, arrowstyle="-"))
ax.add_patch(FancyArrowPatch((50, 66.5), (58, 66.5), color=RED_E, arrowstyle="-|>", mutation_scale=13))
ax.text(48.5, 40, "wait / below threshold", ha="center", va="center",
        fontsize=8, color=RED_E, rotation=90)
# escalate after the configured error-duration or count threshold
box(58, -4, 40, 8,
    "threshold reached → Stop + Start\npersistent / fatal → reopen + reapply or report fault",
    "#fff4d6", "#b8860b", fs=8.0)
arrow(78, 7, 78, 4, color="#b8860b", text="escalate", tx=7)

ax.set_title("Example SDK-buffer-to-cv::Mat path with classified recovery\n"
             "green = owned frame path | red = classify before counting or escalating",
             fontsize=11, loc="center")

out = os.path.join(os.path.dirname(__file__), "..", "..",
                   "chapters", "4.Application", "images", "app-camera-grab-pipeline.png")
out = os.path.abspath(out)
os.makedirs(os.path.dirname(out), exist_ok=True)
fig.tight_layout()
fig.savefig(out, dpi=150, bbox_inches="tight")
print("wrote", out)
