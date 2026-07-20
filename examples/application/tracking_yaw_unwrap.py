"""Why the tracker must unwrap the PnP yaw before feeding it to the EKF.

PnP returns an armor orientation whose yaw lives in [-pi, pi]: it wraps.
A spinning target crosses that seam once per full turn. If the raw wrapped yaw
is handed straight to the filter, the innovation z - h(x) sees a fake jump of
~2*pi at each seam, and one such wrong correction is enough to diverge.
orientationToYaw() fixes this by accumulating shortest_angular_distance, which
reconstructs a continuous (-inf, +inf) yaw.

Reproduces the mechanism in rm_auto_aim tracker.cpp::orientationToYaw.
Output: chapters/4.Application/images/app-tracking-yaw-unwrap.png
"""
import os
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator

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

# --- residuals the filter would see, frame to frame --------------------------
naive_res = np.diff(yaw_wrapped)                # feeding wrapped yaw raw
correct_res = np.diff(yaw_unwrapped)            # after unwrapping
# seam frames: where the naive residual blows past half a turn
seams = np.where(np.abs(naive_res) > PI)[0] + 1

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
axA.set_yticklabels([f"{v/PI:.0f}$\\pi$" if v != 0 else "0"
                     for v in axA.get_yticks()])

# Panel B: the residual each path hands the filter
axB.plot(frame[1:], naive_res, color=C_NAIVE, lw=1.5, marker="o", ms=2.6,
         label="feed raw wrapped yaw:  diff jumps by ~$-2\\pi$ at each seam")
axB.plot(frame[1:], correct_res, color=C_OK, lw=3.0, alpha=0.85,
         label="feed unwrapped yaw:  residual stays $\\approx \\omega/\\mathrm{fps}$")
axB.axhline(0, color="0.6", lw=0.8)
for s in seams:
    axB.axvline(s - 0.5, color="0.55", ls=":", lw=1.1, zorder=0)
    axB.annotate("fake $-2\\pi$ residual\n(one bad correction diverges the EKF)",
                 xy=(s, naive_res[s - 1]), xytext=(s + 5, -3.4),
                 fontsize=8.6, color=C_NAIVE,
                 arrowprops=dict(arrowstyle="->", color=C_NAIVE, lw=1.1))
axB.set_xlabel("frame  (100 fps)")
axB.set_ylabel("per-frame\nyaw residual  [rad]")
axB.legend(loc="center right", fontsize=8.6, framealpha=0.95)
axB.grid(True, alpha=0.25)

fig.suptitle(
    "Unwrap the yaw before the filter: raw PnP yaw fakes a $2\\pi$ ($360^\\circ$) jump; "
    "accumulation restores the true small step",
    fontsize=11, y=0.985, color="0.15")

out = os.path.join(os.path.dirname(__file__), "..", "..",
                   "chapters", "4.Application", "images", "app-tracking-yaw-unwrap.png")
out = os.path.abspath(out)
fig.savefig(out, dpi=150, bbox_inches="tight")
print("saved", out)
print("seam frames:", seams, " naive residual at seams:",
      np.round(naive_res[seams - 1], 3))
