# 图：线性模型 vs 带非线性激活的 MLP 在 XOR 形数据上的决策边界
# 两个模型都用 numpy 手写梯度下降训练，准确率由脚本实际算出并写进标题。
# 产出：chapters/2.Theory/images/theory-dl-nonlinearity.png
import numpy as np
import matplotlib.pyplot as plt

rng = np.random.default_rng(7)

# XOR 形数据：对角的两簇为一类
n = 60
centers = [(0, 0), (1, 1), (0, 1), (1, 0)]
X = np.vstack([rng.normal(c, 0.13, size=(n, 2)) for c in centers])
y = np.array([0] * (2 * n) + [1] * (2 * n)).astype(float)


def sigmoid(z):
    return 1.0 / (1.0 + np.exp(-z))


# --- 模型 1：逻辑回归（线性决策边界） ---
w = np.zeros(2)
b = 0.0
lr = 0.5
for _ in range(3000):
    p = sigmoid(X @ w + b)
    g = p - y                       # softmax/sigmoid + 交叉熵的梯度：p - y
    w -= lr * (X.T @ g) / len(y)
    b -= lr * g.mean()
acc_lin = ((sigmoid(X @ w + b) > 0.5) == y).mean()

# --- 模型 2：MLP 2-8-1，tanh 激活 ---
W1 = rng.normal(0, 1.0, (2, 8))
b1 = np.zeros(8)
W2 = rng.normal(0, 1.0, (8, 1))
b2 = np.zeros(1)
lr = 0.5
for _ in range(6000):
    H = np.tanh(X @ W1 + b1)                     # 前向
    p = sigmoid((H @ W2 + b2).ravel())
    g = (p - y)[:, None] / len(y)                # 反向：链式法则逐层回传
    gW2 = H.T @ g
    gH = g @ W2.T * (1 - H ** 2)
    W2 -= lr * gW2
    b2 -= lr * g.sum(axis=0)
    W1 -= lr * X.T @ gH
    b1 -= lr * gH.sum(axis=0)
H = np.tanh(X @ W1 + b1)
acc_mlp = ((sigmoid((H @ W2 + b2).ravel()) > 0.5) == y).mean()

# --- 画图 ---
BLUE, VERM = "#0072B2", "#D55E00"   # Okabe-Ito，全章统一：蓝=类 0，橙红=类 1
gx, gy = np.meshgrid(np.linspace(-0.6, 1.6, 300), np.linspace(-0.6, 1.6, 300))
G = np.c_[gx.ravel(), gy.ravel()]

fig, axes = plt.subplots(1, 2, figsize=(10, 4.4), dpi=150)
preds = [
    sigmoid(G @ w + b).reshape(gx.shape),
    sigmoid((np.tanh(G @ W1 + b1) @ W2 + b2).ravel()).reshape(gx.shape),
]
titles = [
    f"Linear model: accuracy {acc_lin:.0%}",
    f"MLP 2-8-1 (tanh): accuracy {acc_mlp:.0%}",
]
for ax, P, t in zip(axes, preds, titles):
    ax.contourf(gx, gy, P, levels=[0, 0.5, 1], colors=["#c8dcec", "#f4d3c0"], alpha=0.7)
    ax.contour(gx, gy, P, levels=[0.5], colors="#555555", linewidths=1.2)
    m0, m1 = y == 0, y == 1
    ax.scatter(X[m0, 0], X[m0, 1], s=18, c=BLUE, marker="o", label="class 0", zorder=3)
    ax.scatter(X[m1, 0], X[m1, 1], s=22, c=VERM, marker="^", label="class 1", zorder=3)
    ax.set_title(t, fontsize=11)
    ax.set_xlim(-0.6, 1.6)
    ax.set_ylim(-0.6, 1.6)
    ax.set_xticks([0, 1])
    ax.set_yticks([0, 1])
    ax.set_xlabel("$x_1$")
    ax.grid(alpha=0.25, linewidth=0.5)
axes[0].set_ylabel("$x_2$")
axes[0].legend(loc="upper left", fontsize=9, framealpha=0.9)
axes[0].text(0.5, -0.45, "no straight line separates XOR", ha="center",
             fontsize=9, style="italic", color="#333333")
axes[1].text(0.5, -0.45, "hidden layer bends the space", ha="center",
             fontsize=9, style="italic", color="#333333")
fig.tight_layout()
fig.savefig("/home/neomelt/RMCV_Tutorial/chapters/2.Theory/images/theory-dl-nonlinearity.png",
            bbox_inches="tight")
print(f"acc linear = {acc_lin:.3f}, acc mlp = {acc_mlp:.3f}")
