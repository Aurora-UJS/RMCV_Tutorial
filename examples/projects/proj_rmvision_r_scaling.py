# What rm_vision's distance-scaled measurement noise actually does.
#
# tracker_node.cpp:104-109 builds R every update as
#     R = diag(|f*z0|, |f*z1|, |f*z2|, r_yaw),  f = r_xyz_factor = 4e-4
# where z = (xa, ya, za) is the measured armor position in the odom frame.
# So the variance of each axis is proportional to the ABSOLUTE VALUE OF THAT
# COORDINATE, which is only a proxy for range.  This script sweeps a target
# along a constant-range arc and plots the resulting 1-sigma per axis, so the
# reader can see (a) sigma_x wobbles although the range never changes and
# (b) sigma_y collapses to zero as the target crosses the odom +x axis
#     (the IMU yaw at power-on, NOT the current boresight).
# Generates chapters/6.Projects/images/proj-rmvision-r-scaling.png
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Ellipse

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
INK = "#222222"
mpl.rcParams.update({"font.size": 10.0})

F = 4e-4          # ekf.r_xyz_factor, node_params.yaml:39
RANGE = 4.0       # constant slant range of the sweep, metres
ZA = -0.05        # armor height in the odom frame, metres

ya = np.linspace(-3.0, 3.0, 601)
xa = np.sqrt(RANGE ** 2 - ya ** 2)
za = np.full_like(ya, ZA)

sx = np.sqrt(F * np.abs(xa))
sy = np.sqrt(F * np.abs(ya))
sz = np.sqrt(F * np.abs(za))

i0 = int(np.argmin(np.abs(ya)))
sx_c, sx_e = sx[i0] * 1e3, sx[0] * 1e3
sy_e = sy[0] * 1e3
sz_c = sz[i0] * 1e3

fig, (axA, axB) = plt.subplots(1, 2, figsize=(12.6, 5.5), dpi=150,
                               gridspec_kw={"width_ratios": [1.0, 1.25]})

# ---------------- panel A : top-down view with 1-sigma ellipses --------------
SCALE = 20.0
axA.plot(ya, xa, color=GRAY, lw=1.4, ls="--", zorder=2,
         label="target path, range fixed at 4.0 m")
axA.plot([0], [0], marker="^", ms=13, color=INK, zorder=5)
axA.text(0.0, -0.42, "gimbal / odom origin", ha="center", va="top",
         fontsize=8.6, color=INK)
axA.plot([0, 0], [0, 4.35], color=GRAY, lw=0.9, ls=":", zorder=1)
axA.text(0.06, 4.42, "odom +x = IMU yaw at power-on\n(NOT the boresight)",
         fontsize=8.2, color=GRAY, ha="left", va="bottom")

for yq in (-3.0, -1.8, 0.0, 1.8, 3.0):
    k = int(np.argmin(np.abs(ya - yq)))
    axA.add_patch(Ellipse((ya[k], xa[k]),
                          width=2 * sy[k] * SCALE, height=2 * sx[k] * SCALE,
                          facecolor=BLUE, alpha=0.28, edgecolor=BLUE, lw=1.5, zorder=3))
    axA.plot([ya[k]], [xa[k]], marker="o", ms=4.5, color=BLUE, zorder=4)
    axA.plot([0, ya[k]], [0, xa[k]], color=MAGENTA, lw=0.9, alpha=0.55, zorder=1)

axA.set_xlim(-3.9, 3.9)
axA.set_ylim(-0.95, 5.6)
axA.set_aspect("equal")
axA.set_xlabel("$y_a$  [m]   (lateral, odom frame)")
axA.set_ylabel("$x_a$  [m]   (odom +x, boot heading)")
axA.set_title("1-sigma measurement ellipse of R, drawn 20x\n"
              "magenta = line of sight; correct shape = elongated ALONG it",
              fontsize=10.0)
axA.legend(loc="upper right", fontsize=8.2, frameon=False)
axA.grid(alpha=0.25, lw=0.6)

axA.annotate("on-axis: ellipse\ncollapses in y",
             xy=(0.0, RANGE), xytext=(1.35, 1.35),
             fontsize=8.4, color=MAGENTA, fontweight="bold",
             arrowprops=dict(arrowstyle="->", color=MAGENTA, lw=1.2))
axA.annotate("off-axis: nearly\nisotropic, LOS\nstructure lost",
             xy=(-3.0, xa[0]), xytext=(-3.75, 3.45),
             fontsize=8.4, color=MAGENTA, fontweight="bold",
             arrowprops=dict(arrowstyle="->", color=MAGENTA, lw=1.2))

# ---------------- panel B : sigma per axis ----------------------------------
axB.plot(ya, sx * 1e3, color=BLUE, lw=3.0, alpha=0.85, label=r"$\sigma_x = \sqrt{f\,|x_a|}$")
axB.plot(ya, sy * 1e3, color=MAGENTA, lw=2.0, label=r"$\sigma_y = \sqrt{f\,|y_a|}$")
axB.plot(ya, sz * 1e3, color=GRAY, lw=2.0, ls="--", label=r"$\sigma_z = \sqrt{f\,|z_a|}$")
axB.axhline(np.sqrt(F * RANGE) * 1e3, color=INK, lw=1.1, ls=":",
            label=r"$\sqrt{f \cdot \mathrm{true\ range}}$ = 40.0 mm (constant)")

axB.axvspan(-0.35, 0.35, color=MAGENTA, alpha=0.10, zorder=0)
axB.text(0.0, 44.0, "odom x-axis:\n$\\sigma_y \\rightarrow 0$", ha="center", va="bottom",
         fontsize=8.4, color=MAGENTA, fontweight="bold")

axB.plot([0], [sy[i0] * 1e3], marker="o", ms=7, color=MAGENTA, zorder=5)
axB.annotate(f"{sy[i0]*1e3:.1f} mm", xy=(0, sy[i0] * 1e3), xytext=(0.45, 6.0),
             fontsize=8.6, color=MAGENTA, fontweight="bold",
             arrowprops=dict(arrowstyle="->", color=MAGENTA, lw=1.1))
axB.plot([-3.0], [sy_e], marker="o", ms=6, color=MAGENTA, zorder=5)
axB.text(-2.92, sy_e + 1.6, f"{sy_e:.1f} mm", fontsize=8.4, color=MAGENTA, fontweight="bold")
axB.plot([0], [sx_c], marker="o", ms=6, color=BLUE, zorder=5)
axB.text(0.55, sx_c - 3.6, f"{sx_c:.1f} mm", fontsize=8.4, color=BLUE, fontweight="bold")
axB.plot([-3.0], [sx[0] * 1e3], marker="o", ms=6, color=BLUE, zorder=5)
axB.text(-2.92, sx[0] * 1e3 - 3.4, f"{sx_e:.1f} mm", fontsize=8.4, color=BLUE, fontweight="bold")
axB.text(2.95, sz_c + 1.6, f"{sz_c:.1f} mm", fontsize=8.4, color=GRAY,
         fontweight="bold", ha="right")

axB.set_xlim(-3.2, 3.2)
axB.set_ylim(0, 50)
axB.set_xlabel("target lateral position $y_a$  [m]   (range held at 4.0 m throughout)")
axB.set_ylabel("assumed measurement 1-sigma  [mm]")
axB.set_title(f"Range never changes, yet $\\sigma_x$ swings {sx_e:.1f} -> {sx_c:.1f} mm ({100*(sx_c-sx_e)/sx_e:.0f}%)\n"
              f"and $\\sigma_y$ runs {sy_e:.1f} -> {sy[i0]*1e3:.1f} mm",
              fontsize=10.0)
axB.legend(loc="center right", fontsize=8.4, frameon=False)
axB.grid(alpha=0.25, lw=0.6)

fig.suptitle("rm_vision R = diag(|f*xa|, |f*ya|, |f*za|, r_yaw), f = 4e-4 : a per-AXIS proxy for range, not range itself",
             fontsize=12.0, fontweight="bold", y=1.005)
fig.tight_layout()
fig.savefig("/home/neomelt/RMCV_Tutorial/chapters/6.Projects/images/proj-rmvision-r-scaling.png",
            dpi=150, bbox_inches="tight", facecolor="white")
print(f"sigma_x on-axis {sx_c:.2f} mm, edge {sx_e:.2f} mm")
print(f"sigma_y edge {sy_e:.2f} mm, on-axis {sy[i0]*1e3:.3f} mm")
print(f"sigma_z {sz_c:.2f} mm")
print(f"sqrt(f*range) = {np.sqrt(F*RANGE)*1e3:.2f} mm")
