#!/usr/bin/env python3
"""Draw a derived illustration of rm.cv.fans' latency model.

The six event names come from `docs/auto_aim/latency.md`. The 82 ms img-to-fire
mean is a project-log record, while -18 ms and +20 ms are configured signed
terms. The 80 ms vision-side aggregate is therefore an algebraic reconstruction,
not a separately measured interval, and the internal `predict` location is not
available. The lower panel varies an independent timing-error magnitude and
shows its first-order angle sensitivity under constant 120 rpm rotation. The
interval and model terms listed above are not treated as timing errors.
"""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import FancyArrowPatch

plt.rcParams.update({"font.size": 10.5})

BLUE, MAGENTA, GREY, GREEN = "#3B6FD4", "#D6336C", "#6F7782", "#2E7D32"

# Logged/configured values used only for the derived budget illustration.
IMG_TO_FIRE_MEAN_MS = 82.0
SEND_TO_CONTROL_TERM_MS = -18.0
CONTROL_TO_FIRE_TERM_MS = 20.0
VISION_AGGREGATE_MS = (
    IMG_TO_FIRE_MEAN_MS - SEND_TO_CONTROL_TERM_MS - CONTROL_TO_FIRE_TERM_MS
)
DISTANCE_M, SPEED_MPS = 3.0, 25.0
FIRE_TO_HIT_EXAMPLE_MS = DISTANCE_M / SPEED_MPS * 1e3
DEG_PER_MS_AT_120_RPM = 720.0 / 1000.0

fig, (ax1, ax2) = plt.subplots(
    2,
    1,
    figsize=(11.4, 7.4),
    gridspec_kw={"height_ratios": [1.25, 1.0]},
)

# Conceptual event order. Spacing is deliberately schematic.
events = [
    ("img", "exposure\nmid-point"),
    ("predict", "internal position\nnot retained"),
    ("send", "prediction\nfinished"),
    ("control", "motor control\nbegins"),
    ("fire", "projectile\nleaves"),
    ("hit", "projectile reaches\ntarget"),
]
x_positions = np.arange(len(events), dtype=float)
y_chain = 4.6

for index in range(len(events) - 1):
    ax1.add_patch(
        FancyArrowPatch(
            (x_positions[index] + 0.13, y_chain),
            (x_positions[index + 1] - 0.13, y_chain),
            arrowstyle="->",
            color="#7A8793",
            lw=1.6,
            mutation_scale=12,
        )
    )

for x_value, (name, description) in zip(x_positions, events):
    is_unknown_internal_point = name == "predict"
    ax1.scatter(
        [x_value],
        [y_chain],
        s=125,
        facecolors="white" if is_unknown_internal_point else BLUE,
        edgecolors=BLUE,
        linewidths=1.8,
        linestyle="--" if is_unknown_internal_point else "-",
        zorder=4,
    )
    ax1.text(x_value, y_chain + 0.34, name, ha="center", va="bottom",
             fontsize=10, weight="bold")
    ax1.text(x_value, y_chain - 0.36, description, ha="center", va="top",
             fontsize=8.0, color=GREY)

ax1.text(
    2.5,
    5.55,
    "Six named events (conceptual order; horizontal spacing is not elapsed time)",
    ha="center",
    va="center",
    fontsize=11,
    weight="bold",
)

rows = [
    (
        2.70,
        BLUE,
        "vision-side aggregate",
        f"{VISION_AGGREGATE_MS:.0f} ms = 82 - (-18) - 20",
        "derived from one logged img-to-fire mean",
    ),
    (
        1.85,
        MAGENTA,
        "send-to-control term",
        f"{SEND_TO_CONTROL_TERM_MS:+.0f} ms",
        "configured signed calibration/timing term; mechanism unresolved",
    ),
    (
        1.00,
        MAGENTA,
        "control-to-fire term",
        f"{CONTROL_TO_FIRE_TERM_MS:+.0f} ms",
        "configured value for the fixed snapshot",
    ),
    (
        0.15,
        GREY,
        "fire-to-hit example",
        f"{FIRE_TO_HIT_EXAMPLE_MS:.0f} ms = 3 m / 25 m/s",
        "illustrative no-drag flight time, not a stored measurement",
    ),
]

for y_value, color, label, value, evidence in rows:
    ax1.text(0.05, y_value, label, ha="left", va="center", fontsize=9.2,
             color=color, weight="bold")
    ax1.text(1.55, y_value, value, ha="left", va="center", fontsize=9.2,
             color="#222222")
    ax1.text(3.05, y_value, evidence, ha="left", va="center", fontsize=8.5,
             color=GREY)
    ax1.plot([0.0, 5.0], [y_value - 0.38, y_value - 0.38], color="#D8DDE2",
             lw=0.7)

ax1.text(
    2.5,
    3.25,
    "prediction horizon = vision + send-to-control + flight\n"
    "control-to-fire is omitted only under the documented continuous-fire approximation",
    ha="center",
    va="center",
    fontsize=8.3,
    color=GREEN,
    bbox=dict(boxstyle="round,pad=0.45", fc="#EAF4EC", ec=GREEN, lw=1.0),
)

ax1.set_xlim(-0.25, 5.25)
ax1.set_ylim(-0.35, 5.95)
ax1.axis("off")

# First-order sensitivity to an independent timing error.
timing_error_ms = np.linspace(0.0, 50.0, 251)
angle_error_deg = timing_error_ms * DEG_PER_MS_AT_120_RPM
reported_angle_deg = 30.0
reported_equivalent_ms = reported_angle_deg / DEG_PER_MS_AT_120_RPM

ax2.plot(timing_error_ms, angle_error_deg, color=BLUE, lw=2.4)
ax2.fill_between(timing_error_ms, 0.0, angle_error_deg, color=BLUE, alpha=0.10)

ax2.scatter([10.0], [7.2], color=GREEN, s=48, zorder=4)
ax2.annotate(
    "10 ms -> 7.2 deg",
    xy=(10.0, 7.2),
    xytext=(13.5, 4.5),
    color=GREEN,
    fontsize=9,
    arrowprops=dict(arrowstyle="->", color=GREEN, lw=1.0),
)

ax2.axhline(reported_angle_deg, color=MAGENTA, lw=1.2, ls="--")
ax2.axvline(reported_equivalent_ms, color=MAGENTA, lw=1.2, ls="--")
ax2.scatter([reported_equivalent_ms], [reported_angle_deg], color=MAGENTA,
            s=48, zorder=4)
ax2.annotate(
    "30 deg corresponds to 41.7 ms in this constant-speed model\n"
    "zero hit rate was reported only for the logged test scope",
    xy=(reported_equivalent_ms, reported_angle_deg),
    xytext=(19.0, 32.8),
    color=MAGENTA,
    fontsize=8.4,
    ha="left",
    arrowprops=dict(arrowstyle="->", color=MAGENTA, lw=1.0),
)

ax2.text(
    1.2,
    27.0,
    "The intervals and model terms above are not timing-error measurements.\n"
    "This panel varies a separate error magnitude |delta_t|.",
    fontsize=8.5,
    color=GREY,
    va="top",
    bbox=dict(boxstyle="round,pad=0.4", fc="#F5F7F9", ec="#C8D0D8", lw=0.8),
)

ax2.set_xlim(0, 50)
ax2.set_ylim(0, 38)
ax2.set_xlabel(r"timing-error magnitude  $|\delta t|$  [ms]")
ax2.set_ylabel(r"first-order yaw error  $|\omega \delta t|$  [deg]")
ax2.grid(alpha=0.25, lw=0.6)
ax2.set_title(
    "Constant-speed sensitivity at 120 rpm (not a measured error distribution)",
    fontsize=11,
)

fig.suptitle(
    "rm.cv.fans latency model: named events, mixed evidence sources, and timing-error sensitivity",
    fontsize=12,
    y=0.995,
    weight="bold",
)
fig.tight_layout(rect=(0, 0, 1, 0.97))

output_path = (
    Path(__file__).resolve().parents[2]
    / "chapters/6.Projects/images/proj-cvfans-latency.png"
)
fig.savefig(output_path, dpi=150, bbox_inches="tight")

print(f"derived vision aggregate: {VISION_AGGREGATE_MS:.1f} ms")
print(f"send-to-control configured term: {SEND_TO_CONTROL_TERM_MS:+.1f} ms")
print(f"control-to-fire configured term: {CONTROL_TO_FIRE_TERM_MS:+.1f} ms")
print(f"illustrative fire-to-hit time: {FIRE_TO_HIT_EXAMPLE_MS:.1f} ms")
print(f"10 ms at 120 rpm: {10 * DEG_PER_MS_AT_120_RPM:.1f} deg")
print(f"saved {output_path}")
