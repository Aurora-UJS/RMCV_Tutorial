"""比较同一个像素在三种场地模型下的投影结果。

侧视剖面（X-Z 平面）上做纯几何推导，非实测：
  相机架在 (0, H)，场地由一段平地（z=0）和一块高地（z=Zp）拼成。
  目标车停在高地上，接地点 (Xt, Zp)，其对应像素射线从相机光心出发穿过该点。

  ① 单张平地单应  = 射线与 z=0 假想水平面求交
  ② 分层单应      = 先判层，再与该层平面求交（判对 → 与 ③ 重合；判错 → 退化成 ①）
  ③ 网格射线求交  = 射线与简化场地剖面求交

输出：chapters/5.Advanced/images/adv-radar-three-lifts.png
"""

import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

BLUE = "#3B6FD4"
MAGENTA = "#D6336C"
GRAY = "#8A8A8A"
DARKGRAY = "#4A4A4A"

# ---- 场地与相机（简化剖面） -------------------------------------------------
H = 2.5          # 相机高度 m（手册给的雷达台面高度）
ZP = 0.4         # 高地台面高度 m
X_EDGE = 12.0    # 高地前沿的水平位置 m
X_FAR = 22.0     # 剖面画到哪里
XT = 14.0        # 目标车接地点的水平坐标 m（站在高地上）


def hit_plane(x_t, z_t, z_plane):
    """相机 (0,H) 经过 (x_t, z_t) 的射线，与水平面 z=z_plane 的交点横坐标。"""
    # P(s) = (0,H) + s*(x_t, z_t-H)；令 z 分量 = z_plane
    denom = H - z_t
    if abs(denom) < 1e-9:
        return np.inf
    s = (H - z_plane) / denom
    return x_t * s


def hit_mesh(x_t, z_t):
    """射线与建模剖面求交：先试高地台面，落在高地范围内则命中，否则落到地面。"""
    x_on_plat = hit_plane(x_t, z_t, ZP)
    if x_on_plat >= X_EDGE:
        return x_on_plat, ZP
    return hit_plane(x_t, z_t, 0.0), 0.0


x1 = hit_plane(XT, ZP, 0.0)          # ① 平地单应
x3, z3 = hit_mesh(XT, ZP)            # ③ 射线求交
x2 = x3                              # ② 分层单应，层判正确时与 ③ 相同
err1 = x1 - XT
err3 = x3 - XT

fig = plt.figure(figsize=(11.0, 8.8))
gs = fig.add_gridspec(2, 1, height_ratios=[1.18, 1.0], hspace=0.36)

# =============== 上：侧视几何 =================================================
ax = fig.add_subplot(gs[0])

prof_x = [0, X_EDGE, X_EDGE, X_FAR]
prof_z = [0, 0, ZP, ZP]
ax.fill_between(prof_x, prof_z, -1.9, color=GRAY, alpha=0.20, zorder=1)
ax.plot(prof_x, prof_z, color=DARKGRAY, lw=2.4, zorder=4,
        label="modeled field profile (flat + 0.4 m platform)")

# 假想水平面
ax.plot([0, X_FAR], [0, 0], color=GRAY, lw=1.2, ls=(0, (6, 4)), zorder=3,
        label="assumed flat plane $z=0$")

# 相机与射线
ax.plot([0], [H], marker="o", ms=11, color=DARKGRAY, zorder=6)
ax.annotate(f"camera  $h$ = {H} m", xy=(0, H), xytext=(0.5, H + 0.42),
            fontsize=11, color=DARKGRAY, weight="bold")

# 实线段：光心 → 模型命中点；虚线段：穿过场地的"虚拟延长"，只为画出 (1) 的落点
ax.plot([0, XT], [H, ZP], color=BLUE, lw=2.4, alpha=0.9, zorder=5,
        label="ray of ONE pixel (robot's ground-contact pixel)")
ray_end = x1 * 1.02
ax.plot([XT, ray_end], [ZP, H + (ZP - H) * ray_end / XT], color=BLUE, lw=1.6,
        alpha=0.55, ls=(0, (4, 3)), zorder=5,
        label="virtual extension (ray already hit the field here)")

# 模型设定的接触点（车身示意 + 星标）
ax.plot([XT, XT], [ZP, ZP + 0.62], color=DARKGRAY, lw=7, alpha=0.30,
        solid_capstyle="butt", zorder=4)
ax.plot([XT], [ZP], marker="*", ms=19, color=DARKGRAY, zorder=8)
ax.annotate("modeled contact point\n$x$ = 14.00 m", xy=(XT, ZP),
            xytext=(XT - 4.2, ZP + 1.05), fontsize=10.5, color=DARKGRAY,
            ha="center", weight="bold",
            arrowprops=dict(arrowstyle="->", color=DARKGRAY, lw=1.2))

# ① 平地单应命中点
ax.plot([x1], [0], marker="o", ms=13, mfc="white", mec=BLUE, mew=2.6, zorder=9)
ax.annotate(f"(1) flat homography\n$x$ = {x1:.2f} m", xy=(x1, 0.02),
            xytext=(x1 + 0.55, 1.05), fontsize=10.5, color=BLUE, weight="bold",
            arrowprops=dict(arrowstyle="->", color=BLUE, lw=1.2))

# ②/③ 命中点（重合）
ax.plot([x3], [z3], marker="s", ms=16, mfc="none", mec=GRAY, mew=2.8, zorder=9)
ax.plot([x3], [z3], marker="o", ms=8, color=MAGENTA, zorder=10)
ax.annotate("(2) layered homography  =  (3) ray-mesh intersection\n"
            "$x$ = 14.00 m   (both match the model here)",
            xy=(x3 + 0.12, z3 - 0.06), xytext=(7.2, -1.35), fontsize=10.5,
            color=MAGENTA, ha="center", weight="bold",
            arrowprops=dict(arrowstyle="->", color=MAGENTA, lw=1.2))

# 误差连线
ax.annotate("", xy=(XT, -0.42), xytext=(x1, -0.42),
            arrowprops=dict(arrowstyle="<->", color=BLUE, lw=1.8))
ax.plot([XT, XT], [ZP, -0.42], color=BLUE, lw=0.9, ls=":", zorder=4)
ax.plot([x1, x1], [0.0, -0.42], color=BLUE, lw=0.9, ls=":", zorder=4)
ax.text((XT + x1) / 2, -0.55, f"error {err1:.2f} m", ha="center", va="top",
        fontsize=11, color=BLUE, weight="bold")

ax.set_xlim(-0.8, X_FAR)
ax.set_ylim(-1.9, 3.45)
ax.set_xlabel("horizontal distance from radar  $x$  [m]")
ax.set_ylabel("height  $z$  [m]")
ax.set_title("One pixel projected with three terrain models  —  the flat-plane estimate "
             f"differs by {err1:.2f} m in this {ZP} m platform example",
             fontsize=12.5, weight="bold", pad=10)
ax.legend(loc="upper right", fontsize=8.8, framealpha=0.94,
          borderpad=0.5, labelspacing=0.42)
ax.grid(alpha=0.22, ls=":")

# =============== 下：误差随距离 ===============================================
ax2 = fig.add_subplot(gs[1])

xs = np.linspace(X_EDGE + 0.3, X_FAR, 400)
e_flat = np.array([hit_plane(x, ZP, 0.0) - x for x in xs])
e_ray = np.zeros_like(xs)

ax2.plot(xs, e_flat, color=BLUE, lw=2.6, zorder=5,
         label="(1) flat homography")
ax2.plot(xs, e_flat, color=GRAY, lw=6.0, alpha=0.35, ls=(0, (2, 2)), zorder=3,
         label="(2) layered homography, WRONG layer  (degenerates to 1)")
ax2.plot(xs, e_ray + 0.02, color=GRAY, lw=6.0, alpha=0.55, zorder=4,
         label="(2) layered homography, RIGHT layer")
ax2.plot(xs, e_ray, color=MAGENTA, lw=2.2, zorder=6,
         label="(3) ray-mesh intersection  (uses modeled surface)")

ax2.axhline(0.8, color=DARKGRAY, lw=1.4, ls=(0, (5, 3)), zorder=2)
ax2.text(X_FAR - 0.2, 0.86, "rule: 0.8 m = accurate threshold", ha="right",
         fontsize=10, color=DARKGRAY, weight="bold")
ax2.axhline(1.6, color=DARKGRAY, lw=1.2, ls=(0, (2, 3)), zorder=2)
ax2.text(X_FAR - 0.2, 1.66, "rule: 1.6 m = inaccurate threshold", ha="right",
         fontsize=10, color=DARKGRAY)

ax2.plot([XT], [err1], marker="o", ms=11, mfc="white", mec=BLUE, mew=2.4, zorder=8)
ax2.annotate(f"the case drawn above:\n{err1:.2f} m at $x$ = {XT:.0f} m",
             xy=(XT, err1 - 0.12), xytext=(XT + 0.9, 0.14), fontsize=10.5,
             color=BLUE, weight="bold",
             arrowprops=dict(arrowstyle="->", color=BLUE, lw=1.2))

ax2.set_xlim(X_EDGE, X_FAR)
ax2.set_ylim(-0.35, 5.6)
ax2.set_xlabel("modeled target distance from radar  [m]")
ax2.set_ylabel("horizontal position error  [m]")
ax2.set_title("Layered homography depends on region selection: in this example, "
              "the correct layer matches the modeled mesh",
              fontsize=12, weight="bold", pad=10)
ax2.legend(loc="upper left", fontsize=9.2, framealpha=0.94, ncol=2)
ax2.grid(alpha=0.22, ls=":")

fig.suptitle("DERIVED GEOMETRY, NOT MEASURED  —  pinhole camera at h = 2.5 m, "
             "simplified field profile (flat + one 0.4 m platform)",
             fontsize=10.5, color=DARKGRAY, y=0.985)

out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "..", "chapters", "5.Advanced", "images")
out = os.path.normpath(os.path.join(out_dir, "adv-radar-three-lifts.png"))
fig.savefig(out, dpi=150, bbox_inches="tight")
print("saved:", out)
print(f"  flat-homography hit x = {x1:.4f} m,  error = {err1:.4f} m")
print(f"  ray-mesh        hit x = {x3:.4f} m,  error = {err3:.4f} m")
