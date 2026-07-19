# Depth error caused by 1 px of armor-width measurement error, vs distance.
# Z = fx*W/w  =>  |dZ/dw| = Z^2/(fx*W): quadratic growth with distance.
# fx = 1739 px (6 mm lens, 3.45 um pixel), W = 135 mm (small) / 230 mm (large).
# Generates chapters/2.Theory/images/theory-camera-depth.png
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11})

fx = 1739.0            # px
W_small, W_large = 0.135, 0.230   # m

Z = np.linspace(1, 8, 200)
dz_small = Z**2 / (fx * W_small) * 100   # cm per px
dz_large = Z**2 / (fx * W_large) * 100
dx_lateral = Z / fx * 100                # cm per px, lateral direction

fig, ax = plt.subplots(figsize=(8.6, 4.6), dpi=150)
ax.plot(Z, dz_small, color=BLUE, lw=2.2)
ax.plot(Z, dz_large, color=MAGENTA, lw=2.2)
ax.plot(Z, dx_lateral, color=GRAY, lw=1.4, ls="--")

# direct labels on the curves
ax.annotate("small armor (W=135 mm)", (6.1, dz_small[-60] + 1.5),
            color=BLUE, fontsize=11, rotation=38)
ax.annotate("large armor (W=230 mm)", (6.6, dz_large[-40] - 2.2),
            color=MAGENTA, fontsize=11, rotation=26)
ax.annotate("lateral error per px ($Z/f_x$)", (4.6, 1.0), color=GRAY, fontsize=10)

# annotated points on the small-armor curve
for z0 in (2, 5, 8):
    v = z0**2 / (fx * W_small) * 100
    ax.plot(z0, v, "o", color=BLUE, ms=6)
    ax.annotate(f"{v:.1f} cm/px", (z0 - 0.1, v + 1.3), ha="right",
                color=BLUE, fontsize=10)

ax.set_xlabel("distance Z (m)")
ax.set_ylabel("depth error per 1 px width error (cm)")
ax.set_title("Depth error per pixel grows as $Z^2/(f_x W)$ — "
             "1.7 cm @2 m, 10.6 cm @5 m, 27 cm @8 m (small armor)",
             fontsize=11.5)
ax.set_xlim(1, 8)
ax.set_ylim(0, 30)
ax.grid(color="#E5E5E5", lw=0.6)
ax.set_axisbelow(True)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)
fig.tight_layout()
fig.savefig("/home/neomelt/RMCV_Tutorial/chapters/2.Theory/images/theory-camera-depth.png",
            dpi=150, bbox_inches="tight", facecolor="white")
print("saved theory-camera-depth.png")
