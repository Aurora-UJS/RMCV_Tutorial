# Mirrors the core grid search in sp_vision_25's optimize_yaw() for one
# synthetic pose, then illustrates its sensitivity to a mismatched pitch prior.
#
# Geometry / constants are taken verbatim from the repository:
#   tasks/auto_aim/solver.cpp:12-25   armor object points (big: 230 mm x 56 mm)
#   tasks/auto_aim/solver.cpp:96      pitch hard-coded to +15 deg (outpost -15)
#   tasks/auto_aim/solver.cpp:101-125 R_armor2world and the reprojection
#   tasks/auto_aim/solver.cpp:196-218 SEARCH_RANGE = 140 deg, 1 deg step
#   tasks/auto_aim/solver.cpp:259     cost = sum of the 4 corner L2 distances
# Intrinsics, distortion, and camera-to-gimbal extrinsics come from
# configs/standard4.yaml. The target pose and corner-noise model are synthetic.
# Position is held fixed while the yaw cost is evaluated, so this is not an
# end-to-end reproduction of solvePnP, tracking, or field accuracy.
#
# In this chosen geometry, increasing pitch-prior mismatch introduces a second
# local minimum and raises the chance of a large yaw error under corner noise.
#
# Generates chapters/6.Projects/images/proj-sp-yaw-optimize.png
from pathlib import Path

import cv2
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
ORANGE, INK = "#E8890C", "#222222"
mpl.rcParams.update({"font.size": 10.0, "axes.linewidth": 0.9})

DEG = np.pi / 180.0

LIGHTBAR_LENGTH = 56e-3
BIG_ARMOR_WIDTH = 230e-3
OBJ = np.array([
    [0,  BIG_ARMOR_WIDTH / 2,  LIGHTBAR_LENGTH / 2],
    [0, -BIG_ARMOR_WIDTH / 2,  LIGHTBAR_LENGTH / 2],
    [0, -BIG_ARMOR_WIDTH / 2, -LIGHTBAR_LENGTH / 2],
    [0,  BIG_ARMOR_WIDTH / 2, -LIGHTBAR_LENGTH / 2],
], dtype=np.float64)

K = np.array([[1851.7070167840545, 0, 721.12585328714192],
              [0, 1851.8175594364079, 571.69879709276688],
              [0, 0, 1]], dtype=np.float64)
DIST = np.array([-0.093662536083526302, 0.18945726820633155,
                 -0.00040424349861928674, -0.0040568403852123142, 0.0])

R_CAM2GIM = np.array([
    [0.02823004230930648, -0.014076983590428133, 0.99950232778328707],
    [-0.99954530259354468, -0.010995644138609872, 0.028076393521179785],
    [0.010594940981141165, -0.99984045444409364, -0.014380990321749998],
])
T_HANDEYE = np.array([0.045517325957791413, 0.10544338092767802, 0.034649710880185793])

SEARCH_RANGE = 140          # solver.cpp:200
ASSUMED_PITCH = 15 * DEG    # solver.cpp:96
PIX_NOISE = 1.0             # px, 1-sigma per corner coordinate
TRIALS = 600
YAW_TRUE = 25 * DEG

# Chosen synthetic pose: 4 m horizontal range at world-frame azimuth 12 deg,
# 0.25 m above the gimbal origin, with the gimbal yawed by 10 deg. Before the
# camera extrinsics are applied, the target is therefore 2 deg off gimbal yaw.
DIST_M, AZIM, HEIGHT, GIMBAL_YAW = 4.0, 12 * DEG, 0.25, 10 * DEG
XYZ = np.array([DIST_M * np.cos(AZIM), DIST_M * np.sin(AZIM), HEIGHT])
R_G2W = np.array([[np.cos(GIMBAL_YAW), -np.sin(GIMBAL_YAW), 0],
                  [np.sin(GIMBAL_YAW),  np.cos(GIMBAL_YAW), 0], [0, 0, 1.0]])
GRID = GIMBAL_YAW + (-SEARCH_RANGE / 2 + np.arange(SEARCH_RANGE)) * DEG


def R_armor2world(yaw, pitch):
    cy, sy, cp, sp = np.cos(yaw), np.sin(yaw), np.cos(pitch), np.sin(pitch)
    return np.array([[cy * cp, -sy, cy * sp],
                     [sy * cp,  cy, sy * sp],
                     [-sp,       0, cp]])


def reproject(yaw, pitch):
    R_a2c = R_CAM2GIM.T @ R_G2W.T @ R_armor2world(yaw, pitch)
    t_a2c = R_CAM2GIM.T @ (R_G2W.T @ XYZ - T_HANDEYE)
    rvec, _ = cv2.Rodrigues(R_a2c)
    pts, _ = cv2.projectPoints(OBJ, rvec, t_a2c, K, DIST)
    return pts.reshape(4, 2)


def cost_curve(measured, yaws):
    """solver.cpp:259 evaluated on a whole set of candidate yaws at once."""
    return np.array([np.sum(np.linalg.norm(measured - reproject(y, ASSUMED_PITCH), axis=1))
                     for y in yaws])


# the 140 model reprojections the search walks depend only on the grid and the
# assumed pitch, so they are built once and reused for every noise trial
MODEL = np.stack([reproject(y, ASSUMED_PITCH) for y in GRID])       # (140, 4, 2)


def search_batch(meas):
    """meas: (N, 4, 2) -> best grid yaw for each, exactly as the C++ loop does."""
    c = np.linalg.norm(meas[:, None, :, :] - MODEL[None, :, :, :], axis=3).sum(axis=2)
    return GRID[np.argmin(c, axis=1)]


fig, (axA, axB) = plt.subplots(1, 2, figsize=(12.4, 4.6), dpi=150)

# ---------------- panel A: the cost landscape -----------------------------
grid_fine = np.linspace(GIMBAL_YAW - 45 * DEG, GIMBAL_YAW + 50 * DEG, 1501)

for p_deg, col, lw, lab in [(15, BLUE, 2.1, "true pitch 15 deg — prior is right"),
                            (0, ORANGE, 1.7, "true pitch 0 deg — prior off by 15 deg"),
                            (-15, MAGENTA, 1.7, "true pitch $-$15 deg — off by 30 deg")]:
    meas = reproject(YAW_TRUE, p_deg * DEG)
    curve = cost_curve(meas, grid_fine)
    axA.plot(grid_fine / DEG, curve, color=col, lw=lw, label=lab)
    mins = [i for i in range(1, len(curve) - 1)
            if curve[i] < curve[i - 1] and curve[i] < curve[i + 1]]
    for i in mins:
        axA.plot(grid_fine[i] / DEG, curve[i], "o", color=col, ms=7.0,
                 mec="white", mew=1.2, zorder=6)
    if len(mins) == 2:
        lo, hi = sorted(mins, key=lambda j: curve[j])
        xm = grid_fine[lo] / DEG
        axA.annotate("", xy=(xm, curve[lo]), xytext=(xm, curve[hi]),
                     arrowprops=dict(arrowstyle="<->", color=col, lw=1.1))
        right = (p_deg == 0)
        axA.text(xm + (1.6 if right else -1.6), (curve[lo] + curve[hi]) / 2 + (1.6 if right else 0),
                 f"margin {curve[hi] - curve[lo]:.1f} px", color=col, fontsize=8.3,
                 va="center", ha="left" if right else "right", fontweight="bold")

axA.axvline(YAW_TRUE / DEG, color=GRAY, ls="--", lw=1.2)
axA.text(YAW_TRUE / DEG + 1.4, 20.5, "true yaw\n25 deg", color=GRAY,
         fontsize=8.8, linespacing=1.2)
axA.annotate("secondary\nlocal minimum", xy=(-2.2, 6.6), xytext=(-19, 13.0),
             color=INK, fontsize=8.5, linespacing=1.25, ha="center",
             arrowprops=dict(arrowstyle="->", color=INK, lw=0.9))
axA.set_ylim(-1.2, 26)
axA.set_xlim(-32, 46)
axA.set_xlabel("candidate armor yaw [deg]   (code grid offsets: $-$70 ... +69 deg)")
axA.set_ylabel("reprojection cost [px], sum of 4 corners")
axA.set_title("A. reprojection objective under pitch-prior mismatch\n"
              "one synthetic pose; target position held fixed", fontsize=10.4)
axA.legend(fontsize=8.4, loc="upper left", framealpha=0.95)
axA.grid(alpha=0.25, lw=0.6)

# ---------------- panel B: what noise then does ---------------------------
rng = np.random.default_rng(20250815)
pitch_scan = np.arange(-25, 36, 2.5)
flip, rms = [], []
for p in pitch_scan:
    m0 = reproject(YAW_TRUE, p * DEG)
    meas = m0[None, :, :] + rng.normal(0.0, PIX_NOISE, (TRIALS, 4, 2))
    err = (search_batch(meas) - YAW_TRUE) / DEG
    flip.append(100.0 * np.mean(np.abs(err) > 10.0))
    rms.append(np.sqrt(np.mean(err ** 2)))

axB.plot(pitch_scan, flip, "-", color=MAGENTA, lw=2.2,
         label=f"large yaw error ($|$err$|>$10 deg), {TRIALS} trials")
axB.set_ylabel("large-yaw-error rate [%]", color=MAGENTA)
axB.tick_params(axis="y", colors=MAGENTA)
axB.set_ylim(-3, 78)

axB2 = axB.twinx()
axB2.plot(pitch_scan, rms, "--", color=BLUE, lw=1.9, label="RMS yaw error")
axB2.set_ylabel("RMS yaw error [deg]", color=BLUE)
axB2.tick_params(axis="y", colors=BLUE)
axB2.set_ylim(-1, 26)

axB.axvline(15, color=GRAY, ls="--", lw=1.2)
axB.text(15.9, 40, "prior assumes\npitch = 15 deg", color=GRAY, fontsize=8.8, linespacing=1.2)
axB.axvspan(-25, 0, color=MAGENTA, alpha=0.07)
axB.text(-13.5, 25, "prior error\n$\\geq$15 deg", color=MAGENTA, fontsize=8.8, ha="center",
         linespacing=1.2)
axB.set_xlabel(f"true armor pitch [deg]   (corner noise {PIX_NOISE:.0f} px, 1$\\sigma$)")
axB.set_title("B. grid-search sensitivity in the same synthetic pose\n"
              "Monte Carlo corner noise; not field-accuracy data", fontsize=10.4)
h1, l1 = axB.get_legend_handles_labels()
h2, l2 = axB2.get_legend_handles_labels()
axB.legend(h1 + h2, l1 + l2, fontsize=8.4, loc="upper left", framealpha=0.95)
axB.grid(alpha=0.25, lw=0.6)

fig.tight_layout()
repo_root = Path(__file__).resolve().parents[2]
out = repo_root / "chapters/6.Projects/images/proj-sp-yaw-optimize.png"
fig.savefig(out, dpi=150, bbox_inches="tight")
print("wrote", out.relative_to(repo_root))

# --- numbers quoted in the prose -----------------------------------------
print("\npitch_true  large-err%%   RMS err [deg]   (noise %.1f px, %d trials)"
      % (PIX_NOISE, TRIALS))
for p in (15, 5, 0, -10, -15):
    i = int(np.flatnonzero(np.isclose(pitch_scan, p))[0])
    print(f"{p:8d}  {flip[i]:9.1f}  {rms[i]:12.1f}")

print("\nnoise-free local minima of the cost:")
for p in (15, 0, -15):
    meas = reproject(YAW_TRUE, p * DEG)
    curve = cost_curve(meas, grid_fine)
    mins = [i for i in range(1, len(curve) - 1)
            if curve[i] < curve[i - 1] and curve[i] < curve[i + 1]]
    print(f"  pitch_true={p:4d}: " +
          ", ".join(f"yaw {grid_fine[i]/DEG:6.1f} deg / cost {curve[i]:5.2f} px" for i in mins))
