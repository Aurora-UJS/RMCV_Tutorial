# RANSAC vs least squares on outlier-contaminated line data,
# for the "traditional CV" theory chapter.
# One panel: same data, both fits on the same axes; the title carries the numbers.
# Output: chapters/2.Theory/images/theory-2-ransac.png
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

rng = np.random.default_rng(3)

BLUE = "#2a78d6"
GREEN = "#008300"
RED = "#e34948"
INK = "#0b0b0b"

# ---- data: y = 0.5 x + 10, 70 inliers (sigma=1), 30 outliers clustered high
a_true, b_true = 0.5, 10.0
x_in = rng.uniform(0, 100, 70)
y_in = a_true * x_in + b_true + rng.normal(0, 1.0, x_in.size)
x_out = rng.uniform(0, 100, 30)
y_out = rng.uniform(45, 95, 30)          # e.g. reflections above the target
X = np.concatenate([x_in, x_out])
Y = np.concatenate([y_in, y_out])

# ---- ordinary least squares on everything
A = np.vstack([X, np.ones_like(X)]).T
(a_ls, b_ls), *_ = np.linalg.lstsq(A, Y, rcond=None)

# ---- RANSAC: minimal sample s=2, threshold eps=2.5, fixed trial budget
eps, best_inl = 2.5, None
for _ in range(100):
    i, j = rng.choice(X.size, 2, replace=False)
    if X[i] == X[j]:
        continue
    a = (Y[j] - Y[i]) / (X[j] - X[i])
    b = Y[i] - a * X[i]
    d = np.abs(Y - (a * X + b)) / np.hypot(a, 1)   # point-line distance
    inl = d < eps
    if best_inl is None or inl.sum() > best_inl.sum():
        best_inl = inl
# refit on the consensus set
(a_r, b_r), *_ = np.linalg.lstsq(A[best_inl], Y[best_inl], rcond=None)

ang = lambda a: np.rad2deg(np.arctan(a))
err_ls = abs(ang(a_ls) - ang(a_true))
err_r = abs(ang(a_r) - ang(a_true))

fig, ax = plt.subplots(figsize=(8.0, 4.6), dpi=150)
ax.scatter(x_in, y_in, s=16, c=BLUE, label=f"inliers ({x_in.size})")
ax.scatter(x_out, y_out, s=22, c=RED, marker="x", linewidths=1.4,
           label=f"outliers ({x_out.size})")
xx = np.array([0, 100])
ax.plot(xx, a_true * xx + b_true, color=INK, lw=1.0, ls=":", label="true line")
ax.plot(xx, a_ls * xx + b_ls, color=RED, lw=2.0, ls="--",
        label=f"least squares (slope err {err_ls:.1f}°)")
ax.plot(xx, a_r * xx + b_r, color=GREEN, lw=2.6, alpha=0.75,
        label=f"RANSAC refit (slope err {err_r:.2f}°, {best_inl.sum()} consensus)")
ax.set_xlabel("x"); ax.set_ylabel("y")
ax.legend(loc="upper left", fontsize=8.5, framealpha=0.9)
ax.set_title(
    f"Seeded draw with 30% generated outliers: LS error {err_ls:.1f}°; "
    f"RANSAC error {err_r:.2f}°",
    fontsize=11)
fig.tight_layout()

out = Path(__file__).resolve().parents[2] / "chapters/2.Theory/images/theory-2-ransac.png"
out.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(out)
print("saved", out)
print(f"LS slope {a_ls:.3f} (err {err_ls:.1f} deg), RANSAC slope {a_r:.3f} "
      f"(err {err_r:.2f} deg), consensus {best_inl.sum()}/{X.size}")
