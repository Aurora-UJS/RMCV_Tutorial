# 图：狭长损失谷地上，朴素梯度下降 vs 动量法的 60 步轨迹
# 损失取 L = (0.01*w1^2 + w2^2)/2（条件数 100 的二次谷地），轨迹与终点损失均实际算出。
# 产出：chapters/2.Theory/images/theory-dl-optimizers.png
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

OUTPUT = (Path(__file__).resolve().parents[2]
          / "chapters/2.Theory/images/theory-dl-optimizers.png")

A, B = 0.01, 1.0          # 两个方向的曲率：w1 平缓，w2 陡峭


def loss(p):
    return 0.5 * (A * p[0] ** 2 + B * p[1] ** 2)


def grad(p):
    return np.array([A * p[0], B * p[1]])


start = np.array([-9.0, 2.5])
steps = 60
lr = 1.8                   # 接近 GD 稳定上界 2/B：高曲率方向反复换向

# 朴素梯度下降
p = start.copy()
traj_gd = [p.copy()]
for _ in range(steps):
    p = p - lr * grad(p)
    traj_gd.append(p.copy())
traj_gd = np.array(traj_gd)

# 动量法：v 累积历史梯度，反复变号的分量会部分抵消
p = start.copy()
v = np.zeros(2)
beta, lr_m = 0.9, 0.4
traj_mo = [p.copy()]
for _ in range(steps):
    v = beta * v + grad(p)
    p = p - lr_m * v
    traj_mo.append(p.copy())
traj_mo = np.array(traj_mo)

L_gd, L_mo = loss(traj_gd[-1]), loss(traj_mo[-1])

# --- 画图 ---
BLUE, VERM = "#0072B2", "#D55E00"
gx, gy = np.meshgrid(np.linspace(-10.5, 3.5, 300), np.linspace(-3.2, 3.2, 300))
Z = 0.5 * (A * gx ** 2 + B * gy ** 2)

fig, ax = plt.subplots(figsize=(9.5, 4.2), dpi=150)
ax.contour(gx, gy, Z, levels=np.geomspace(0.02, 4, 10),
           colors="#999999", linewidths=0.6, alpha=0.8)
ax.plot(traj_gd[:, 0], traj_gd[:, 1], "-o", c=BLUE, ms=2.6, lw=1.1,
        label=f"gradient descent, loss {L_gd:.2f}")
ax.plot(traj_mo[:, 0], traj_mo[:, 1], "-^", c=VERM, ms=3.0, lw=1.1,
        label=f"momentum ($\\beta$=0.9), loss {L_mo:.4f}")
ax.plot(*start, "ks", ms=7, zorder=5)
ax.annotate("start", start + [0.15, 0.18], fontsize=9)
ax.plot(0, 0, "k*", ms=13, zorder=5)
ax.annotate("minimum", (0.2, -0.35), fontsize=9)
ax.set_title(f"Same quadratic and start, {steps} updates: momentum ends at lower loss\n"
             "with the learning rates shown in the script", fontsize=11)
ax.set_xlabel("$w_1$ (flat direction)")
ax.set_ylabel("$w_2$ (steep direction)")
ax.legend(loc="lower right", fontsize=9, framealpha=0.9)
ax.grid(alpha=0.2, linewidth=0.5)
fig.tight_layout()
fig.savefig(OUTPUT, bbox_inches="tight")
print(f"final loss: GD = {L_gd:.4f}, momentum = {L_mo:.6f}")
