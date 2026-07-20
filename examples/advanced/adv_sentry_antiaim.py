"""进阶篇 · 哨兵决策视觉：反自瞄机动为什么能破掉匀速模型预测。

机理（推导 + 仿真，非实测）：
敌方跟踪器用匀速模型（CV）卡尔曼滤波，瞄准点取 x̂ + v̂·t_fly。
若目标在 t_fly 窗口内把横向速度从 +u 翻成 −u，敌方仍按翻转前的速度外推，
落点误差瞬间冲到 Δ ≈ 2·u·t_fly；随后随滤波器重新收敛而衰减。
只要 |误差| 超过装甲板半宽，这一发必然脱靶。

左图：一条 1 m/s、每 1.0 s 反向的横移的时间序列。
右图：脱靶时间占比随反向周期的扫描（设计旋钮）。
⚠ 仿真假设速度可瞬时反向，真实底盘受加速度限制，短周期段是乐观上界。

输出：chapters/5.Advanced/images/adv-sentry-antiaim.png
"""

import os

import matplotlib
import numpy as np

matplotlib.use("Agg")
import matplotlib.pyplot as plt

BLUE = "#3B6FD4"
MAGENTA = "#D6336C"
GREY = "#8A8A8A"

# ---- 场景参数 ----
U = 1.0             # m/s，横移速度
FS = 100.0          # Hz，敌方量测频率
SIGMA_MEAS = 0.02   # m，PnP 横向量测噪声（1 sigma）
Q_ACC = 4.0         # (m/s^2)^2，CV 模型的过程噪声谱密度（把加速度当噪声吸收）
BULLET_V = 25.0     # m/s，2026 手册 17 mm 初速上限（随赛季变动）
RANGE_M = 5.0       # m，交战距离
T_FLY = RANGE_M / BULLET_V
HALF_W = 0.0675     # m，小装甲板半宽（按 PnP 用的 135 mm 灯条间距折半，全书统一口径）
T_END = 8.0
RNG_SEED = 20260720


def true_lateral(t, t_leg):
    """每 t_leg 秒反向一次的横移：返回位置与速度。"""
    leg = np.floor(t / t_leg).astype(int)
    sign = np.where(leg % 2 == 0, 1.0, -1.0)
    # 位置 = 已走完各段的累积 + 本段内的位移
    n_full = leg
    # 偶数段 +U、奇数段 −U，每段位移 ±U·t_leg，故累积在 0 与 U·t_leg 间摆
    cum = np.where(n_full % 2 == 0, 0.0, U * t_leg)
    pos = cum + sign * U * (t - n_full * t_leg)
    return pos, sign * U


def run_cv_filter(t, z, dt):
    """标准 2 维匀速模型卡尔曼滤波（位置、速度），返回 t_fly 后的外推落点。"""
    F = np.array([[1.0, dt], [0.0, 1.0]])
    G = np.array([[0.5 * dt * dt], [dt]])
    Q = G @ G.T * Q_ACC
    H = np.array([[1.0, 0.0]])
    R = np.array([[SIGMA_MEAS ** 2]])

    x = np.array([[z[0]], [0.0]])
    P = np.diag([SIGMA_MEAS ** 2, 4.0])
    pred = np.empty_like(t)
    for k in range(len(t)):
        if k > 0:
            x = F @ x
            P = F @ P @ F.T + Q
        y = np.array([[z[k]]]) - H @ x
        S = H @ P @ H.T + R
        K = P @ H.T @ np.linalg.inv(S)
        x = x + K @ y
        P = (np.eye(2) - K @ H) @ P
        pred[k] = x[0, 0] + x[1, 0] * T_FLY   # 提前量：按估计速度外推一个飞行时间
    return pred


def miss_fraction(t_leg, seed):
    dt = 1.0 / FS
    t = np.arange(0.0, T_END, dt)
    pos, _ = true_lateral(t, t_leg)
    rng = np.random.default_rng(seed)
    z = pos + rng.normal(0.0, SIGMA_MEAS, size=t.shape)
    pred = run_cv_filter(t, z, dt)
    # 真值也要外推：t_fly 之后目标真正在哪
    pos_future, _ = true_lateral(t + T_FLY, t_leg)
    err = pred - pos_future
    # 掐掉前 0.5 s 的滤波器初始化瞬态，只统计稳态
    mask = t > 0.5
    return t, pos, pos_future, pred, err, float(np.mean(np.abs(err[mask]) > HALF_W))


T_LEG_MAIN = 1.0
t, pos, pos_future, pred, err, frac_main = miss_fraction(T_LEG_MAIN, RNG_SEED)

legs = np.linspace(0.2, 3.0, 29)
fracs = [miss_fraction(L, RNG_SEED + i)[-1] for i, L in enumerate(legs)]

fig = plt.figure(figsize=(12.8, 5.4))
gs = fig.add_gridspec(2, 2, width_ratios=[1.6, 1.0], hspace=0.34, wspace=0.26,
                      left=0.065, right=0.985, top=0.80, bottom=0.10)
axa = fig.add_subplot(gs[0, 0])
axb = fig.add_subplot(gs[1, 0], sharex=axa)
ax2 = fig.add_subplot(gs[:, 1])

axa.plot(t, pos_future, lw=3.2, color=GREY, alpha=0.75,
         label=r"true position at $t+t_{fly}$")
axa.plot(t, pred, lw=1.6, color=BLUE, label="enemy CV-filter aim point")
axa.set_ylabel("lateral position [m]")
axa.set_title(f"Zigzag at {U} m/s, reversing every {T_LEG_MAIN} s")
axa.grid(alpha=0.25)
axa.legend(fontsize=8.5, loc="upper right", ncol=2)
plt.setp(axa.get_xticklabels(), visible=False)

miss = np.abs(err) > HALF_W
axb.fill_between(t, -0.45, 0.45, where=miss, color=GREY, alpha=0.18, step="mid",
                 label="miss (|error| > armor half-width)")
axb.axhspan(-HALF_W, HALF_W, color=MAGENTA, alpha=0.20)
axb.axhline(HALF_W, color=MAGENTA, lw=1.2)
axb.axhline(-HALF_W, color=MAGENTA, lw=1.2)
axb.annotate(f"armor half-width $\\pm${HALF_W * 1000:.1f} mm", (0.12, HALF_W),
             textcoords="offset points", xytext=(2, 5), fontsize=8.5, color=MAGENTA)
axb.plot(t, err, lw=1.6, color=BLUE)
delta = 2 * U * T_FLY
axb.axhline(delta, ls=":", lw=1.1, color="k")
axb.annotate(f"$2 u\\,t_{{fly}}$ = {delta:.2f} m", (T_END * 0.62, delta),
             textcoords="offset points", xytext=(0, 5), fontsize=8.5)
axb.set_xlabel("time [s]")
axb.set_ylabel("aim-point error [m]")
axb.set_ylim(-0.45, 0.45)
axb.set_title(f"Off target {frac_main * 100:.0f}% of the time")
axb.grid(alpha=0.25)
axb.legend(fontsize=8.5, loc="lower right")

# ---- 右：脱靶占比 vs 反向周期 ----
ax2.plot(legs, np.array(fracs) * 100, lw=2.4, color=MAGENTA)
ax2.plot(T_LEG_MAIN, frac_main * 100, "o", ms=8, color=BLUE, zorder=5)
ax2.annotate(f"left panel\n({T_LEG_MAIN} s, {frac_main * 100:.0f}%)",
             (T_LEG_MAIN, frac_main * 100), textcoords="offset points",
             xytext=(16, 6), fontsize=9, color=BLUE)
i_pk = int(np.argmax(fracs))
ax2.plot(legs[i_pk], fracs[i_pk] * 100, "v", ms=9, color="k", zorder=6)
ax2.annotate(f"peak {fracs[i_pk] * 100:.0f}% @ {legs[i_pk]:.1f} s\n(faster is worse)",
             (legs[i_pk], fracs[i_pk] * 100), textcoords="offset points",
             xytext=(10, -26), fontsize=8.5)
ax2.axvspan(0.2, 0.5, color=GREY, alpha=0.18)
ax2.annotate("optimistic:\nassumes instant\nvelocity reversal", (0.62, 62),
             fontsize=8.5, color="k")
ax2.set_xlabel("reversal period [s]")
ax2.set_ylabel("fraction of time off target [%]")
ax2.set_title("Design knob: miss rate peaks near 0.4 s")
ax2.grid(alpha=0.25)

fig.suptitle(
    "Anti-auto-aim: reversing velocity inside the flight-time window breaks the "
    "constant-velocity assumption\n"
    f"peak aim error $2u\\,t_{{fly}}$ = {delta:.2f} m is {delta / HALF_W:.1f}x the armor "
    f"half-width ($u$={U} m/s, {RANGE_M:.0f} m range, {BULLET_V:.0f} m/s bullet; "
    "simulated, not measured)",
    fontsize=10.5,
)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "chapters", "5.Advanced", "images",
                   "adv-sentry-antiaim.png")
fig.savefig(os.path.normpath(out), dpi=150)
print("saved:", os.path.normpath(out))
print(f"t_fly = {T_FLY:.3f} s, 2*u*t_fly = {delta:.3f} m = {delta / HALF_W:.2f}x half-width")
print(f"miss fraction at leg={T_LEG_MAIN}s: {frac_main * 100:.1f}%")
for L, f in zip(legs[::7], np.array(fracs)[::7]):
    print(f"  leg={L:.2f}s -> miss {f * 100:.1f}%")
