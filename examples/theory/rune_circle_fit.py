# Circle fitting for the power-rune (energy mechanism) anchor of the
# "traditional CV" theory chapter.
# Kasa algebraic fit on armor-center samples; Monte Carlo over the same pixel
# noise shows why a short arc gives an ill-conditioned center estimate.
# Output: chapters/2.Theory/images/theory-2-rune-circle.png
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

rng = np.random.default_rng(11)

BLUE = "#2a78d6"
GREEN = "#008300"
INK = "#0b0b0b"
MUTED = "#52514e"

R_TRUE = 150.0            # px, rune radius in the image
C_TRUE = np.array([0.0, 0.0])
SIGMA = 2.0               # px, armor-center localization noise
N_PTS = 40                # samples along the arc (frames)
TRIALS = 300


def kasa_fit(x, y):
    """Algebraic circle fit: minimize sum (x^2+y^2+Dx+Ey+F)^2 -> linear LS."""
    A = np.column_stack([x, y, np.ones_like(x)])
    b = -(x**2 + y**2)
    (D, E, F), *_ = np.linalg.lstsq(A, b, rcond=None)
    cx, cy = -D / 2, -E / 2
    r = np.sqrt(cx**2 + cy**2 - F)
    return np.array([cx, cy]), r


def run(arc_deg):
    centers = np.empty((TRIALS, 2))
    for k in range(TRIALS):
        th = np.deg2rad(rng.uniform(0, arc_deg, N_PTS) + 20)
        x = C_TRUE[0] + R_TRUE * np.cos(th) + rng.normal(0, SIGMA, N_PTS)
        y = C_TRUE[1] + R_TRUE * np.sin(th) + rng.normal(0, SIGMA, N_PTS)
        centers[k], _ = kasa_fit(x, y)
    rms = np.sqrt(np.mean(np.sum((centers - C_TRUE) ** 2, axis=1)))
    return centers, rms


arcs = (45, 240)
results = {a: run(a) for a in arcs}
ratio = results[45][1] / results[240][1]

fig, axes = plt.subplots(1, 2, figsize=(9.6, 4.6), dpi=150)
for ax, arc in zip(axes, arcs):
    centers, rms = results[arc]
    # one sample draw to show the measured points themselves
    th = np.deg2rad(np.linspace(0, arc, N_PTS) + 20)
    x = R_TRUE * np.cos(th) + rng.normal(0, SIGMA, N_PTS)
    y = R_TRUE * np.sin(th) + rng.normal(0, SIGMA, N_PTS)
    c_hat, r_hat = kasa_fit(x, y)

    tt = np.linspace(0, 2 * np.pi, 200)
    ax.plot(R_TRUE * np.cos(tt), R_TRUE * np.sin(tt), color=INK, lw=0.8,
            ls=":", label="true circle")
    ax.plot(c_hat[0] + r_hat * np.cos(tt), c_hat[1] + r_hat * np.sin(tt),
            color=GREEN, lw=2.2, alpha=0.7, label="Kasa fit (one draw)")
    ax.scatter(x, y, s=14, c=BLUE, zorder=3, label="armor samples")
    ax.scatter(centers[:, 0], centers[:, 1], s=4, c=MUTED, alpha=0.45,
               label=f"{TRIALS} center estimates")
    ax.scatter(*C_TRUE, s=70, c=INK, marker="+", linewidths=1.6, zorder=4,
               label="true center")
    ax.set_aspect("equal")
    ax.set_xlim(-230, 230); ax.set_ylim(-230, 230)
    ax.set_xlabel("x (px)"); ax.set_ylabel("y (px)")
    ax.set_title(f"{arc}° arc: center RMS error {rms:.1f} px", fontsize=10)
    ax.legend(loc="lower left", fontsize=7.5, framealpha=0.9)

fig.suptitle(
    f"Same {SIGMA:.0f} px noise, same {N_PTS} samples: a {arcs[0]}° arc leaves the center "
    f"{ratio:.0f}x less certain than a {arcs[1]}° arc",
    fontsize=11)
fig.tight_layout(rect=[0, 0, 1, 0.93])

out = Path(__file__).resolve().parents[2] / "chapters/2.Theory/images/theory-2-rune-circle.png"
out.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(out)
print("saved", out)
for a in arcs:
    print(f"arc {a} deg: center RMS {results[a][1]:.2f} px")
print(f"ratio {ratio:.1f}x")
