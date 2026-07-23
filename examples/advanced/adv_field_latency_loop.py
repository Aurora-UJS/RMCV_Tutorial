# Latency-proxy construction: match a referee-system shot report to the frame
# associated with that command (Advanced part, field chapter).
#
# Top panel is a SCHEMATIC of the chain -- segment widths are NOT to scale and carry
# no timing claim; the only thing they encode is which segments you can instrument
# from inside your own process (gray) and which need cross-device observation
# (magenta). The report-return segment is explicit because report arrival is later
# than the physical muzzle-exit event that the proxy is intended to bracket.
# Bottom panel reproduces a project-reported proxy range of 35-110 ms and mean of
# 82 ms. The original samples and event/clock mapping were not independently
# reproduced, so the range is not presented as a measured probability distribution.
# Generates chapters/5.Advanced/images/adv-field-latency-loop.png
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib as mpl
from matplotlib.patches import FancyArrowPatch, Rectangle

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 10.5, "axes.linewidth": 0.8})

T_LO, T_HI, T_MEAN = 35.0, 110.0, 82.0

# (label, width, instrumentable?)
SEGS = [
    ("exposure\n+ readout + USB", 1.25, False),
    ("preprocess\n+ inference", 1.10, True),
    ("PnP\n+ filter", 0.85, True),
    ("plan\n+ pack", 0.75, True),
    ("serial in flight\n+ control loop", 1.15, False),
    ("feeder travel\n+ muzzle exit", 1.05, False),
    ("referee detect\n+ report return", 1.25, False),
]

fig, (ax, bx) = plt.subplots(2, 1, figsize=(9.6, 5.4),
                             gridspec_kw={"height_ratios": [2.15, 1.0]})

# ---------------- top: schematic chain ----------------
x, y, h = 0.0, 0.0, 0.62
muzzle_x = None
for i, (label, w, instr) in enumerate(SEGS):
    col = GRAY if instr else MAGENTA
    ax.add_patch(Rectangle((x, y), w, h, facecolor=col, alpha=0.85,
                           edgecolor="white", lw=1.4))
    ax.text(x + w / 2, y + h / 2, label, ha="center", va="center",
            color="white", fontsize=9, linespacing=1.25)
    x += w
    if i == 5:
        muzzle_x = x
total = x

ax.plot([0, 0], [y - 0.55, y + h + 0.96], color=BLUE, lw=1.6)
ax.plot([total, total], [y - 0.55, y + h + 0.96], color=BLUE, lw=1.6)
ax.text(0, y + h + 1.02, "$t_0$  mapped exposure timestamp",
        ha="left", va="bottom", color=BLUE, fontsize=10)
ax.text(total, y + h + 1.02, "$t_1$  mapped report-arrival timestamp  ",
        ha="right", va="bottom", color=BLUE, fontsize=10)

ax.plot([muzzle_x, muzzle_x], [y - 0.06, y + h + 0.12],
        color="white", lw=1.2, linestyle=(0, (2, 2)), zorder=4)
ax.text(muzzle_x, y + h + 0.18, "physical muzzle exit\n(not directly timestamped here)",
        ha="center", va="bottom", color="#555555", fontsize=8.5)

# the measurement span
ax.add_patch(FancyArrowPatch((0.04, y - 0.30), (total - 0.04, y - 0.30),
                             arrowstyle="<|-|>", mutation_scale=13,
                             color=BLUE, lw=1.6))
ax.text(total / 2, y - 0.50,
        "constructed proxy:  $t_1-t_0$  (requires frame matching and clock mapping)",
        ha="center", va="top", color=BLUE, fontsize=10)

# back-fill arrow
ax.add_patch(FancyArrowPatch((total - 0.05, y + h + 0.34), (0.05, y + h + 0.34),
                             arrowstyle="-|>", mutation_scale=12,
                             color=GRAY, lw=1.2, linestyle=(0, (4, 3)),
                             connectionstyle="arc3,rad=0.16"))
ax.text(total / 2, y + h + 0.44, "match: which frame is associated with this report?",
        ha="center", va="bottom", color=GRAY, fontsize=9.5)

ax.text(0, y - 1.02,
        "gray = you can time it from inside your process        "
        "magenta = needs a cross-device observation        "
        "(widths schematic, not to scale)",
        ha="left", va="top", fontsize=9.2, color="#444444")

ax.set_xlim(-0.30, total + 0.30)
ax.set_ylim(-1.35, 2.28)
ax.axis("off")
ax.set_title("Observe the full chain across process and device boundaries",
             fontsize=11.5, pad=6)

# ---------------- bottom: the cited distribution ----------------
bx.add_patch(Rectangle((T_LO, 0.42), T_HI - T_LO, 0.26,
                       facecolor=MAGENTA, alpha=0.22, edgecolor=MAGENTA, lw=1.2))
bx.plot([T_MEAN, T_MEAN], [0.36, 0.74], color=BLUE, lw=2.2)
bx.text(T_MEAN, 0.78, "reported mean 82 ms  —  nominal value used only in this illustration",
        ha="center", va="bottom", color=BLUE, fontsize=10)

bx.annotate("", xy=(T_LO, 0.30), xytext=(T_HI, 0.30),
            arrowprops=dict(arrowstyle="<|-|>", color=MAGENTA, lw=1.4))
bx.text(T_LO, 0.25, "35 ms", ha="center", va="top", color=MAGENTA, fontsize=9.5)
bx.text(T_HI, 0.25, "110 ms", ha="center", va="top", color=MAGENTA, fontsize=9.5)
bx.text((T_LO + T_HI) / 2, 0.13,
        "reported range width 75 ms  —  sample density unavailable",
        ha="center", va="top", color=MAGENTA, fontsize=9.8)

bx.set_xlim(20, 125)
bx.set_ylim(-0.05, 1.05)
bx.set_yticks([])
bx.set_xlabel("project-reported latency proxy (ms)   —   not independently reproduced")
for s in ("top", "right", "left"):
    bx.spines[s].set_visible(False)
bx.grid(axis="x", alpha=0.22, lw=0.6)

fig.tight_layout()
output = (Path(__file__).resolve().parents[2]
          / "chapters/5.Advanced/images/adv-field-latency-loop.png")
fig.savefig(output, dpi=150)
print("saved adv-field-latency-loop.png")
