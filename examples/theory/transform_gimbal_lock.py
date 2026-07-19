# Gimbal lock demonstration for the coordinate-transform chapter.
# At pitch = -90 deg (ZYX intrinsic Euler, nose straight up), extra yaw and
# extra roll rotate the body about the same physical axis: panels (b) and (c)
# end up in exactly the same attitude.
# Output: chapters/2.Theory/images/theory-transform-gimbal-lock.png
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

def Rx(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])

def Ry(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])

def Rz(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])

def euler_zyx(yaw, pitch, roll):
    return Rz(yaw) @ Ry(pitch) @ Rx(roll)

# Body glyph: a flat pentagon "pointer" in the body x-y plane, nose along +x.
PLATE = np.array([
    [1.0, 0.0, 0.0],     # nose
    [0.35, 0.45, 0.0],
    [-0.55, 0.45, 0.0],
    [-0.55, -0.45, 0.0],
    [0.35, -0.45, 0.0],
]).T

AXIS_COLORS = {"x": "#d1495b", "y": "#2e7d32", "z": "#1565c0"}  # RViz-style x/y/z

LABEL_NUDGE = {"x": np.array([0.24, 0.0, 0.0]),  # x_b points up: shift sideways
               "y": np.array([0.0, 0.0, 0.14]),
               "z": np.array([0.0, 0.0, 0.16])}

def draw_frame(ax, R, alpha=1.0, lw=2.2, length=1.15, labels=True):
    for i, name in enumerate(["x", "y", "z"]):
        v = R[:, i] * length
        ax.quiver(0, 0, 0, *v, color=AXIS_COLORS[name], alpha=alpha,
                  lw=lw, arrow_length_ratio=0.12)
        if labels:
            ax.text(*(v * 1.18 + LABEL_NUDGE[name]), f"${name}_b$",
                    color=AXIS_COLORS[name], fontsize=10,
                    ha="center", va="center", alpha=alpha)

def draw_plate(ax, R, alpha=0.4):
    p = R @ PLATE
    poly = Poly3DCollection([list(zip(p[0], p[1], p[2]))], facecolor="#8d99ae",
                            edgecolor="#333333", alpha=alpha, lw=1.0)
    ax.add_collection3d(poly)
    nose = R @ np.array([1.0, 0.0, 0.0])
    ax.scatter(*nose, color="#333333", s=20, alpha=min(1.0, alpha + 0.4))

def setup_ax(ax, title):
    ax.set_title(title, fontsize=10.5)
    lim = 1.35
    ax.set_xlim(-lim, lim); ax.set_ylim(-lim, lim); ax.set_zlim(-lim, lim)
    ax.set_box_aspect((1, 1, 1))
    ax.set_xticks([]); ax.set_yticks([]); ax.set_zticks([])
    # faint world frame for reference (unlabeled; explained in the caption)
    for i in range(3):
        v = np.eye(3)[:, i] * 1.3
        ax.quiver(0, 0, 0, *v, color="#999999", alpha=0.45, lw=1.0,
                  arrow_length_ratio=0.08)
    ax.view_init(elev=20, azim=-40)

yaw0, pitch0, roll0 = np.deg2rad(20), np.deg2rad(-90), 0.0  # nose straight up
d = np.deg2rad(25)

R_a = euler_zyx(yaw0, pitch0, roll0)          # base attitude
R_b = euler_zyx(yaw0 + d, pitch0, roll0)      # extra yaw +25 deg
R_c = euler_zyx(yaw0, pitch0, roll0 + d)      # extra roll +25 deg

assert np.allclose(R_b, R_c, atol=1e-12), "gimbal lock demo broken"

fig = plt.figure(figsize=(10.5, 4.0))
titles = [
    "(a) yaw 20°, pitch −90°, roll 0°",
    "(b) extra yaw +25°",
    "(c) extra roll +25°  → same as (b)",
]
for k, (R, title) in enumerate(zip([R_a, R_b, R_c], titles)):
    ax = fig.add_subplot(1, 3, k + 1, projection="3d")
    setup_ax(ax, title)
    if k > 0:  # ghost of the base attitude for comparison
        draw_frame(ax, R_a, alpha=0.15, lw=1.4, labels=False)
        draw_plate(ax, R_a, alpha=0.08)
    draw_frame(ax, R)
    draw_plate(ax, R)

fig.suptitle("Gimbal lock: at pitch = ±90°, yaw and roll rotate about the same axis",
             fontsize=12)
fig.tight_layout(rect=(0, 0, 1, 0.94))
out = "chapters/2.Theory/images/theory-transform-gimbal-lock.png"
fig.savefig(out, dpi=150, bbox_inches="tight")
print("saved", out)
print("max |R_b - R_c| =", np.abs(R_b - R_c).max())
