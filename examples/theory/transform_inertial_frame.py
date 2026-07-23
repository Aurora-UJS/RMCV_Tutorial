# Why aim prediction must run in an inertial frame.
# A target that is perfectly static in the odom frame appears to move at
# omega * r in the camera frame while the gimbal sweeps.
# Output: chapters/2.Theory/images/theory-transform-inertial-frame.png
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

OUTPUT = (Path(__file__).resolve().parents[2]
          / "chapters/2.Theory/images/theory-transform-inertial-frame.png")

# Scenario chosen for the illustration: gimbal yaw sweeps at 2 rad/s.
omega = 2.0                       # rad/s
t = np.linspace(0.0, 0.5, 300)    # s
yaw = -0.5 + omega * t            # rad, sweep -28.6 deg -> +28.6 deg
p_odom = np.array([3.0, 0.8])     # m, static target (top view: x forward, y left)
r = np.hypot(*p_odom)             # 3.10 m
v_app = omega * r                 # 6.21 m/s apparent speed, constant magnitude

# Body(gimbal/camera)-frame coordinates: p_b = Rz(yaw)^T p_odom
fwd = np.cos(yaw) * p_odom[0] + np.sin(yaw) * p_odom[1]
left = -np.sin(yaw) * p_odom[0] + np.cos(yaw) * p_odom[1]

C_CAM = "#d1495b"   # camera-frame curves (the misleading view)
C_ODOM = "#1565c0"  # odom-frame lines (the truthful view)

fig, (axL, axR) = plt.subplots(1, 2, figsize=(10.5, 4.2),
                               gridspec_kw={"width_ratios": [1, 1.35]})

# --- Left: top view in the odom frame -------------------------------------
axL.set_title("Top view (odom frame)", fontsize=10.5)
axL.plot(0, 0, "s", color="#444444", ms=9, zorder=5)
axL.annotate("robot", (0, 0), textcoords="offset points", xytext=(-4, -16),
             fontsize=9, color="#444444")
axL.plot(*p_odom, "*", color=C_ODOM, ms=17, zorder=5)
axL.annotate("target (static)", p_odom, textcoords="offset points",
             xytext=(8, 6), fontsize=9, color=C_ODOM)
# camera forward direction at three instants
for tk, alpha in [(0.0, 0.35), (0.25, 0.6), (0.5, 1.0)]:
    a = -0.5 + omega * tk
    axL.annotate("", xy=(2.4 * np.cos(a), 2.4 * np.sin(a)), xytext=(0, 0),
                 arrowprops=dict(arrowstyle="->", color=C_CAM, alpha=alpha, lw=2))
    axL.annotate(f"t={tk:.2f}s", (2.55 * np.cos(a), 2.55 * np.sin(a)),
                 fontsize=8, color=C_CAM, alpha=alpha, ha="left")
arc = np.linspace(-0.5, 0.0, 60)
axL.plot(1.1 * np.cos(arc), 1.1 * np.sin(arc), color=C_CAM, lw=1, alpha=0.5)
axL.annotate("gimbal sweeps\n$\\omega$ = 2 rad/s", (1.35, -0.62), fontsize=9,
             color=C_CAM)
axL.set_xlim(-0.6, 4.0); axL.set_ylim(-2.0, 2.0)
axL.set_aspect("equal")
axL.set_xlabel("x odom [m]"); axL.set_ylabel("y odom [m]")
axL.grid(alpha=0.25, lw=0.5)

# --- Right: the same target's coordinates in both frames ------------------
axR.set_title(f"Same target, two frames: apparent speed $\\omega r$ ≈ {v_app:.1f} m/s",
              fontsize=10.5)
axR.plot(t, np.full_like(t, p_odom[0]), "--", color=C_ODOM, lw=1.6)
axR.plot(t, np.full_like(t, p_odom[1]), "--", color=C_ODOM, lw=1.6)
axR.plot(t, fwd, color=C_CAM, lw=2.4)
axR.plot(t, left, color=C_CAM, lw=2.4)
# direct labels: odom lines at the right edge, camera curves away from them
axR.annotate("x (odom)", (t[-1], p_odom[0]), textcoords="offset points",
             xytext=(6, -4), fontsize=9, color=C_ODOM, va="top")
axR.annotate("y (odom)", (t[-1], p_odom[1]), textcoords="offset points",
             xytext=(6, 0), fontsize=9, color=C_ODOM, va="center")
kf = np.argmax(fwd)  # label the forward curve at its peak
axR.annotate("forward (camera)", (t[kf], fwd[kf]), textcoords="offset points",
             xytext=(-30, 10), fontsize=9, color=C_CAM, va="bottom")
axR.annotate("left (camera)", (t[-1], left[-1]), textcoords="offset points",
             xytext=(6, 0), fontsize=9, color=C_CAM, va="center")
# slope annotation where the left-coordinate changes fastest (t = 0.25 s, yaw = 0)
k = np.argmin(np.abs(yaw))
axR.annotate(f"local slope ≈ {omega * p_odom[0]:.1f} m/s\nfor this simulated sweep",
             (t[k], left[k]), textcoords="offset points", xytext=(14, -58),
             fontsize=9, color="#333333",
             arrowprops=dict(arrowstyle="->", color="#333333", lw=1))
axR.set_xlim(0, 0.66)
axR.set_ylim(-1.1, 3.6)
axR.set_xlabel("time [s]"); axR.set_ylabel("coordinate [m]")
axR.grid(alpha=0.25, lw=0.5)

fig.suptitle("A static target 'moves' in the camera frame while the gimbal turns",
             fontsize=12)
fig.tight_layout(rect=(0, 0, 1, 0.93))
fig.savefig(OUTPUT, dpi=150, bbox_inches="tight")
print("saved", OUTPUT)
print(f"r = {r:.3f} m, apparent speed = {v_app:.2f} m/s")
# sanity: numeric derivative of camera-frame position magnitude
vx = np.gradient(fwd, t); vy = np.gradient(left, t)
print("numeric apparent speed:", np.hypot(vx, vy).mean())
