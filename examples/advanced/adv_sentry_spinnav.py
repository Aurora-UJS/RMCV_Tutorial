"""进阶篇 · 哨兵决策视觉：云台自旋如何拧歪导航指令。

机理（推导，非实测）：
Nav2 的 robot_base_frame 若绑在自旋的云台 yaw 系上，控制器算出世界系方向 d̂ 后，
按约定发出的是 R(psi)^-1 · d̂；而底盘按自己（近似不转）的朝向执行这三个数，
于是实际世界系方向变成 R(-psi) · d̂ —— 与期望方向差了整整一个云台偏航角 psi。
云台扫一圈，误差扫过 360°，净位移期望为零。

本脚本用闭环仿真复现：每个控制周期重新朝目标点规划一次方向，
分别执行「不补偿」（方向被 R(-psi) 旋掉）与「补偿」（虚拟系方案）两种情况。

输出：chapters/5.Advanced/images/adv-sentry-spinnav.png
"""

import os

import matplotlib
import numpy as np

matplotlib.use("Agg")
import matplotlib.pyplot as plt

BLUE = "#3B6FD4"
MAGENTA = "#D6336C"
GREY = "#8A8A8A"

# ---- 仿真参数 ----
V = 1.5          # m/s，底盘线速度
OMEGA = 2.0      # rad/s，云台自旋扫描角速度
DT_CTRL = 0.05   # s，Nav2 控制周期（20 Hz）
T_END = 6.0      # s
GOAL = np.array([5.0, 0.0])


def rot(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s], [s, c]])


def simulate(compensate):
    """每个控制周期朝目标重规划一次；compensate=False 时执行方向被 R(-psi) 旋掉。"""
    p = np.array([0.0, 0.0])
    t = 0.0
    ts, ps = [t], [p.copy()]
    while t < T_END:
        d = GOAL - p
        n = np.linalg.norm(d)
        if n < 0.05:                       # 到点即停
            ts.append(T_END)
            ps.append(p.copy())
            break
        d_hat = d / n
        psi = OMEGA * t                    # 该周期起始时刻的云台偏航角
        exec_dir = d_hat if compensate else rot(-psi) @ d_hat
        p = p + V * exec_dir * DT_CTRL
        t += DT_CTRL
        ts.append(t)
        ps.append(p.copy())
    return np.array(ts), np.array(ps)


t_ok, p_ok = simulate(True)
t_bad, p_bad = simulate(False)

d_ok = np.linalg.norm(p_ok - GOAL, axis=1)
d_bad = np.linalg.norm(p_bad - GOAL, axis=1)
t_reach = t_ok[np.argmax(d_ok < 0.05)] if (d_ok < 0.05).any() else np.nan
progress_bad = np.linalg.norm(p_bad[-1] - p_bad[0])
d_bad_min = d_bad.min()

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12.0, 5.0))

# ---- 左：世界系轨迹 ----
ax1.plot(p_bad[:, 0], p_bad[:, 1], lw=3.0, color=MAGENTA, alpha=0.85,
         label="uncompensated (base frame spins)")
ax1.plot(p_ok[:, 0], p_ok[:, 1], lw=4.0, color=BLUE, alpha=0.55,
         label="compensated (fake fixed-yaw frame)")
ax1.plot([0, GOAL[0]], [0, GOAL[1]], ls="--", lw=1.3, color=GREY, zorder=4,
         label="intended straight path")
ax1.plot(0, 0, "o", ms=8, color="k", zorder=5)
ax1.annotate("start", (0, 0), textcoords="offset points", xytext=(6, -16), fontsize=9)
ax1.plot(*GOAL, "*", ms=15, color="k", zorder=5)
ax1.annotate("goal (5 m)", GOAL, textcoords="offset points", xytext=(-30, 12), fontsize=9)
ax1.set_xlabel("x in odom frame [m]")
ax1.set_ylabel("y in odom frame [m]")
ax1.set_title("World-frame path, 6 s of navigation")
ax1.set_aspect("equal", adjustable="datalim")
ax1.grid(alpha=0.25)
ax1.legend(fontsize=8.5, loc="upper left")

# ---- 右：离目标距离 ----
ax2.plot(t_bad, d_bad, lw=2.6, color=MAGENTA, alpha=0.85, label="uncompensated")
ax2.plot(t_ok, d_ok, lw=2.6, color=BLUE, alpha=0.85, label="compensated")
ax2.axhline(np.linalg.norm(GOAL), ls=":", lw=1.2, color=GREY)
ax2.annotate("initial distance", (0.15, np.linalg.norm(GOAL)),
             textcoords="offset points", xytext=(2, 5), fontsize=8.5, color=GREY)
if not np.isnan(t_reach):
    ax2.plot(t_reach, 0.0, "o", ms=7, color=BLUE, zorder=5)
    ax2.annotate(f"goal reached\n{t_reach:.2f} s", (t_reach, 0.0),
                 textcoords="offset points", xytext=(8, 18), fontsize=9, color=BLUE)
ax2.set_xlabel("time [s]")
ax2.set_ylabel("distance to goal [m]")
ax2.set_title(f"Uncompensated never gets closer than {d_bad_min:.1f} m")
ax2.grid(alpha=0.25)
ax2.legend(fontsize=9, loc="center right")

fig.suptitle(
    "Spinning gimbal rotates every velocity command by the full gimbal yaw:\n"
    f"goal reached in {t_reach:.1f} s when compensated, never in {T_END:.0f} s when not "
    f"(v={V} m/s, spin={OMEGA} rad/s, {int(1 / DT_CTRL)} Hz control; derived, not measured)",
    fontsize=11,
)
fig.tight_layout(rect=(0, 0, 1, 0.90))

out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "chapters", "5.Advanced", "images",
                   "adv-sentry-spinnav.png")
fig.savefig(os.path.normpath(out), dpi=150)
print("saved:", os.path.normpath(out))
print(f"uncompensated net displacement = {progress_bad:.3f} m; "
      f"compensated reaches goal at {t_reach:.2f} s")
