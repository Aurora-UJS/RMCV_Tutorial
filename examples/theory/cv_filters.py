# Noise vs. filters: mean / Gaussian / median on a real game-frame crop.
# Generates chapters/2.Theory/images/theory-cv-filters.png
# Run: python3 examples/theory/cv_filters.py   (any cwd works)

from pathlib import Path

import cv2
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
VIDEO = ROOT / "examples" / "test.mp4"
OUT = ROOT / "chapters" / "2.Theory" / "images" / "theory-cv-filters.png"

rng = np.random.default_rng(42)

# -- the same 7.0 s frame used throughout the OpenCV section of the book
cap = cv2.VideoCapture(str(VIDEO))
cap.set(cv2.CAP_PROP_POS_MSEC, 7000)
ok, frame = cap.read()
assert ok, "cannot read examples/test.mp4"
gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
clean = gray[400:620, 540:940]  # crop around the front blue car's armor plates

# -- two noise models
gauss = np.clip(
    clean.astype(np.float64) + rng.normal(0.0, 15.0, clean.shape), 0, 255
).astype(np.uint8)

salt_pepper = clean.copy()
mask = rng.random(clean.shape)
salt_pepper[mask < 0.025] = 0
salt_pepper[mask > 0.975] = 255

# -- three filters, same 5x5 support
def filters(img):
    return {
        "mean 5x5": cv2.blur(img, (5, 5)),
        "Gaussian 5x5": cv2.GaussianBlur(img, (5, 5), 0),
        "median 5x5": cv2.medianBlur(img, 5),
    }

def rmse(img):
    return float(np.sqrt(np.mean((img.astype(np.float64) - clean.astype(np.float64)) ** 2)))

rows = [
    ("Gaussian noise (sigma=15)", gauss),
    ("salt & pepper (5%)", salt_pepper),
]

fig, axes = plt.subplots(2, 4, figsize=(12.6, 5.6))
for r, (row_name, noisy) in enumerate(rows):
    panels = [("noisy input", noisy)] + list(filters(noisy).items())
    for c, (name, img) in enumerate(panels):
        ax = axes[r][c]
        ax.imshow(img, cmap="gray", vmin=0, vmax=255)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_title(f"{name} - RMSE {rmse(img):.1f}", fontsize=10)
        if c == 0:
            ax.set_ylabel(row_name, fontsize=10)

fig.suptitle(
    "Match the filter to the noise: linear filters average Gaussian noise away,\n"
    "but only the median removes salt & pepper instead of smearing it (RMSE vs. clean crop, gray levels)",
    fontsize=12,
)
fig.tight_layout(rect=(0, 0, 1, 0.90))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=150, bbox_inches="tight")
print("saved", OUT)
for r, (row_name, noisy) in enumerate(rows):
    line = [f"{row_name}: input {rmse(noisy):.1f}"]
    line += [f"{k} {rmse(v):.1f}" for k, v in filters(noisy).items()]
    print(" | ".join(line))
