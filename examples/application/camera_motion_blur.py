"""Motion blur vs exposure time for RM auto-aim targets.

First principles: during the exposure window t_exp, a target moving with
lateral velocity v at distance d sweeps an angle omega = v/d.  Projected
through a lens with focal length f (in pixels), the image of the target
smears over

    blur[px] = (v / d) * f * t_exp .

Blur depends only on exposure time, NOT on frame rate (global shutter
integrates all rows simultaneously).  f is taken from the real rm_vision
camera_info.yaml (fx ~= 1806 px, 1440x1080).  The vertical marker is the
exposure the shipped rm_vision config actually uses (2500 us).

Output: chapters/4.Application/images/app-camera-motion-blur.png
"""
import os
import numpy as np
import matplotlib.pyplot as plt

F_PX = 1806.0          # focal length in pixels, real rm_vision intrinsics
BLUR_OK = 2.0          # px, empirical "still crisp" threshold for a lightbar
T_CFG = 2.5            # ms, exposure_time in shipped rm_vision node_params

# (label, v [m/s], d [m])
CASES = [
    ("mid-range strafe  v=3 m/s  d=5 m", 3.0, 5.0),
    ("close fast move    v=4 m/s  d=3 m", 4.0, 3.0),
]

t_ms = np.linspace(0.0, 10.0, 400)      # exposure time in ms
t_s = t_ms / 1000.0

fig, ax = plt.subplots(figsize=(8.4, 5.0))

colors = ["#1f77b4", "#d62728"]
for (label, v, d), c in zip(CASES, colors):
    rate = (v / d) * F_PX               # px per second
    blur = rate * t_s                   # px
    ax.plot(t_ms, blur, color=c, lw=2.4, label=label)
    b_cfg = rate * (T_CFG / 1000.0)
    ax.plot(T_CFG, b_cfg, "o", color=c, ms=7, zorder=5)
    ax.annotate(f"{b_cfg:.1f} px", (T_CFG, b_cfg), xytext=(T_CFG + 0.25, b_cfg + 0.4),
                color=c, fontsize=10, fontweight="bold")

# usable window: blur below threshold for the milder case
rate_mild = (CASES[0][1] / CASES[0][2]) * F_PX
t_ok = BLUR_OK / rate_mild * 1000.0     # ms where mild case hits threshold
ax.axhspan(0, BLUR_OK, color="#2ca02c", alpha=0.08)
ax.axhline(BLUR_OK, color="#2ca02c", lw=1.4, ls="--")
ax.annotate("crisp lightbar  (blur < 2 px)", (0.15, BLUR_OK + 0.15),
            color="#2ca02c", fontsize=10)

ax.axvline(T_CFG, color="0.35", lw=1.3, ls=":")
ax.annotate("rm_vision config\nexposure = 2.5 ms", (T_CFG + 0.15, 9.1),
            color="0.25", fontsize=9.5, va="top")

ax.set_xlim(0, 10)
ax.set_ylim(0, 10)
ax.set_xlabel("exposure time  $t_{exp}$  [ms]")
ax.set_ylabel("motion blur of the lightbar  [px]")
ax.set_title("Motion blur is set by exposure alone:  blur = (v/d)$\\cdot$f$\\cdot t_{exp}$\n"
             "f = 1806 px (real intrinsics) $\\Rightarrow$ keep $t_{exp}$ short, buy back light with gain",
             fontsize=11.5)
ax.legend(loc="upper right", fontsize=9.5, framealpha=0.95)
ax.grid(True, alpha=0.25)

out = os.path.join(os.path.dirname(__file__), "..", "..",
                   "chapters", "4.Application", "images", "app-camera-motion-blur.png")
out = os.path.abspath(out)
os.makedirs(os.path.dirname(out), exist_ok=True)
fig.tight_layout()
fig.savefig(out, dpi=150)
print("wrote", out)
print(f"blur@2.5ms  caseA={rate_mild*T_CFG/1000:.2f}px  "
      f"caseB={(CASES[1][1]/CASES[1][2])*F_PX*T_CFG/1000:.2f}px  "
      f"caseA hits 2px at {t_ok:.2f}ms")
