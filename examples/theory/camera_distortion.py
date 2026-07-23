# Brown distortion model on a regular grid: barrel / pincushion / tangential.
# Coefficients are exaggerated so the shape is visible in print.
# Generates chapters/2.Theory/images/theory-camera-distortion.png
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
from pathlib import Path

OUTPUT = (Path(__file__).resolve().parents[2]
          / "chapters/2.Theory/images/theory-camera-distortion.png")

BLUE, GRAY = "#3B6FD4", "#B0B0B0"
mpl.rcParams.update({"font.size": 11})


def brown(x, y, k1=0.0, k2=0.0, p1=0.0, p2=0.0):
    """Forward Brown model on the normalized image plane."""
    r2 = x * x + y * y
    radial = 1 + k1 * r2 + k2 * r2 * r2
    xd = x * radial + 2 * p1 * x * y + p2 * (r2 + 2 * x * x)
    yd = y * radial + p1 * (r2 + 2 * y * y) + 2 * p2 * x * y
    return xd, yd


cases = [
    ("Barrel  ($k_1<0$)", dict(k1=-0.35)),
    ("Pincushion  ($k_1>0$)", dict(k1=+0.35)),
    ("Tangential  ($p_1,p_2\\neq 0$)", dict(p1=0.06, p2=0.04)),
]

n, lim = 11, 0.5
lines = []  # each grid line as an (x_array, y_array) pair
t = np.linspace(-lim, lim, 60)
for c in np.linspace(-lim, lim, n):
    lines.append((np.full_like(t, c), t))   # vertical line
    lines.append((t, np.full_like(t, c)))   # horizontal line

fig, axes = plt.subplots(1, 3, figsize=(10.5, 3.7), dpi=150)
for ax, (title, coef) in zip(axes, cases):
    for x, y in lines:
        ax.plot(x, y, color=GRAY, lw=0.7)            # ideal grid
        xd, yd = brown(x, y, **coef)
        ax.plot(xd, yd, color=BLUE, lw=1.3)          # distorted grid
    ax.set_title(title, fontsize=12)
    ax.set_xlim(-0.62, 0.62)
    ax.set_ylim(-0.62, 0.62)
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    for s in ax.spines.values():
        s.set_color("#DDDDDD")

axes[0].plot([], [], color=GRAY, lw=0.7, label="ideal grid")
axes[0].plot([], [], color=BLUE, lw=1.3, label="distorted")
axes[0].legend(loc="lower left", fontsize=9, framealpha=0.9)
fig.suptitle("Brown-model examples with exaggerated coefficients on a normalized grid",
             fontsize=13, y=1.0)
fig.tight_layout()
fig.savefig(OUTPUT, dpi=150, bbox_inches="tight", facecolor="white")
print("saved theory-camera-distortion.png")
