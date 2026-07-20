# Big-rune rotation prediction and how you grade it, for the "rune detection" chapter.
# Top: the rune's angular speed spd = a*sin(w t) + b (b = 2.09 - a). Per-frame frame-diff
#   speed is a noise storm (gray dots); a sine FIT over a long window (fix w, linear LSQ)
#   recovers the parameters. Note the peak is pinned at 2.09 rad/s for every legal (a, w).
# Bottom: grade the predictor by the ONLY thing that matters -- does the predicted lead angle
#   land the bullet on the armor after the flight time. Error stays inside +/-5 deg, well under
#   the +/-13.5 deg "armor half-width" threshold => hit.
# Output: chapters/4.Application/images/app-rune-predict.png
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

RED = "#e34948"; ORANGE = "#e08a1e"; GRAY = "#9a9894"
INK = "#0b0b0b"; BLUE = "#2a78d6"; GREEN = "#3f9a52"; MUTED = "#52514e"

rng = np.random.default_rng(7)

# ---- ground-truth big rune (season values; peak pinned at 2.09 rad/s) ----
a, w = 0.90, 1.95
b = 2.09 - a
spd = lambda t: a * np.sin(w * t) + b
theta = lambda t: -a / w * np.cos(w * t) + b * t + a / w   # integral, theta(0)=0

fps = 100.0
dt = 1.0 / fps
T = 6.0
ts = np.arange(0.0, T, dt)
sp_noisy = spd(ts) + rng.normal(0.0, 0.30, ts.size)        # post-low-pass speed noise level

DT = 0.40          # total lead: bullet flight (7 m / ~20 m/s) + pipeline latency
FIT_START = 3.0    # need ~one period of data before the fit is trustworthy


def fit_sine(tt, yy):
    """Fix omega (scan the legal band), then A1 sin + A2 cos + C is LINEAR -> LSQ."""
    best = None
    for om in np.linspace(1.884, 2.000, 25):
        X = np.column_stack([np.sin(om * tt), np.cos(om * tt), np.ones_like(tt)])
        p, *_ = np.linalg.lstsq(X, yy, rcond=None)
        res = np.sum((X @ p - yy) ** 2)
        if best is None or res < best[0]:
            best = (res, om, p)
    _, om, p = best
    return np.hypot(p[0], p[1]), om, np.arctan2(p[1], p[0]), p[2]   # A, omega, phi, C


# final fit (for drawing) + rolling prediction error (for grading)
A_f, w_f, phi_f, C_f = fit_sine(ts, sp_noisy)
err_t, err_deg = [], []
for t in ts[ts >= FIT_START]:
    m = ts <= t
    A, om, phi, C = fit_sine(ts[m], sp_noisy[m])
    lead_pred = (-A / om * np.cos(om * (t + DT) + phi) + C * (t + DT)) - (-A / om * np.cos(om * t + phi) + C * t)
    lead_true = theta(t + DT) - theta(t)
    err_t.append(t)
    err_deg.append(np.degrees(lead_pred - lead_true))
err_t, err_deg = np.array(err_t), np.array(err_deg)
emax = np.abs(err_deg).max()
thr = np.degrees(0.5 * 300 / 636.42)   # half the armor arc, as a center angle ~ 13.5 deg

fig, (axA, axB) = plt.subplots(2, 1, figsize=(9.0, 7.4), gridspec_kw=dict(height_ratios=[1.05, 1.0]))

# ---------- Panel A: speed profile ----------
axA.scatter(ts, sp_noisy, s=9, color=GRAY, alpha=0.55, zorder=1,
            label="per-frame frame-diff speed (noise storm)")
axA.plot(ts, spd(ts), color=INK, lw=1.4, zorder=3, label="true spd = a sin(w t) + b")
axA.plot(ts, A_f * np.sin(w_f * ts + phi_f) + C_f, color=BLUE, lw=5.0, alpha=0.45, zorder=2,
         solid_capstyle="round", label="sine fit over window (fix w -> linear LSQ)")
axA.axhline(2.09, color=RED, lw=1.2, ls=(0, (5, 3)), zorder=2)
axA.text(T - 0.05, 2.13, "peak pinned at 2.09 rad/s  (a + b = 2.090 for every legal a)",
         color=RED, fontsize=9.5, ha="right", va="bottom")
axA.axhline(b - a, color=MUTED, lw=1.0, ls=(0, (2, 3)), zorder=1)
axA.text(0.05, b - a - 0.03, "trough = 2.09 - 2a", color=MUTED, fontsize=9, ha="left", va="top")
axA.set_ylabel("angular speed  (rad/s)")
axA.set_xlim(0, T); axA.set_ylim(-0.15, 2.45)
axA.set_title(f"Big rune: recover (a, w) by fitting the SINE, not by trusting one frame   "
              f"[fit a={A_f:.2f}, w={w_f:.2f} vs truth a={a:.2f}, w={w:.2f}]", fontsize=11.5)
axA.legend(loc="lower right", fontsize=8.6, frameon=True, framealpha=0.95)
axA.grid(alpha=0.18)

# ---------- Panel B: grade the predictor ----------
axB.axhspan(-thr, thr, color=GREEN, alpha=0.14, zorder=0)
axB.axhline(thr, color=GREEN, lw=1.3, zorder=1)
axB.axhline(-thr, color=GREEN, lw=1.3, zorder=1)
axB.text(FIT_START + 0.05, thr - 0.6, f"+/-{thr:.1f} deg = half an armor arc: inside this band the bullet still lands (HIT)",
         color=GREEN, fontsize=9.3, va="top")
axB.axhline(0, color=MUTED, lw=0.8, zorder=1)
axB.plot(err_t, err_deg, color=BLUE, lw=2.4, zorder=3,
         label=f"prediction error over lead DT={DT:.2f}s  (max |{emax:.1f}| deg)")
axB.set_xlabel("time  (s)"); axB.set_ylabel("predicted - true lead  (deg)")
axB.set_xlim(0, T); axB.set_ylim(-thr * 1.25, thr * 1.25)
axB.set_title("Grade prediction by the ONLY metric that matters: is the lead within an armor of truth?",
              fontsize=11.5)
axB.legend(loc="lower right", fontsize=9.0, frameon=True, framealpha=0.95)
axB.grid(alpha=0.18)

fig.tight_layout()
out = Path("chapters/4.Application/images/app-rune-predict.png")
out.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(out, dpi=150, bbox_inches="tight")
print("wrote", out, " max_err_deg=%.2f thr=%.2f" % (emax, thr))
