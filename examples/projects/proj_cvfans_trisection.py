#!/usr/bin/env python3
"""Plot two angle estimates against the logged hand-computed references.

The three input columns come from rm.cv.fans' engineering log
(`aimer/auto_aim/README.md:503-514`, entry dated April 25). The first column is
hand-computed under a constant-rotation assumption; it is not an independently
measured ground truth. The arithmetic mean and offset correction below are
post-hoc calculations on the same ten samples, not held-out validation.
"""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams.update({"font.size": 10.5})

BLUE, MAGENTA, GREY, GREEN = "#3B6FD4", "#D6336C", "#8A8A8A", "#2E7D32"

# Values transcribed from the published table.
reference = np.array([25.3, 29.3, 34.9, 40.5, 46.2, 50.5, 56.2, 61.8, 67.5, 71.7])
area = np.array([21.3, 26.0, 32.0, 41.3, 46.0, 52.8, 61.0, 68.0, 73.7, 78.2])
ternary = np.array([31.0, 35.0, 41.0, 44.0, 50.0, 52.0, 55.0, 61.0, 65.0, 70.0])

err_area = area - reference
err_ternary = ternary - reference
posthoc_mean = 0.5 * (area + ternary)
err_mean = posthoc_mean - reference
same_sample_offset = err_mean.mean()


def rms(values):
    return float(np.sqrt(np.mean(values**2)))


rms_area = rms(err_area)
rms_ternary = rms(err_ternary)
rms_mean = rms(err_mean)
rms_mean_corrected = rms(err_mean - same_sample_offset)

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.6, 4.7))

# Estimate against the hand-computed reference.
limits = [20, 82]
ax1.plot(limits, limits, color=GREY, lw=1.0, ls="--", zorder=1)
ax1.text(74, 77.5, "agreement line  y = x", color=GREY, fontsize=9,
         rotation=38, ha="center", va="center")
ax1.plot(reference, area, "-o", color=MAGENTA, lw=1.8, ms=5.5,
         label="area-ratio method", zorder=3)
ax1.plot(reference, ternary, "-s", color=BLUE, lw=1.8, ms=5.0,
         label="ternary search (Apr-25 cost)", zorder=3)

for ref, area_value, ternary_value in zip(reference, area, ternary):
    ax1.plot([ref, ref], [ref, area_value], color=MAGENTA, lw=0.8,
             alpha=0.35, zorder=2)
    ax1.plot([ref, ref], [ref, ternary_value], color=BLUE, lw=0.8,
             alpha=0.35, zorder=2)

ax1.set_xlim(limits)
ax1.set_ylim(limits)
ax1.set_aspect("equal")
ax1.set_xlabel("hand-computed reference under constant rotation  [deg]")
ax1.set_ylabel("estimated angle  [deg]")
ax1.set_title("Estimates in the 10-row project log", fontsize=11)
ax1.legend(loc="upper left", fontsize=9, framealpha=0.95)
ax1.grid(alpha=0.25, lw=0.6)

# Signed residuals on the same ten samples.
ax2.axhline(0, color="k", lw=1.0, zorder=2)
ax2.plot(reference, err_area, "-o", color=MAGENTA, lw=2.0, ms=5.5,
         label=f"area-ratio  RMS {rms_area:.2f} deg", zorder=4)
ax2.plot(reference, err_ternary, "-s", color=BLUE, lw=2.0, ms=5.0,
         label=f"ternary search  RMS {rms_ternary:.2f} deg", zorder=4)
ax2.plot(reference, err_mean, "-^", color=GREEN, lw=2.5, ms=5.0,
         label=f"post-hoc mean  RMS {rms_mean:.2f} deg", zorder=5)
ax2.axhline(same_sample_offset, color=GREEN, lw=1.2, ls=":", zorder=3)
ax2.annotate(
    f"mean offset on these samples: {same_sample_offset:.3f} deg\n"
    f"in-sample RMS after subtraction: {rms_mean_corrected:.3f} deg",
    xy=(34.5, same_sample_offset),
    xytext=(25.0, -6.0),
    color=GREEN,
    fontsize=8.6,
    va="center",
    ha="left",
    arrowprops=dict(arrowstyle="->", color=GREEN, lw=1.0),
)

ax2.set_xlim(23, 79)
ax2.set_ylim(-8, 8)
ax2.set_xlabel("hand-computed reference under constant rotation  [deg]")
ax2.set_ylabel("estimate minus reference  [deg]")
ax2.set_title("Signed residuals on the same 10 samples", fontsize=11)
ax2.legend(loc="lower right", fontsize=8.6, framealpha=0.95)
ax2.grid(alpha=0.25, lw=0.6)

fig.suptitle(
    "The logged residual trends differ, but the simple mean is only a post-hoc demonstration\n"
    "No independent ground truth or held-out trajectory is available for fusion validation",
    fontsize=11.5,
    y=1.005,
)
fig.tight_layout(rect=(0, 0, 1, 0.99))

output_path = (
    Path(__file__).resolve().parents[2]
    / "chapters/6.Projects/images/proj-cvfans-trisection.png"
)
fig.savefig(output_path, dpi=150, bbox_inches="tight")

print(f"area RMS against reference: {rms_area:.3f} deg")
print(f"ternary RMS against reference: {rms_ternary:.3f} deg")
print(f"post-hoc mean RMS: {rms_mean:.3f} deg")
print(f"same-sample offset: {same_sample_offset:.3f} deg")
print(f"in-sample RMS after offset subtraction: {rms_mean_corrected:.3f} deg")
print(f"saved {output_path}")
