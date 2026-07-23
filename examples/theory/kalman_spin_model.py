# Whole-vehicle model figure for the target-tracking section:
# left  -- geometry: four armor plates rotating around the chassis center,
#          state (x_c, y_c, v, theta, omega, r), observation = one visible plate;
# right -- simulated armor and chassis-center trajectories under simultaneous
#          rotation and translation.
# Generates chapters/2.Theory/images/theory-kalman-spin-model.png
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
from matplotlib.patches import FancyArrowPatch

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(9.6, 4.6), dpi=150)

# ---------- left: simplified geometry at one instant ---------------------
mounting_radius = 0.26                   # one-radius model used in the text
half_w = 0.0675                          # small armor is 135 mm wide
th0 = np.deg2rad(-80)                    # plate 0 roughly faces the camera

for i in range(4):
    th = th0 + i * np.pi / 2
    r = mounting_radius
    n = np.array([np.cos(th), np.sin(th)])       # outward normal
    tang = np.array([-np.sin(th), np.cos(th)])
    c = r * n
    p0, p1 = c - half_w * tang, c + half_w * tang
    visible = n[1] < -0.3                        # facing the camera below
    ax1.plot([p0[0], p1[0]], [p0[1], p1[1]],
             color=BLUE if visible else GRAY, lw=5 if visible else 3,
             ls="-" if visible else (0, (3, 2)),
             solid_capstyle="round", zorder=4)

# chassis outline and center
ax1.add_patch(plt.Circle((0, 0), 0.245, fill=False, color=GRAY,
                         lw=0.8, ls=":"))
ax1.plot(0, 0, "o", color=MAGENTA, ms=7, zorder=5)
ax1.annotate("center $(x_c, y_c)$", (-0.07, 0.06), ha="right",
             color=MAGENTA, fontsize=10)

# radius r and angle theta of plate 0
n0 = np.array([np.cos(th0), np.sin(th0)])
ax1.plot([0, mounting_radius * n0[0]], [0, mounting_radius * n0[1]],
         color="black", lw=1.0)
ax1.annotate("$r$", (0.5 * mounting_radius * n0[0] - 0.06,
                     0.5 * mounting_radius * n0[1]),
             fontsize=11)
ax1.plot([0, 0.30], [0, 0], color=GRAY, lw=0.8, ls="--")
arc = np.linspace(th0, 0, 40)
ax1.plot(0.13 * np.cos(arc), 0.13 * np.sin(arc), color="black", lw=0.8)
ax1.annotate(r"$\theta$", (0.15, -0.10), fontsize=11)

# spin arrow omega
spin = np.linspace(np.deg2rad(35), np.deg2rad(145), 40)
ax1.plot(0.36 * np.cos(spin), 0.36 * np.sin(spin), color=MAGENTA, lw=1.4)
ax1.add_patch(FancyArrowPatch(
    (0.36 * np.cos(spin[1]), 0.36 * np.sin(spin[1])),
    (0.36 * np.cos(spin[0]), 0.36 * np.sin(spin[0])),
    arrowstyle="-|>", mutation_scale=13, color=MAGENTA))
ax1.annotate(r"$\omega$", (0.0, 0.40), ha="center", color=MAGENTA, fontsize=12)

# translation arrow v
ax1.add_patch(FancyArrowPatch((0.0, 0.0), (0.30, 0.14), arrowstyle="-|>",
                              mutation_scale=13, color=MAGENTA, lw=1.4))
ax1.annotate("$v$", (0.31, 0.16), color=MAGENTA, fontsize=12)

# camera below, looking up
cam = np.array([0.0, -0.78])
ax1.plot(*cam, marker="s", color="black", ms=7)
for th_ray in (np.deg2rad(65), np.deg2rad(115)):
    ray = cam + 0.62 * np.array([np.cos(th_ray), np.sin(th_ray)])
    ax1.plot([cam[0], ray[0]], [cam[1], ray[1]], color=GRAY, lw=0.7, ls=":")
ax1.annotate("camera", (0.06, -0.80), fontsize=10)
ax1.annotate("observed plate:\n$x_a = x_c + r\\cos\\theta$\n"
             "$y_a = y_c + r\\sin\\theta$",
             (-0.86, -0.72), fontsize=10, color=BLUE)

ax1.set_title("Simplified four-plate geometry", fontsize=11.5)
ax1.set_xlim(-0.9, 0.9); ax1.set_ylim(-0.95, 0.55)
ax1.set_aspect("equal"); ax1.axis("off")

# ---------- right: armor trajectory vs center trajectory -----------------
v, omega, r0 = 1.0, 1.5 * 2 * np.pi, 0.26     # 1 m/s, 1.5 rev/s
tt = np.linspace(0.0, 1.5, 900)
cx, cy = v * tt, np.zeros_like(tt)
ax_, ay_ = cx + r0 * np.cos(th0 + omega * tt), cy + r0 * np.sin(th0 + omega * tt)

ax2.plot(ax_, ay_, color=BLUE, lw=2.2, alpha=0.8,
         label="armor-plate trajectory")
ax2.plot(cx, cy, color=MAGENTA, lw=2.6, label="chassis-center trajectory")
ax2.plot(cx[0], cy[0], "o", color="black", ms=5, zorder=5)
ax2.plot(cx[-1], cy[-1], "o", color="black", ms=5, zorder=5)
ax2.annotate("t = 0", (cx[0] - 0.02, 0.06), ha="right", fontsize=9)
ax2.annotate("t = 1.5 s", (cx[-1] + 0.03, 0.06), fontsize=9)

ax2.set_title("Simulated motion: rotation 1.5 rev/s, translation 1 m/s",
              fontsize=11.5)
ax2.set_xlabel("x (m)"); ax2.set_ylabel("y (m)")
ax2.set_aspect("equal")
ax2.set_xlim(-0.45, 1.95); ax2.set_ylim(-0.55, 0.55)
ax2.legend(loc="upper left", fontsize=9, framealpha=0.9)

fig.tight_layout()
output = (Path(__file__).resolve().parents[2]
          / "chapters/2.Theory/images/theory-kalman-spin-model.png")
fig.savefig(output, bbox_inches="tight")
print("saved theory-kalman-spin-model.png")
