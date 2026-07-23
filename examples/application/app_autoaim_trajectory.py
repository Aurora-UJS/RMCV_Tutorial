# Trajectory-view of auto-aim, for the system-integration chapter.
#
# Illustrates, in miniature, the sp_vision-25 "trajectory planner" idea:
#   * a spinning enemy (small-top) -> the shoot trajectory yaw_shoot(t)
#     (the target trajectory advanced by one bullet flight time t_fly),
#     which is a saw-tooth because the nearest armour switches every 90 deg;
#   * a feasible planned trajectory found by a finite-horizon,
#     acceleration-bounded least-squares problem with the same basic
#     box-constrained structure as the inspected TinyMPC setup:
#     min ||pos - shoot||^2 + lam||acc||^2 s.t. |acc| <= a_max,
#     double integrator pos'=vel, vel'=acc;
#   * gate-eligible windows = where |plan - shoot| < fire_thresh; this only
#     evaluates the simplified plan and is not a measured hit rate.
#
# The planned reference can begin transitioning before an armour switch because
# a bounded-acceleration trajectory cannot follow the discontinuous reference.
#
# Generates chapters/4.Application/images/app-autoaim-trajectory.png
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from scipy.optimize import lsq_linear

mpl.rcParams.update({"font.size": 10.5})

# ---- target: a car spinning in place, 4 armours on a square -----------------
DT = 0.01
T = 1.4
t = np.arange(0, T, DT)
N = t.size

omega = 4.0          # spin rate [rad/s]  (a brisk small-top)
d = 2.6              # gimbal-to-centre distance [m]
r = 0.28             # armour radius [m]
t_fly = 0.12         # bullet flight time [s]  (~2.6 m at ~22 m/s)


def target_yaw(tt):
    """Azimuth of the NEAREST of four armours of a car spinning at omega."""
    phi = omega * tt                      # car orientation
    ang = phi + np.array([0, 1, 2, 3]) * (np.pi / 2)
    ax = d + r * np.cos(ang)              # armour x (centre on the x axis)
    ay = r * np.sin(ang)                  # armour y
    dist = np.hypot(ax, ay)
    k = np.argmin(dist)                   # the nearest armour
    return np.arctan2(ay[k], ax[k])


yaw_target = np.array([target_yaw(tt) for tt in t])            # target trajectory
yaw_shoot = np.array([target_yaw(tt + t_fly) for tt in t])     # advanced by t_fly

# ---- feasible plan: acceleration-bounded LS (a simplified planner QP) -------
a_max = 40.0         # synthetic yaw-acceleration bound [rad/s^2]
lam = 1e-7           # tiny effort weight (the R in the QP)

# double integrator: pos = M @ u + pos0 + t*vel0  (state [pos,vel], input acc)
M = np.zeros((N, N - 1))
for k in range(N):
    for j in range(k - 1):
        M[k, j] = DT * DT * (k - 1 - j)
pos0, vel0 = yaw_shoot[0], (yaw_shoot[1] - yaw_shoot[0]) / DT
base = pos0 + t * vel0

A = np.vstack([M, np.sqrt(lam) * np.eye(N - 1)])
b = np.concatenate([yaw_shoot - base, np.zeros(N - 1)])
sol = lsq_linear(A, b, bounds=(-a_max, a_max), max_iter=800, tol=1e-11)
if not sol.success:
    raise RuntimeError(f"trajectory solve failed: {sol.message}")
u = sol.x
yaw_plan = base + M @ u

# ---- yaw gate: |planned yaw - shoot yaw| < fire_thresh ----------------------
fire_thresh = 0.0035  # standard3 threshold; this script checks yaw only
err = np.abs(yaw_plan - yaw_shoot)
fire = err < fire_thresh
availability = fire.mean()               # yaw-gate availability in this model

# =========================== plot ===========================================
fig, (ax, axe) = plt.subplots(
    2, 1, figsize=(10.4, 6.6), dpi=150, sharex=True,
    gridspec_kw={"height_ratios": [3, 1], "hspace": 0.12})

RED, BLUE, INK, GREEN = "#D6336C", "#3B6FD4", "#222222", "#2F9E44"
deg = 180 / np.pi

# shade fire (green) / hold (light red) bands across the top panel
def shade(axis):
    inband = fire.astype(int)
    edges = np.flatnonzero(np.diff(np.concatenate([[0], inband, [0]])))
    starts, ends = edges[::2], edges[1::2]
    for s, e in zip(starts, ends):
        end = t[e] if e < N else T
        axis.axvspan(t[s], end, color=GREEN, alpha=0.12, zorder=0)
    hold = 1 - inband
    edges = np.flatnonzero(np.diff(np.concatenate([[0], hold, [0]])))
    for s, e in zip(edges[::2], edges[1::2]):
        end = t[e] if e < N else T
        axis.axvspan(t[s], end, color=RED, alpha=0.08, zorder=0)

shade(ax)

ax.plot(t, yaw_target * deg, color=INK, lw=1.0, alpha=0.35,
        label="target trajectory  yaw_target(t)")
ax.plot(t, yaw_shoot * deg, color=RED, lw=1.6, ls=(0, (5, 2)),
        label="shoot trajectory  yaw_shoot(t) = yaw_target(t + t_fly)")
ax.plot(t, yaw_plan * deg, color=BLUE, lw=4.2, alpha=0.55,
        solid_capstyle="round", label="planned trajectory (acc-bounded model)")

# annotate the t_fly lead and one early-deceleration
i0 = 22
ax.annotate("", xy=(t[i0], yaw_shoot[i0] * deg),
            xytext=(t[i0] + t_fly, yaw_target[i0 + int(t_fly / DT)] * deg),
            arrowprops=dict(arrowstyle="<->", color=INK, lw=1.0))
ax.text(t[i0] + t_fly / 2, yaw_shoot[i0] * deg + 1.6, "t_fly", ha="center",
        fontsize=8.6, color=INK)

# Mark one transition that starts before a reference jump.
jumps = np.flatnonzero(np.abs(np.diff(yaw_shoot)) > 0.02)
if jumps.size:
    js = jumps[len(jumps) // 2]
    ax.annotate("planned transition\nbegins before\nthe reference jump",
                xy=(t[js - 6], yaw_plan[js - 6] * deg),
                xytext=(t[js] - 0.30, yaw_plan[js - 6] * deg + 4.2),
                fontsize=8.2, color=BLUE, ha="center",
                arrowprops=dict(arrowstyle="->", color=BLUE, lw=1.0))

ax.set_ylabel("yaw  [deg]")
ax.legend(loc="upper right", fontsize=8.6, framealpha=0.92)
ax.set_title(
    f"Simplified trajectory plan: yaw-gate availability = {availability*100:.0f}%\n"
    "green = planned yaw is within the gate;   "
    "red = planned yaw is outside the gate (not measured hit rate)",
    fontsize=11, fontweight="bold", pad=9, loc="left")

# error panel with the fire threshold
shade(axe)
axe.plot(t, err * deg, color=BLUE, lw=1.5)
axe.axhline(fire_thresh * deg, color=INK, lw=1.0, ls=":")
axe.text(t[2], fire_thresh * deg * 1.15, "yaw threshold", fontsize=8.0, color=INK)
axe.set_ylabel("|err| [deg]")
axe.set_xlabel("time  t  [s]")
axe.set_ylim(0, err.max() * deg * 1.1)
axe.set_xlim(0, T)

fig.savefig("chapters/4.Application/images/app-autoaim-trajectory.png",
            bbox_inches="tight", facecolor="white")
print(f"saved app-autoaim-trajectory.png  availability={availability*100:.1f}%  "
      f"max|err|={err.max()*deg:.2f}deg  a_max_used={np.abs(u).max():.1f}")
