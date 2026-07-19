# Otsu's between-class variance on a real game frame, and why the full frame
# is exactly the case where Otsu's assumption breaks.
# Generates chapters/2.Theory/images/theory-cv-otsu.png
# Run: python3 examples/theory/cv_otsu.py   (any cwd works)

from pathlib import Path

import cv2
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
VIDEO = ROOT / "examples" / "test.mp4"
OUT = ROOT / "chapters" / "2.Theory" / "images" / "theory-cv-otsu.png"

BLUE = "#0072B2"   # fixed threshold (the pipeline's choice for the frame)
VERM = "#D55E00"   # Otsu threshold

cap = cv2.VideoCapture(str(VIDEO))
cap.set(cv2.CAP_PROP_POS_MSEC, 7000)
ok, frame = cap.read()
assert ok, "cannot read examples/test.mp4"
gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

# -- Otsu by hand: sigma_B^2(t) = w0*w1*(mu0-mu1)^2 over the histogram
hist = np.bincount(gray.ravel(), minlength=256).astype(np.float64)
p = hist / hist.sum()
v = np.arange(256, dtype=np.float64)
w0 = np.cumsum(p)                      # P(value <= t)
m0 = np.cumsum(p * v)                  # unnormalized class-0 mean
mu = m0[-1]
sigma_b = np.zeros(256)
valid = (w0 > 0) & (w0 < 1)
w1 = 1.0 - w0
sigma_b[valid] = (mu * w0[valid] - m0[valid]) ** 2 / (w0[valid] * w1[valid])
t_star = int(np.argmax(sigma_b))

t_cv, _ = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)
assert t_star == int(t_cv), (t_star, t_cv)   # our argmax must match OpenCV

T_FIXED = 160  # the value used by examples/cpp/lightbar_pipeline.cpp
frac_otsu = float((gray > t_star).mean())
frac_fix = float((gray > T_FIXED).mean())

fig = plt.figure(figsize=(12.6, 9.2))
gs = fig.add_gridspec(3, 3, height_ratios=(1.6, 1.0, 1.0), hspace=0.32)

titles = [
    ("grayscale frame (7.0 s)", gray),
    (f"Otsu t*={t_star}: {frac_otsu*100:.0f}% white - splits the background", gray > t_star),
    (f"fixed t={T_FIXED}: {frac_fix*100:.1f}% white - keeps only emitters", gray > T_FIXED),
]
for c, (name, img) in enumerate(titles):
    ax = fig.add_subplot(gs[0, c])
    ax.imshow(img, cmap="gray", vmin=0, vmax=1 if img.dtype == bool else 255)
    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_title(name, fontsize=10)

ax_h = fig.add_subplot(gs[1, :])
ax_h.fill_between(v, p, color="0.55", step="mid")
ax_h.set_yscale("log")
ax_h.set_ylabel("p(v)  (log)")
ax_h.set_xlim(0, 255)
ax_h.tick_params(labelbottom=False)

ax_s = fig.add_subplot(gs[2, :], sharex=ax_h)
ax_s.plot(v, sigma_b, color="0.2", lw=2)
ax_s.set_ylabel(r"$\sigma_B^2(t)$")
ax_s.set_xlabel("threshold t (gray level)")

for ax in (ax_h, ax_s):
    ax.axvline(t_star, color=VERM, lw=1.8, ls="-")
    ax.axvline(T_FIXED, color=BLUE, lw=1.8, ls="--")
    ax.grid(alpha=0.25)
ax_s.annotate(f"Otsu argmax t*={t_star}", xy=(t_star, sigma_b[t_star]),
              xytext=(t_star + 12, sigma_b[t_star] * 0.92), color=VERM, fontsize=10)
ax_s.annotate(f"pipeline fixed t={T_FIXED}", xy=(T_FIXED, 0),
              xytext=(T_FIXED + 6, sigma_b.max() * 0.55), color=BLUE, fontsize=10)

fig.suptitle(
    "Otsu maximizes between-class variance - but with <1% bright pixels the maximum\n"
    "lands inside the dark background mass, not between background and lightbars",
    fontsize=12,
)
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=150, bbox_inches="tight")
print("saved", OUT)
print(f"otsu t*={t_star}, white frac {frac_otsu:.3f}; fixed {T_FIXED}, white frac {frac_fix:.4f}")
