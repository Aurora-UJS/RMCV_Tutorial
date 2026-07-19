# Hough voting demo for the "traditional CV" theory chapter.
# Left: image-space points, one true line buried in clutter.
# Right: the (theta, rho) accumulator actually built by voting;
#        collinear points pile up in one cell, clutter spreads thin.
# Output: chapters/2.Theory/images/theory-2-hough.png
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

rng = np.random.default_rng(7)

# ---- palette (doc-wide: blue = data/model, red = clutter, black = truth)
BLUE = "#2a78d6"
RED = "#e34948"
INK = "#0b0b0b"
MUTED = "#52514e"

# ---- synthetic data: 40 points on a line + 60 clutter points, 200x200 image
W = H = 200
theta_true = np.deg2rad(60.0)          # line normal direction
rho_true = 80.0                        # distance from origin
t = rng.uniform(-90, 110, 40)
x_line = rho_true * np.cos(theta_true) - t * np.sin(theta_true)
y_line = rho_true * np.sin(theta_true) + t * np.cos(theta_true)
keep = (x_line >= 0) & (x_line < W) & (y_line >= 0) & (y_line < H)
x_line, y_line = x_line[keep], y_line[keep]
x_line += rng.normal(0, 1.0, x_line.size)   # 1 px localization noise
y_line += rng.normal(0, 1.0, y_line.size)
x_cl = rng.uniform(0, W, 60)
y_cl = rng.uniform(0, H, 60)
xs = np.concatenate([x_line, x_cl])
ys = np.concatenate([y_line, y_cl])

# ---- voting: accumulator over theta in [0, pi), rho in [-diag, diag], 2 px rho bins
n_theta = 180
rho_bin = 2
diag = int(np.ceil(np.hypot(W, H)))
n_rho = 2 * diag // rho_bin
thetas = np.linspace(0, np.pi, n_theta, endpoint=False)
acc = np.zeros((n_rho, n_theta), dtype=int)
for x, y in zip(xs, ys):
    rhos = x * np.cos(thetas) + y * np.sin(thetas)
    idx = np.round((rhos + diag) / rho_bin).astype(int).clip(0, n_rho - 1)
    acc[idx, np.arange(n_theta)] += 1

peak_r, peak_t = np.unravel_index(np.argmax(acc), acc.shape)
rho_hat = peak_r * rho_bin - diag
theta_hat = thetas[peak_t]
votes = acc.max()

fig, (ax0, ax1) = plt.subplots(1, 2, figsize=(9.6, 4.2), dpi=150)

# ---- left: image space
ax0.scatter(x_cl, y_cl, s=18, c=RED, marker="x", linewidths=1.2,
            label=f"clutter ({x_cl.size} pts)")
ax0.scatter(x_line, y_line, s=16, c=BLUE, label=f"collinear ({x_line.size} pts)")
xx = np.array([-20, W + 20])
# line recovered from the accumulator peak: x cos(t) + y sin(t) = rho
yy = (rho_hat - xx * np.cos(theta_hat)) / np.sin(theta_hat)
ax0.plot(xx, yy, color=INK, lw=1.0, ls="--", label="line from peak")
ax0.set_xlim(0, W); ax0.set_ylim(0, H)
ax0.set_aspect("equal")
ax0.set_xlabel("x (px)"); ax0.set_ylabel("y (px)")
ax0.set_title("Image space: which points form a line?", fontsize=10)
ax0.legend(loc="lower right", fontsize=8, framealpha=0.9)

# ---- right: accumulator
im = ax1.imshow(acc, aspect="auto", cmap="Blues", origin="lower",
                extent=[0, 180, -diag, diag])
ax1.annotate(f"peak: {votes} votes\n" + rf"$(\theta,\rho)=({np.rad2deg(theta_hat):.0f}^\circ,{rho_hat:.0f})$",
             xy=(np.rad2deg(theta_hat), rho_hat), xytext=(95, -160),
             fontsize=9, color=INK,
             arrowprops=dict(arrowstyle="->", color=INK, lw=1.0))
ax1.set_xlabel(r"$\theta$ (deg)"); ax1.set_ylabel(r"$\rho$ (px)")
ax1.set_title("Accumulator: each point votes a sinusoid", fontsize=10)
fig.colorbar(im, ax=ax1, label="votes", shrink=0.9)

fig.suptitle(
    f"Hough voting: {x_line.size} collinear points stack {votes} votes in one cell; "
    f"{x_cl.size} clutter points never agree",
    fontsize=11)
fig.tight_layout(rect=[0, 0, 1, 0.94])

out = Path(__file__).resolve().parents[2] / "chapters/2.Theory/images/theory-2-hough.png"
out.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(out)
print("saved", out, "| true (theta,rho)=(60,80), peak=",
      round(np.rad2deg(theta_hat)), rho_hat, "votes=", votes)
