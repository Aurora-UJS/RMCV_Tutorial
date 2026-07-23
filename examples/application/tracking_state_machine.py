"""The tracker's four-state lifecycle and its confirmation/deletion counters.

Mirrors rm_auto_aim tracker.cpp::update() state machine:
  LOST -> DETECTING            first detection (init on armor closest to center)
  DETECTING -> TRACKING        matched for > tracking_thres consecutive frames
  DETECTING -> LOST            one miss (a flicker is not a target)
  TRACKING  -> TEMP_LOST       one miss (keep predicting without a measurement)
  TEMP_LOST -> TRACKING        matched again
  TEMP_LOST -> LOST            missed for > lost_thres frames

The diagram shows the intended transitions with both counters initialized to
zero. The inspected upstream constructor does not explicitly initialize them.

DETECTING delays confirmation of a new target. TEMP_LOST delays deletion of an
already confirmed track. During TEMP_LOST the EKF keeps running predict() and
the reference node still publishes tracking=true; downstream behavior depends
on the controller that consumes this flag.

Output: chapters/4.Application/images/app-tracking-state-machine.png
"""
import os
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

# node: name -> (x, y, face, edge)
NODES = {
    "LOST":      (0.0,  0.0, "#e9ecef", "#868e96"),
    "DETECTING": (3.2,  1.7, "#fff3bf", "#f08c00"),
    "TRACKING":  (7.4,  1.7, "#d3f9d8", "#2f9e44"),
    "TEMP_LOST": (7.4, -1.7, "#ffe8cc", "#e8590c"),
}
W, H = 2.05, 0.92

fig, ax = plt.subplots(figsize=(9.2, 5.2))
ax.set_xlim(-1.5, 9.9)
ax.set_ylim(-3.2, 3.3)
ax.axis("off")


def center(name):
    x, y, _, _ = NODES[name]
    return x, y


def draw_node(name):
    x, y, fc, ec = NODES[name]
    box = FancyBboxPatch((x - W / 2, y - H / 2), W, H,
                         boxstyle="round,pad=0.02,rounding_size=0.18",
                         linewidth=2.2, edgecolor=ec, facecolor=fc, zorder=3)
    ax.add_patch(box)
    ax.text(x, y, name, ha="center", va="center", fontsize=12.5,
            fontweight="bold", color="#212529", zorder=4)


def edge(a, b, label, rad=0.0, lx=0.0, ly=0.0, color="#495057",
         label_fs=9.2, va="center", ha="center"):
    (x0, y0), (x1, y1) = center(a), center(b)
    arr = FancyArrowPatch((x0, y0), (x1, y1),
                          connectionstyle=f"arc3,rad={rad}",
                          arrowstyle="-|>", mutation_scale=18,
                          shrinkA=34, shrinkB=34, lw=1.9, color=color, zorder=2)
    ax.add_patch(arr)
    mx, my = (x0 + x1) / 2 + lx, (y0 + y1) / 2 + ly
    ax.text(mx, my, label, ha=ha, va=va, fontsize=label_fs, color=color,
            zorder=5,
            bbox=dict(boxstyle="round,pad=0.22", fc="white", ec="none", alpha=0.9))


for n in NODES:
    draw_node(n)

# transitions
edge("LOST", "DETECTING", "first detection\n(init: armor nearest image center)",
     rad=0.12, lx=-0.2, ly=0.55, color="#f08c00")
edge("DETECTING", "TRACKING", "match count > tracking_thres\n(default 5)",
     rad=0.0, ly=0.5, color="#2f9e44")
edge("DETECTING", "LOST", "one miss\n(cancel unconfirmed track)",
     rad=0.28, lx=0.9, ly=-0.55, color="#868e96")
edge("TRACKING", "TEMP_LOST", "one miss\n(EKF keeps predicting)",
     rad=0.0, lx=1.35, ly=0.0, color="#e8590c", ha="left")
edge("TEMP_LOST", "TRACKING", "matched again\n(regain)",
     rad=0.28, lx=-1.5, ly=0.0, color="#2f9e44", ha="right")
edge("TEMP_LOST", "LOST", "missed > lost_thres frames\n(= configured lost_time_thres / dt)",
     rad=-0.16, lx=-0.1, ly=-0.7, color="#868e96")

# self loops (semantics note)
ax.annotate("matched:\nstay & correct", xy=(7.4, 1.7 + H / 2),
            xytext=(7.4, 3.05), ha="center", fontsize=8.6, color="#2f9e44",
            arrowprops=dict(arrowstyle="-|>", color="#2f9e44",
                            connectionstyle="arc3,rad=-0.5", shrinkB=2))

# Banner: which states set the track-valid flag in the reference node.
ax.text(3.7, -2.75,
        "publishes  tracking = true:  TRACKING  +  TEMP_LOST"
        "        |        tracking = false:  LOST  +  DETECTING",
        ha="center", va="center", fontsize=9.3, color="#212529",
        bbox=dict(boxstyle="round,pad=0.5", fc="#f1f3f5", ec="#ced4da"))

ax.set_title(
    "Tracker lifecycle: delayed confirmation and delayed deletion",
    fontsize=12.5, pad=12, color="#212529")

out = os.path.join(os.path.dirname(__file__), "..", "..",
                   "chapters", "4.Application", "images", "app-tracking-state-machine.png")
out = os.path.abspath(out)
fig.savefig(out, dpi=150, bbox_inches="tight")
print("saved", out)
