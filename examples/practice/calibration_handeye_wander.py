# Illustrative hand-eye consistency sensitivity for a fixed target 4 m away
# while the gimbal sweeps yaw +-20 deg and pitch +-10 deg. The left panel uses
# full rotation matrices for the specified axes and sweep. The right panel uses
# the first-order perpendicular scale d*|delta theta|; an arbitrary direction
# instead gives d_perp*|delta theta| <= d*|delta theta|. The curves illustrate
# geometry and do not define a firing threshold or uniquely diagnose a cause.
# Generates chapters/3.Practice/images/practice-calibration-handeye.png
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
from matplotlib.patches import Rectangle

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11})


def Rz(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def rot_axis(axis, angle):
    """Rodrigues rotation about a unit axis."""
    n = np.asarray(axis, float)
    n = n / np.linalg.norm(n)
    K = np.array([[0, -n[2], n[1]], [n[2], 0, -n[0]], [-n[1], n[0], 0]])
    return np.eye(3) + np.sin(angle) * K + (1 - np.cos(angle)) * (K @ K)


# Nominal extrinsic used to synthesize the example.
R_GC = np.array([[0, 0, 1], [-1, 0, 0], [0, -1, 0]], float)
t_GC = np.array([0.10, 0.0, 0.05])

p_O = np.array([4.0, 0.0, 0.0])  # fixed target, 4 m ahead in reference frame O

# Two-axis periodic sweep: yaw +-20 deg / pitch +-10 deg (target stays in FOV)
t = np.linspace(0, 2 * np.pi, 600)
yaw = np.deg2rad(20) * np.sin(t)
pitch = np.deg2rad(10) * np.sin(2 * t + 0.6)

# Two specified rotation-error axes with different pose-dependent signatures.
# Their traces are examples for this target direction and sweep, not diagnoses.
n_perp = np.array([0.0, 1.0, 1.0]) / np.sqrt(2)
n_roll = np.array([1.0, 0.0, 0.0])

cases = [
    ("no injected extrinsic error", None, None, "#222222", "-"),
    ("1 cm translation error", None, np.array([0.0, 0.01, 0.0]), BLUE, "-"),
    # Translation is drawn thicker so its centimeter-scale path remains visible.
    ("1$\\degree$ transverse-axis rotation", (n_perp, 1.0), None,
     MAGENTA, "-"),
    ("1$\\degree$ nominal sight-axis rotation", (n_roll, 1.0), None,
     MAGENTA, "-."),
]

fig, (axL, axR) = plt.subplots(1, 2, figsize=(10.5, 4.4), dpi=150)

# armor plate footprint for scale (135 x 55 mm, centered on the true point)
axL.add_patch(Rectangle((-6.75, -2.75), 13.5, 5.5, facecolor="#EDEDED",
                        edgecolor=GRAY, lw=1.0, zorder=0))
axL.annotate("armor plate 135$\\times$55 mm", (6.4, 2.35),
             ha="right", color="#555555", fontsize=9)

stats = {}
for label, rot_err, dt, color, ls in cases:
    R_hat = R_GC if rot_err is None else rot_axis(
        rot_err[0], np.deg2rad(rot_err[1])) @ R_GC
    t_hat = t_GC if dt is None else t_GC + dt
    trace = np.empty((len(t), 3))
    for i, (a, b) in enumerate(zip(yaw, pitch)):
        R_OG = Rz(a) @ rot_axis([0, 1, 0], b)      # yaw then pitch
        p_C = R_GC.T @ (R_OG.T @ p_O - t_GC)       # what the camera measures
        trace[i] = R_OG @ (R_hat @ p_C + t_hat)    # odom estimate w/ bad extrinsic
    err = trace - p_O
    stats[label] = (np.linalg.norm(err, axis=1).mean(),
                    np.ptp(err, axis=0).max())
    if rot_err is None and dt is None:
        axL.plot(0, 0, "*", color=color, ms=14, zorder=6, label=label)
    else:
        lw = 3.0 if dt is not None else 1.8
        axL.plot(err[:, 1] * 100, err[:, 2] * 100, ls, color=color,
                 lw=lw, label=label)

axL.set_xlabel("O-frame y error (cm)")
axL.set_ylabel("O-frame z error (cm)")
axL.set_aspect("equal")
axL.grid(color="#E5E5E5", lw=0.6)
axL.legend(loc="lower left", fontsize=8.5, framealpha=0.95)
axL.set_title("fixed target in O, yaw $\\pm$20$\\degree$ / "
              "pitch $\\pm$10$\\degree$ sweep, d = 4 m", fontsize=11)

# Right: first-order perpendicular scale d*|delta theta| versus |delta t|.
d = np.linspace(0.5, 8, 200)
axR.plot(d, np.deg2rad(1.0) * d * 100, color=MAGENTA, lw=2.2,
         label="1.0$\\degree$ perpendicular: $d|\\delta\\theta|$ (small angle)")
axR.plot(d, np.deg2rad(0.5) * d * 100, "--", color=MAGENTA, lw=1.8,
         label="0.5$\\degree$ perpendicular scale")
axR.axhline(1.0, color=BLUE, lw=2.2, label="1 cm translation: constant")
axR.axhline(6.75, color=GRAY, lw=1.0, ls=":")
axR.annotate("13.5 cm plate: half-width = 6.75 cm", (0.7, 7.0),
             color="#555555", fontsize=9)
x_cross = 6.75 / (np.deg2rad(1.0) * 100)
axR.plot(x_cross, 6.75, "o", color=MAGENTA, ms=6)
axR.annotate(f"1$\\degree$ scale crosses\nreference at {x_cross:.1f} m",
             xy=(x_cross, 6.75), xytext=(4.5, 5.1),
             arrowprops={"arrowstyle": "->", "color": MAGENTA, "lw": 0.9},
             color=MAGENTA, fontsize=9, ha="left")
axR.set_xlabel("target distance d (m)")
axR.set_ylabel("position-error scale (cm)")
axR.set_xlim(0, 8)
axR.set_ylim(0, 15)
axR.grid(color="#E5E5E5", lw=0.6)
axR.legend(loc="upper left", fontsize=8.5, framealpha=0.95)
axR.set_title("perpendicular small-angle scale vs range", fontsize=11)

fig.suptitle("Illustrative hand-eye sensitivity: fixed target, specified sweep and error axes",
             fontsize=13, y=1.0)
fig.tight_layout()
output = (Path(__file__).resolve().parents[2] / "chapters/3.Practice/images/"
          "practice-calibration-handeye.png")
fig.savefig(output,
            dpi=150, bbox_inches="tight", facecolor="white")

print("plate reference: full width = 13.50 cm, half-width = 6.75 cm")
print(f"1 deg perpendicular scale crosses reference at {x_cross:.2f} m")
for k, (mean_off, span) in stats.items():
    print(f"{k:28s} mean offset = {mean_off * 100:5.2f} cm, "
          f"max axis span = {span * 100:5.2f} cm")
