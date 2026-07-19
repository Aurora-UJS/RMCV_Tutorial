# Distortion field of a real calibration file (community open-source config:
# 1440x1080, fx~1807, plumb_bob five-coefficient model).
# Left: displacement magnitude |distorted - ideal| in pixels over the frame.
# Right: the same displacement along the line from the principal point to the
# farthest image corner.
# Generates chapters/3.Practice/images/practice-calibration-distortion.png
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11})

# --- real calibration output (camera_info.yaml of a community RM vision stack) ---
W, H = 1440, 1080
fx, fy = 1807.12121, 1806.46896
cx, cy = 711.11997, 562.49495
k1, k2, p1, p2, k3 = -0.078049, 0.158627, 0.000304, -0.000566, 0.0


def brown_shift(u, v):
    """Pixel displacement of the ideal projection (u, v) under the Brown model."""
    x = (u - cx) / fx
    y = (v - cy) / fy
    r2 = x * x + y * y
    radial = 1 + k1 * r2 + k2 * r2 * r2 + k3 * r2 * r2 * r2
    xd = x * radial + 2 * p1 * x * y + p2 * (r2 + 2 * x * x)
    yd = y * radial + p1 * (r2 + 2 * y * y) + 2 * p2 * x * y
    ud = fx * xd + cx
    vd = fy * yd + cy
    return ud - u, vd - v


# --- panel A: magnitude map over the frame ---
uu, vv = np.meshgrid(np.linspace(0, W, 241), np.linspace(0, H, 181))
du, dv = brown_shift(uu, vv)
mag = np.hypot(du, dv)

fig, (axA, axB) = plt.subplots(
    1, 2, figsize=(10.5, 4.0), dpi=150, gridspec_kw={"width_ratios": [1.25, 1]}
)

cf = axA.contourf(uu, vv, mag, levels=np.linspace(0, 10, 21), cmap="Blues")
cs = axA.contour(uu, vv, mag, levels=[1, 2, 4, 8], colors="#33507e", linewidths=0.9)
axA.clabel(cs, fmt="%g px", fontsize=8)
axA.plot(cx, cy, "+", color=MAGENTA, ms=11, mew=2)
axA.annotate("principal point", (cx, cy), (cx + 60, cy - 60),
             color=MAGENTA, fontsize=9)
axA.set_xlim(0, W)
axA.set_ylim(H, 0)  # image convention: v downwards
axA.set_aspect("equal")
axA.set_xlabel("u (px)")
axA.set_ylabel("v (px)")
axA.set_title("displacement over the 1440$\\times$1080 frame", fontsize=11)
fig.colorbar(cf, ax=axA, shrink=0.85, label="|shift| (px)")

# --- panel B: displacement along the worst radial direction ---
corners = np.array([[0, 0], [W, 0], [0, H], [W, H]], float)
rad = np.hypot(corners[:, 0] - cx, corners[:, 1] - cy)
far = corners[np.argmax(rad)]
R0 = rad.max()
dirv = (far - np.array([cx, cy])) / R0

r = np.linspace(0, R0, 400)
du, dv = brown_shift(cx + r * dirv[0], cy + r * dirv[1])
shift = np.hypot(du, dv)

axB.plot(r, shift, color=BLUE, lw=2.2)
axB.axvspan(0, 300, color=GRAY, alpha=0.18, lw=0)
axB.annotate("central zone\n(r < 300 px)", (150, 5.0), ha="center",
             color="#555555", fontsize=9)
axB.plot(R0, shift[-1], "o", color=MAGENTA, ms=7, zorder=5)
axB.annotate(f"image corner: {shift[-1]:.1f} px", (R0 - 20, shift[-1]),
             ha="right", va="bottom", color=MAGENTA, fontsize=10)
r1 = r[np.searchsorted(shift, 1.0)]
axB.axhline(1.0, color=GRAY, lw=0.8, ls="--")
axB.annotate(f"1 px at r $\\approx$ {r1:.0f} px", (r1 + 30, 1.45),
             fontsize=9, color="#555555")
axB.set_xlabel("distance from principal point (px)")
axB.set_ylabel("|shift| (px)")
axB.set_xlim(0, R0 * 1.02)
axB.set_ylim(0, 10.8)
axB.grid(color="#E5E5E5", lw=0.6)
axB.set_title("along the worst radial direction", fontsize=11)

fig.suptitle("plumb_bob $[-0.078,\\ 0.159,\\ 0.0003,\\ -0.0006,\\ 0]$: "
             f"sub-pixel near the center, $\\approx$ {shift[-1]:.1f} px at the corners",
             fontsize=13, y=1.02)
fig.tight_layout()
fig.savefig("/home/neomelt/RMCV_Tutorial/chapters/3.Practice/images/"
            "practice-calibration-distortion.png",
            dpi=150, bbox_inches="tight", facecolor="white")

# numbers used in the chapter text
du, dv = brown_shift(cx + 300 * dirv[0], cy + 300 * dirv[1])
print(f"corner shift      = {shift[-1]:.2f} px  (r = {R0:.0f} px)")
print(f"shift at r=300 px = {np.hypot(du, dv):.2f} px")
print(f"1 px crossing     = r {r1:.0f} px")
print(f"fx * 3.45um       = {fx * 3.45e-3:.3f} mm")
print(f"fy/fx deviation   = {abs(fy / fx - 1) * 100:.3f} %")
print(f"cx off center     = {cx - W / 2:+.1f} px, cy off center = {cy - H / 2:+.1f} px")
