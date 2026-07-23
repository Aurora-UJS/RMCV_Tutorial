# Energy-rune geometry for the application chapter.
# The diagram shows five blades at 72 deg spacing, an example state assignment,
# and position hypotheses obtained by rotation about the estimated R center.
# Output: chapters/4.Application/images/app-rune-geometry.png
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle, Arc
from matplotlib.transforms import Affine2D
from pathlib import Path

# ---- palette (doc-wide: red = current target, orange = already hit, gray = unlit, ink = geometry)
RED = "#e34948"
ORANGE = "#e08a1e"
GRAY = "#9a9894"
INK = "#0b0b0b"
BLUE = "#2a78d6"
MUTED = "#52514e"

fig, ax = plt.subplots(figsize=(8.2, 8.2))
ax.set_aspect("equal")

R_ARM = 1.0          # R-center -> armor-center (blade radius), normalized
STRIP_IN = 0.30      # inner end of the flowing-arrow strip
ARM_W, ARM_H = 0.42, 0.26   # striking-armor frame size (tangential x radial)

# blade i sits at angle 90 + i*72 deg; state assignment for the snapshot
angles_deg = [90 + i * 72 for i in range(5)]
states = ["target", "shot", "unlit", "unlit", "shot"]
state_color = {"target": RED, "shot": ORANGE, "unlit": GRAY}
state_label = {"target": "target candidate", "shot": "activated", "unlit": "unlit"}

def draw_blade(ax, ang_deg, color, lit):
    a = np.deg2rad(ang_deg)
    ux, uy = np.cos(a), np.sin(a)           # outward radial unit vector
    # flowing-arrow strip (center spoke)
    ax.plot([STRIP_IN * ux, (R_ARM - ARM_H / 2) * ux],
            [STRIP_IN * uy, (R_ARM - ARM_H / 2) * uy],
            color=color, lw=3.2, solid_capstyle="round", zorder=3)
    # side light bars only appear once the blade is activated (lit)
    if lit:
        for s in (-1, 1):
            px, py = -uy, ux                # tangential unit vector
            off = 0.16
            ax.plot([(0.55) * ux + s * off * px, (R_ARM - ARM_H / 2) * ux + s * off * px],
                    [(0.55) * uy + s * off * py, (R_ARM - ARM_H / 2) * uy + s * off * py],
                    color=color, lw=2.0, alpha=0.9, solid_capstyle="round", zorder=3)
    # striking-armor frame at the blade tip
    cx, cy = R_ARM * ux, R_ARM * uy
    rect = Rectangle((-ARM_W / 2, -ARM_H / 2), ARM_W, ARM_H, fill=False,
                     edgecolor=color, lw=2.6, zorder=4)
    t = Affine2D().rotate_deg(ang_deg - 90).translate(cx, cy) + ax.transData
    rect.set_transform(t)
    ax.add_patch(rect)
    return cx, cy

target_c = None
for ang, st in zip(angles_deg, states):
    # side bars light up only AFTER a blade is hit -> only "shot" blades get them.
    # This example assumes three child contours after activation and one before.
    cx, cy = draw_blade(ax, ang, state_color[st], lit=(st == "shot"))
    if st == "target":
        target_c = (cx, cy)

# ---- R mark at the center
ax.scatter([0], [0], s=260, facecolor="none", edgecolor=INK, lw=2.2, zorder=5)
ax.text(0, 0, "R", ha="center", va="center", fontsize=13, fontweight="bold", zorder=6)
ax.text(0, -0.16, "center R mark", ha="center", va="top", fontsize=10, color=MUTED)

# ---- radius line R -> target armor center
tx, ty = target_c
ax.annotate("", xy=(tx, ty), xytext=(0, 0),
            arrowprops=dict(arrowstyle="-", color=INK, lw=1.4, ls=(0, (5, 3))), zorder=2)
mx, my = 0.5 * tx, 0.5 * ty
ax.text(mx - 0.05, my + 0.06, "r  (R -> armor center)", fontsize=10, color=INK,
        rotation=np.rad2deg(np.arctan2(ty, tx)), rotation_mode="anchor", ha="center")

# ---- 72 deg arc between the target and the next blade
a0 = np.deg2rad(angles_deg[0])
a1 = np.deg2rad(angles_deg[1])
arc = Arc((0, 0), 1.3, 1.3, angle=0, theta1=min(angles_deg[0], angles_deg[1]),
          theta2=max(angles_deg[0], angles_deg[1]), color=BLUE, lw=1.8)
ax.add_patch(arc)
amid = 0.5 * (a0 + a1)
ax.text(0.78 * np.cos(amid), 0.78 * np.sin(amid), "72 deg", color=BLUE, fontsize=11,
        ha="center", va="center", fontweight="bold")

# ---- rotation-direction curved arrow (outer ring)
ring = 1.62
arr = FancyArrowPatch((ring * np.cos(np.deg2rad(20)), ring * np.sin(np.deg2rad(20))),
                      (ring * np.cos(np.deg2rad(-35)), ring * np.sin(np.deg2rad(-35))),
                      connectionstyle="arc3,rad=0.32", arrowstyle="-|>", mutation_scale=18,
                      color=MUTED, lw=1.8)
ax.add_patch(arr)
ax.text(ring * np.cos(np.deg2rad(-8)) + 0.12, ring * np.sin(np.deg2rad(-8)),
        "image-plane rotation\n(sign depends on viewpoint and\nimage convention; estimate it\nfrom consecutive observations)",
        fontsize=9.5, color=MUTED, va="center")

# ---- "seed the others" annotation on the target arc
ax.annotate("from one detected blade,\nrotate +/-72 deg about R\nto propose the others",
            xy=(0.60 * np.cos(a0) - 0.10, 0.60 * np.sin(a0)),
            xytext=(-1.95, 1.02), fontsize=9.5, color=INK, ha="left", va="center",
            arrowprops=dict(arrowstyle="->", color=INK, lw=1.1))

# ---- the cue the hierarchy test actually counts: side bars present or not
a_t = np.deg2rad(angles_deg[0])          # target blade (red), points up
ax.annotate("example target state\n(1 child contour)",
            xy=(0.13, 0.72 * np.sin(a_t)), xytext=(0.62, 1.30),
            fontsize=9.5, color=RED, ha="left", va="center",
            arrowprops=dict(arrowstyle="->", color=RED, lw=1.1))
a_s = np.deg2rad(angles_deg[4])          # an activated blade (orange), lower right
ax.annotate("example activated state\n(3 child contours)",
            xy=(0.74 * np.cos(a_s), 0.74 * np.sin(a_s) - 0.16),
            xytext=(1.06, 0.98),
            fontsize=9.5, color=ORANGE, ha="left", va="center",
            arrowprops=dict(arrowstyle="->", color=ORANGE, lw=1.1))

# ---- legend by state
handles = [plt.Line2D([0], [0], color=state_color[s], lw=3.0, label=state_label[s])
           for s in ["target", "shot", "unlit"]]
ax.legend(handles=handles, loc="lower right", fontsize=9.5, frameon=True, framealpha=0.95)

ax.set_title("Energy-rune geometry: five blades at 72 deg around the R mark\n"
             "Estimate the target blade, center R, and image-plane radius r.",
             fontsize=12.5, pad=10)
ax.set_xlim(-2.05, 2.1)
ax.set_ylim(-1.7, 1.55)
ax.axis("off")

fig.tight_layout()
out = Path(__file__).resolve().parents[2] / "chapters/4.Application/images/app-rune-geometry.png"
out.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(out, dpi=150, bbox_inches="tight")
print("wrote", out)
