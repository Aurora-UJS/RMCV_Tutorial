"""Why the tracker must unwrap the PnP yaw before feeding it to the EKF.

PnP returns an armor orientation whose yaw lives in [-pi, pi]: it wraps.
A spinning target crosses that seam once per full turn. Treating wrapped yaw as
an ordinary real-valued signal creates a numeric jump of about 2*pi at each
seam. Its effect on a filter depends on the innovation definition, gain, and
gating; this script only demonstrates the angle-boundary mechanism.
orientationToYaw() fixes this by accumulating shortest_angular_distance, which
reconstructs a continuous (-inf, +inf) yaw.

Reproduces the mechanism in rm_auto_aim tracker.cpp::orientationToYaw.
Output: chapters/4.Application/images/app-tracking-yaw-unwrap.png
"""
import os
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter, MultipleLocator

PI = np.pi


def wrap_to_pi(a):
    """Map an angle to [-pi, pi], the range a PnP/RPY yaw comes back in."""
    return (a + PI) % (2 * PI) - PI


def shortest_angular_distance(a, b):
    """Signed smallest rotation taking a to b, in [-pi, pi]."""
    return wrap_to_pi(b - a)


# --- simulate a constant-speed spin (small top): 2 rev/s over 1.0 s -----------
fps = 100
T = 1.0
n = int(fps * T)
frame = np.arange(n)
omega = 4 * PI  # rad/s  -> two full turns in the window, two wrap seams
yaw0 = -2.4     # start near the -pi seam so the first wrap comes early
yaw_true = yaw0 + omega * frame / fps          # the physical, continuous yaw
yaw_wrapped = wrap_to_pi(yaw_true)              # what PnP actually reports

# --- reconstruct a continuous yaw the way orientationToYaw() does -------------
yaw_unwrapped = np.empty(n)
last = yaw_wrapped[0]
yaw_unwrapped[0] = last
for i in range(1, n):
    last = last + shortest_angular_distance(last, yaw_wrapped[i])
    yaw_unwrapped[i] = last

# --- frame-to-frame angle increments, not a complete EKF innovation ----------
naive_step = np.diff(yaw_wrapped)
correct_step = np.diff(yaw_unwrapped)
# Seam frames: where the raw numeric step exceeds half a turn.
seams = np.where(np.abs(naive_step) > PI)[0] + 1

C_WRAP = "#c0392b"      # raw wrapped yaw  (the trap)
C_CONT = "#1f6fb2"      # unwrapped yaw    (the fix)
C_NAIVE = "#c0392b"
C_OK = "#1f6fb2"

fig, (axA, axB) = plt.subplots(
    2, 1, figsize=(8.6, 6.4), gridspec_kw=dict(height_ratios=[1.35, 1.0], hspace=0.34)
)

# Panel A: wrapped (trap) vs unwrapped (fix)
axA.plot(frame, yaw_unwrapped, color=C_CONT, lw=3.2, alpha=0.85,
         label="unwrapped yaw  (shortest_angular_distance accumulation)  -> fed to EKF")
axA.plot(frame, yaw_wrapped, color=C_WRAP, lw=1.4, marker="o", ms=2.6,
         label="raw PnP yaw  (wrapped to [-pi, pi])")
for s in seams:
    axA.axvline(s - 0.5, color="0.55", ls=":", lw=1.1, zorder=0)
axA.axhline(PI, color="0.7", lw=0.8, ls="--")
axA.axhline(-PI, color="0.7", lw=0.8, ls="--")
axA.text(seams[0] - 0.5, yaw_unwrapped.max() * 0.9, "  wrap seam",
         color="0.35", fontsize=9, rotation=0, va="top")
axA.set_ylabel("yaw  [rad]")
axA.set_title(
    "PnP yaw wraps at $\\pm\\pi$; a spinning target crosses the seam once per full turn",
    fontsize=12.5, pad=8)
axA.legend(loc="upper left", fontsize=8.6, framealpha=0.95)
axA.grid(True, alpha=0.25)
axA.yaxis.set_major_locator(MultipleLocator(PI))
axA.yaxis.set_major_formatter(
    FuncFormatter(lambda value, _: "0" if abs(value) < 1e-9 else f"{value / PI:.0f}$\\pi$")
)

# Panel B: adjacent-sample differences for the two representations.
axB.plot(frame[1:], naive_step, color=C_NAIVE, lw=1.5, marker="o", ms=2.6,
         label="raw wrapped yaw: adjacent step jumps by ~$-2\\pi$ at each seam")
axB.plot(frame[1:], correct_step, color=C_OK, lw=3.0, alpha=0.85,
         label="unwrapped yaw: adjacent step stays $\\approx \\omega/\\mathrm{fps}$")
axB.axhline(0, color="0.6", lw=0.8)
for s in seams:
    axB.axvline(s - 0.5, color="0.55", ls=":", lw=1.1, zorder=0)
axB.annotate("numeric $-2\\pi$ boundary jump\n(filter impact depends on its update rule)",
             xy=(seams[0], naive_step[seams[0] - 1]), xytext=(seams[0] + 8, -4.2),
             fontsize=8.6, color=C_NAIVE,
             arrowprops=dict(arrowstyle="->", color=C_NAIVE, lw=1.1))
axB.set_xlabel("frame  (100 fps)")
axB.set_ylabel("adjacent-sample\nyaw step  [rad]")
axB.legend(loc="upper left", fontsize=8.6, framealpha=0.95)
axB.grid(True, alpha=0.25)

fig.suptitle(
    "Yaw unwrapping removes the numeric $2\\pi$ ($360^\\circ$) boundary jump "
    "when adjacent true rotation is below $\\pi$",
    fontsize=11, y=0.985, color="0.15")

out = os.path.join(os.path.dirname(__file__), "..", "..",
                   "chapters", "4.Application", "images", "app-tracking-yaw-unwrap.png")
out = os.path.abspath(out)
fig.savefig(out, dpi=150, bbox_inches="tight")
print("saved", out)
print("seam frames:", seams, " raw adjacent steps at seams:",
      np.round(naive_step[seams - 1], 3))
