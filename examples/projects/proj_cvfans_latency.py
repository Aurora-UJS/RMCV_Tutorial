# rm.cv.fans' six-point latency decomposition, drawn to scale, and what each
# segment costs in aim angle against a fast spinner.
#
# Sources (all read from the repository, nothing invented):
#   docs/auto_aim/latency.md:7-14   the six named time points
#   aimer/base/robot/coord_converter.hpp:153-164  the six getter functions
#   aimer/base/robot/coord_converter.cpp:143-147  prediction horizon
#       = img_to_predict + predict_to_send + send_to_control + fire_to_hit
#       -> control_to_fire is DELIBERATELY absent
#   aimer/base/robot/coord_converter.cpp:155-159  hit horizon = all five
#   aimer/base/robot/coord_converter.cpp:137-141  fire_to_hit = |aim| / v0,
#       with the in-code comment "不考虑空气阻力"
#   assets/base.param.toml:41,44    send-to-control = -18e-3 (NEGATIVE),
#                                   control-to-fire = +20e-3
#   aimer/auto_aim/README.md:317    measured img->fire mean ~82 ms
#   aimer/auto_aim/README.md:319    120 rpm swerve: 10 ms of error <-> 7 deg
#
# The vision-side block (img->predict->send) is not a stored constant: it is
# measured per frame / filtered online, so its 80 ms width here is BACKED OUT
# of the 82 ms measured mean minus the two configured segments, and the
# internal predict tick is drawn dashed to mark that the split is not known.
#
# The read-it rule: the two big segments -- vision (58 deg) and flight
# (86 deg) -- each on their own clear the 30 deg at which this project
# measured anti-spin hit rate hitting zero. The other two (13 deg, 14 deg)
# do not reach that line, but each is still about twice the 7.2 deg that a
# single 10 ms slip costs -- which is why none of them may be lumped away.
#
# Generates chapters/6.Projects/images/proj-cvfans-latency.png
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch

mpl.rcParams.update({"font.size": 10.5})

BLUE, MAGENTA, GREY = "#3B6FD4", "#D6336C", "#8A8A8A"
GREEN = "#2E7D32"

# ---- segment budget [ms] ---------------------------------------------------
IMG_TO_FIRE = 82.0          # measured mean, README:317
SEND_TO_CONTROL = -18.0     # base.param.toml:41
CONTROL_TO_FIRE = 20.0      # base.param.toml:44
VISION = IMG_TO_FIRE - SEND_TO_CONTROL - CONTROL_TO_FIRE   # = 80.0
DIST, V0 = 3.0, 25.0
FIRE_TO_HIT = DIST / V0 * 1e3                              # = 120.0, no drag

DEG_PER_MS = 720.0 / 1000.0    # 120 rpm = 2 rev/s = 720 deg/s

t_img = 0.0
t_predict = VISION * 0.55       # split unknown -> drawn dashed
t_send = VISION
t_control = t_send + SEND_TO_CONTROL
t_fire = t_send + SEND_TO_CONTROL + CONTROL_TO_FIRE
t_hit = t_fire + FIRE_TO_HIT

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(11.4, 7.2),
                               gridspec_kw={"height_ratios": [1.25, 1.0]})

# ================= panel 1: Gantt (segments never overlap on a row) =========
ticks = [(t_img, "img", "exposure mid-point"),
         (t_predict, "predict", "split not knowable"),
         (t_send, "send", "measurable"),
         (t_control, "control", "param"),
         (t_fire, "fire", "param"),
         (t_hit, "hit", "computed")]
TOP = 5.4
for t, name, sub in ticks:
    dashed = (name == "predict")
    ax1.plot([t, t], [-0.55, TOP], color="k", lw=1.0,
             ls=":" if dashed else "-", alpha=0.55, zorder=1)

# staggered tick labels so the 80/62/82 ms cluster stays readable
lab = {"img": (0, TOP + 0.75, True), "predict": (0, TOP + 0.75, True),
       "control": (-15, TOP - 0.28, False), "send": (0, TOP + 0.75, True),
       "fire": (14, TOP - 0.28, False), "hit": (0, TOP + 0.75, True)}
for t, name, sub in ticks:
    dx, y, show_sub = lab[name]
    ax1.text(t + dx, y, name, ha="center", va="bottom", fontsize=9.5,
             weight="bold", zorder=5)
    if show_sub:
        ax1.text(t + dx, y - 0.42, sub, ha="center", va="bottom", fontsize=7.4,
                 color=GREY, zorder=5)
    else:
        ax1.plot([t, t + dx], [y + 0.07, y + 0.07], color=GREY, lw=0.7,
                 alpha=0.7, zorder=5)

rows = [
    (4, t_img, VISION, BLUE,
     "vision compute + transfer  80 ms   (measured per frame / filtered)"),
    (3, t_send, SEND_TO_CONTROL, MAGENTA,
     "send→control  −18 ms   ← runs BACKWARDS: not a physical latency"),
    (2, t_control, CONTROL_TO_FIRE, MAGENTA,
     "control→fire  20 ms   (param)"),
    (1, t_fire, FIRE_TO_HIT, GREY,
     f"fire→hit  {FIRE_TO_HIT:.0f} ms  = |aim| / v0, NO drag  "
     f"({DIST:.0f} m at {V0:.0f} m/s)"),
]
H = 0.52
for y, x0, w, colour, text in rows:
    ax1.add_patch(plt.Rectangle((min(x0, x0 + w), y - H / 2), abs(w), H,
                                facecolor=colour, alpha=0.32,
                                edgecolor=colour, lw=1.2, zorder=3))
    if w < 0:   # draw the backwards arrow inside the row
        ax1.annotate("", xy=(x0 + w, y), xytext=(x0, y), zorder=4,
                     arrowprops=dict(arrowstyle="->", color=MAGENTA, lw=1.6))
    ax1.text(max(x0, x0 + w) + 5, y, text, ha="left", va="center",
             fontsize=8.7, color=colour if colour != GREY else "#4A4A4A",
             zorder=5)

# the two horizons
ax1.add_patch(FancyArrowPatch((t_img, 0), (t_control, 0), arrowstyle="-",
                              color=GREEN, lw=3.4, alpha=0.9, zorder=3))
ax1.plot([t_control, t_fire], [0, 0], color=GREEN, lw=3.4, ls=":", alpha=0.45,
         zorder=3)
ax1.add_patch(FancyArrowPatch((t_fire, 0), (t_hit, 0), arrowstyle="->",
                              color=GREEN, lw=3.4, alpha=0.9,
                              mutation_scale=14, zorder=3))
ax1.add_patch(FancyArrowPatch((t_img, -1), (t_hit, -1), arrowstyle="->",
                              color="#7A4FBF", lw=3.4, alpha=0.9,
                              mutation_scale=14, zorder=3))
ax1.text((t_control + t_fire) / 2, 0.34, "skipped", ha="center", va="bottom",
         fontsize=7.8, color=GREEN, style="italic")
ax1.text(t_hit + 5, 0, "prediction horizon = where to point\n"
         "(control→fire deliberately dropped)", va="center", fontsize=8.7,
         color=GREEN)
ax1.text(t_hit + 5, -1, "hit horizon = when this bullet lands\n"
         "(all five segments)", va="center", fontsize=8.7, color="#7A4FBF")

ax1.set_xlim(-16, t_hit + 128)
ax1.set_ylim(-1.7, TOP + 1.45)
ax1.set_yticks([])
ax1.set_xticks([0, 50, 100, 150, 200])
ax1.set_xlabel("time after exposure mid-point  [ms]")
ax1.spines[["left", "right", "top"]].set_visible(False)
ax1.set_title("Six named time points, drawn to scale — and the two different "
              "sums built from them", fontsize=11, pad=26)

# ================= panel 2: what each segment costs in aim angle =============
segs = [("vision compute\n+ transfer", VISION, BLUE),
        ("send→control\n(−18 ms)", abs(SEND_TO_CONTROL), MAGENTA),
        ("control→fire\n(20 ms)", CONTROL_TO_FIRE, MAGENTA),
        (f"fire→hit\n({DIST:.0f} m)", FIRE_TO_HIT, GREY)]
names = [s[0] for s in segs]
vals = [s[1] * DEG_PER_MS for s in segs]
cols = [s[2] for s in segs]

bars = ax2.barh(range(len(segs)), vals, color=cols, alpha=0.75, height=0.6)
for b, v, ms in zip(bars, vals, [s[1] for s in segs]):
    ax2.text(v + 1.5, b.get_y() + b.get_height() / 2,
             f"{v:.0f}°   ({ms:.0f} ms)", va="center", fontsize=9)

for x, colour, style, yy, txt in (
        (7.2, GREY, "-.", 1.13, "7.2° = one 10 ms slip"),
        (30, MAGENTA, "--", 1.02, "30° = anti-spin hit rate 0"),
        (45, "k", ":", 1.13, "45° = midway between plates")):
    ax2.axvline(x, color=colour, lw=1.5, ls=style, zorder=1)
    ax2.text(x, yy, txt, transform=ax2.get_xaxis_transform(),
             color=colour, fontsize=8.2, ha="center", va="bottom")

ax2.set_yticks(range(len(segs)))
ax2.set_yticklabels(names, fontsize=8.8)
ax2.invert_yaxis()
ax2.set_xlim(0, 108)
ax2.set_xlabel("aim error if this segment were simply ignored  [deg]   "
               "(120 rpm swerve = 720 °/s)")
ax2.grid(axis="x", alpha=0.25, lw=0.6)
ax2.set_title("Why none of them may be lumped away", fontsize=11, pad=38)

fig.suptitle(
    "Latency is not one constant: rm.cv.fans splits it into six time points, "
    "then builds TWO different sums from them\n"
    "vision (58°) and flight (86°) each clear on their own the 30° at which "
    "this project's own anti-spin hit rate goes to zero; the other two are "
    "still ~2x the 7.2° that one 10 ms slip already costs",
    fontsize=11.5, y=1.01)
fig.tight_layout(rect=(0, 0, 1, 0.985))
fig.savefig("chapters/6.Projects/images/proj-cvfans-latency.png",
            dpi=150, bbox_inches="tight")

print(f"vision {VISION:.0f} ms -> {VISION*DEG_PER_MS:.1f} deg")
print(f"send->control {SEND_TO_CONTROL} ms -> "
      f"{abs(SEND_TO_CONTROL)*DEG_PER_MS:.1f} deg")
print(f"control->fire {CONTROL_TO_FIRE} ms -> "
      f"{CONTROL_TO_FIRE*DEG_PER_MS:.1f} deg")
print(f"fire->hit {FIRE_TO_HIT:.0f} ms -> {FIRE_TO_HIT*DEG_PER_MS:.1f} deg")
print(f"img->hit total {t_hit:.0f} ms; img->fire {t_fire:.0f} ms")
print(f"10 ms -> {10*DEG_PER_MS:.1f} deg  (README:319 says 7)")
