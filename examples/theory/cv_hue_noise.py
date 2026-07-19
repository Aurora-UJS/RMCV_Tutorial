# Hue noise diverges as saturation drops: Monte-Carlo of +-2 DN channel noise
# on a blue pixel (V=200) versus the first-order prediction std(H) = 60*sqrt(2)*sigma/Delta.
# Generates chapters/2.Theory/images/theory-cv-hue-noise.png
# Run: python3 examples/theory/cv_hue_noise.py   (any cwd works)

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT = Path(__file__).resolve().parents[2] / "chapters" / "2.Theory" / "images" / "theory-cv-hue-noise.png"

BLUE = "#0072B2"   # Monte-Carlo / high-S example
VERM = "#D55E00"   # analytic curve / low-S example

rng = np.random.default_rng(7)
SIGMA = 2.0        # channel noise, digital numbers (DN)
V0 = 200.0         # fixed brightness
N = 40000          # samples per saturation value


def hue_deg(r, g, b):
    """Standard hue in degrees, computed on float RGB."""
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    d = np.maximum(mx - mn, 1e-12)
    h = np.where(
        mx == r, (g - b) / d,
        np.where(mx == g, (b - r) / d + 2.0, (r - g) / d + 4.0),
    )
    return (60.0 * h) % 360.0


def circ_std_deg(h):
    a = np.deg2rad(h)
    r = np.hypot(np.cos(a).mean(), np.sin(a).mean())
    return np.rad2deg(np.sqrt(-2.0 * np.log(max(r, 1e-12))))


# Base color: pure blue sector, H = 240 deg, V = 200, saturation varied.
# OpenCV convention: S = 255 * Delta / V  =>  Delta = V * S / 255.
# Cap S at 240: at S = 255 the base R/G channels sit exactly at 0, so np.clip
# truncates the noise one-sidedly and the endpoint drifts off the first-order line.
S_vals = np.unique(
    np.concatenate([np.round(np.geomspace(3, 240, 40)).astype(int), [12, 150]])
)
mc_std, hist_samples = [], {}
for S in S_vals:
    delta = V0 * S / 255.0
    r = np.clip(V0 - delta + rng.normal(0, SIGMA, N), 0, 255)
    g = np.clip(V0 - delta + rng.normal(0, SIGMA, N), 0, 255)
    b = np.clip(V0 + rng.normal(0, SIGMA, N), 0, 255)
    h = hue_deg(r, g, b)
    mc_std.append(circ_std_deg(h))
    if S in (12, 150):
        hist_samples[S] = h
mc_std = np.array(mc_std)

delta_all = V0 * S_vals / 255.0
analytic = 60.0 * np.sqrt(2.0) * SIGMA / delta_all  # degrees, first-order

std12 = mc_std[list(S_vals).index(12)] if 12 in S_vals else None
std150 = mc_std[list(S_vals).index(150)] if 150 in S_vals else None

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12.0, 4.8))

ax1.axvspan(0, 20, color="0.85", zorder=0)
ax1.text(4, 1.1, "hue unreliable\n(std > ~10 deg)", fontsize=9, color="0.35")
ax1.plot(S_vals, analytic, color=VERM, lw=2, ls="--",
         label=r"first order: $60\sqrt{2}\,\sigma/\Delta$")
ax1.plot(S_vals, mc_std, "o", ms=5, color=BLUE, label="Monte-Carlo (40k samples)")
ax1.set_xscale("log")
ax1.set_yscale("log")
ax1.set_xlabel("saturation S (OpenCV units, 0-255)")
ax1.set_ylabel("circular std of hue (deg)")
ax1.legend(frameon=False)
ax1.grid(alpha=0.25, which="both")

bins = np.linspace(180, 300, 121)
ax2.hist(hist_samples[150], bins=bins, density=True, color=BLUE, alpha=0.85,
         label=f"S=150: std {std150:.1f} deg")
ax2.hist(hist_samples[12], bins=bins, density=True, histtype="step", lw=2,
         color=VERM, label=f"S=12: std {std12:.1f} deg")
ax2.axvline(240, color="0.3", lw=1, ls=":")
ax2.text(236, ax2.get_ylim()[1] * 0.55, "true hue 240 deg", fontsize=9,
         color="0.35", ha="right")
ax2.set_xlabel("measured hue (deg)")
ax2.set_ylabel("density")
ax2.legend(frameon=False)
ax2.grid(alpha=0.25)

fig.suptitle(
    f"Hue noise grows as 1/$\\Delta$: the same +-{SIGMA:.0f} DN channel noise gives "
    f"hue std {std150:.1f} deg at S=150 but {std12:.0f} deg at S=12 (V=200, blue pixel)",
    fontsize=12,
)
fig.tight_layout(rect=(0, 0, 1, 0.92))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=150)
print("saved", OUT)
for S, st, an in zip(S_vals, mc_std, analytic):
    if S in (3, 5, 10, 12, 20, 50, 150, 240):
        print(f"S={S:3d}  Delta={V0*S/255:6.1f}  MC std={st:6.2f} deg  analytic={an:6.2f} deg")
