# Lineage of the three RM vision projects dissected in this part of the book.
#
# Every arrow is backed by something checkable in the repositories, not by
# folklore:
#   sp_vision_25/readme.md:333-335  bibliography [3] = rm.cv.fans, [4] = rm_vision
#   sp_vision_25/readme.md:319      "no need to consider fire delay ... [3]"
#   sp_vision_25/readme.md:329-331  [1][2] = the borrowed four-point detectors
#   tasks/auto_aim/solver.cpp:220-252  SJTU_cost -- byte-for-byte the same body,
#                                      and the same Chinese comments, as
#                                      rm.cv.fans aimer/auto_aim/predictor/motion/
#                                      top_model.cpp get_pts_cost; call site
#                                      commented out at solver.cpp:260
# Star/fork counts and dates are GitHub repo metadata read at the time of
# writing (2026-07); LOC are wc -l over *.cpp/*.hpp in each clone.
#
# Generates chapters/6.Projects/images/proj-lineage.png
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Rectangle

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
GREEN, ORANGE, INK = "#2F9E44", "#E8890C", "#222222"
mpl.rcParams.update({"font.size": 10.0, "axes.linewidth": 0.0})

fig, ax = plt.subplots(figsize=(12.6, 8.4), dpi=150)
ax.set_xlim(0, 122)
ax.set_ylim(0, 92)
ax.axis("off")


def card(x, y, w, h, title, role, lines, col, lic_ok):
    ax.add_patch(FancyBboxPatch(
        (x, y), w, h, boxstyle="round,pad=0.7,rounding_size=1.6",
        linewidth=1.6, edgecolor=col, facecolor=col, alpha=1.0, zorder=3))
    ax.text(x + w / 2, y + h - 3.4, title, ha="center", va="center", fontsize=12,
            fontweight="bold", color="white", zorder=5)
    ax.text(x + w / 2, y + h - 8.0, role, ha="center", va="center", fontsize=9.4,
            color="white", style="italic", zorder=5)
    ax.text(x + 2.6, y + h - 12.2, lines, ha="left", va="top", fontsize=8.3,
            color="white", zorder=5, linespacing=1.62)
    tag = "MIT" if lic_ok else "NO LICENSE"
    ax.text(x + w - 2.6, y + 2.2, tag, ha="right", va="center", fontsize=8.2,
            fontweight="bold", color=col, zorder=6,
            bbox=dict(boxstyle="round,pad=0.24", fc="white", ec="white", lw=0))


CY, CH = 42, 30
CTOP = CY + CH

card(2, CY, 33, CH, "rm_vision", "the most standard framework",
     "chenjunnn, personal, not a team\n"
     "ROS 2 Humble, 4 repos / 6 packages\n"
     "9-state whole-car EKF, ~2.0k LOC\n"
     "ballistics + fire control pushed to MCU\n"
     "algorithm frozen since 2023-05\n"
     "211 stars / 18 forks", BLUE, True)

card(44.5, CY, 33, CH, "rm.cv.fans  (LMTD)", "the most extreme algorithm",
     "julyfun, SJTU background\n"
     "no ROS, home-made UMT pub/sub\n"
     "yaw-only pose search, ternary angle\n"
     "six-segment latency model\n"
     "522-line engineering log, failures kept\n"
     "284 stars / 61 forks", MAGENTA, False)

card(87, CY, 33, CH, "sp_vision_25", "the most complete engineering",
     "Tongji SuperPower, a team\n"
     "no ROS (optional plugin), one main\n"
     "11-state EKF, NIS consistency check\n"
     "trajectory planner over TinyMPC\n"
     "21 standalone tests, per-robot YAML\n"
     "514 stars / 136 forks, still active", GREEN, True)

# ---- band A: subtitle + the rm_vision -> sp_vision paradigm arc ------------
ax.text(61, 89.5,
        "read it as a relay, not a ranking: a framework norm, then a fire-control "
        "theory, then an engineering synthesis that carries both",
        ha="center", va="center", fontsize=9.2, color=INK, style="italic")

# arc lands on the top-left corner of sp_vision; the endpoint is kept level with
# the card tops so the whole arc stays clear of the rm.cv.fans card below it
ax.add_patch(FancyArrowPatch((18.5, CTOP + 0.8), (88.0, CTOP + 0.4),
                             color=BLUE, lw=2.0, arrowstyle="-|>", mutation_scale=18,
                             connectionstyle="arc3,rad=-0.24", zorder=2))
ax.text(46, 85.0, "whole-car EKF paradigm  ·  cited as [4] in the bibliography",
        ha="center", va="center", fontsize=8.8, color=BLUE, fontweight="bold",
        bbox=dict(boxstyle="round,pad=0.34", fc="white", ec=BLUE, lw=0.9), zorder=6)

# ---- band B: external model donors, straight above sp_vision --------------
ax.add_patch(Rectangle((87, 74.5), 33, 8.0, facecolor="white", edgecolor=ORANGE,
                       linewidth=1.2, zorder=3))
ax.text(103.5, 78.5, "four-point detector weights [1][2]\n"
                     "Shenzhen Univ. RobotPilots · USTB Reborn",
        ha="center", va="center", fontsize=8.3, color=ORANGE, linespacing=1.45, zorder=5)
ax.add_patch(FancyArrowPatch((103.5, 74.3), (103.5, CTOP + 0.6), color=ORANGE,
                             lw=1.7, arrowstyle="-|>", mutation_scale=16, zorder=2))

# ---- band C: rm.cv.fans -> sp_vision, straight through the gap ------------
ax.add_patch(FancyArrowPatch((78.6, CY + CH * 0.50), (85.8, CY + CH * 0.50),
                             color=MAGENTA, lw=1.9, arrowstyle="-|>",
                             mutation_scale=17, zorder=2))

# rm_vision <-> rm.cv.fans: contemporaries, no evidence of borrowing
ax.add_patch(FancyArrowPatch((36.2, CY + CH * 0.50), (43.2, CY + CH * 0.50),
                             color=GRAY, lw=1.4, arrowstyle="-", linestyle=(0, (4, 3)),
                             mutation_scale=14, zorder=2))
# kept to three short lines so the label fits inside the 9.5-unit gap
ax.text(39.7, CY + CH * 0.50 - 2.4, "same era,\nno borrowing\nfound", ha="center",
        va="top", fontsize=7.2, color="#6E6E6E", linespacing=1.35, zorder=6)

# ---- band D: the two magenta contributions, labelled below the cards ------
ax.add_patch(FancyArrowPatch((61, CY - 1.0), (103.5, CY - 1.0),
                             color=MAGENTA, lw=1.6, arrowstyle="-|>", mutation_scale=15,
                             connectionstyle="arc3,rad=0.30", zorder=2))
ax.text(46, 28.6,
        "cited as [3]:  fire-control vocabulary and latency theory\n"
        "\"bullets leave like a stream of water\"  ·  hit rate vs kill time\n"
        "and lifted as code:  get_pts_cost $\\rightarrow$ SJTU_cost, same body, same\n"
        "comments — then commented out at solver.cpp:260",
        ha="center", va="center", fontsize=8.4, color=MAGENTA, linespacing=1.5,
        bbox=dict(boxstyle="round,pad=0.36", fc="white", ec=MAGENTA, lw=0.9), zorder=6)

# ---- band E: timeline ----------------------------------------------------
TY = 6.0
ax.add_patch(FancyArrowPatch((3, TY), (119, TY), color=INK, lw=1.2,
                             arrowstyle="-|>", mutation_scale=14, zorder=2))
for xpos, lab in [(8, "2022"), (33, "2023"), (58, "2024"), (83, "2025"), (108, "2026")]:
    ax.plot([xpos], [TY], marker="|", color=INK, ms=9, zorder=3)
    ax.text(xpos, TY - 2.6, lab, ha="center", va="top", fontsize=8.6, color=INK)


def span(x0, x1, y, col, lab, dashed_after=None):
    ax.plot([x0, x1], [y, y], color=col, lw=4.2, solid_capstyle="round", zorder=3)
    if dashed_after is not None:
        ax.plot([x1, dashed_after], [y, y], color=col, lw=1.4, ls=":", zorder=3)
    ax.text(x0 - 1.2, y, lab, ha="right", va="center", fontsize=7.9, color=col)


span(8.5, 42, TY + 12.0, BLUE, "rm_auto_aim  (frozen 2023-05)", dashed_after=108)
span(64, 96, TY + 8.0, MAGENTA, "rm.cv.fans public repo")
span(31, 118, TY + 4.0, GREEN, "sp_vision  23 $\\rightarrow$ 24 $\\rightarrow$ 25")

fig.tight_layout()
out = "chapters/6.Projects/images/proj-lineage.png"
fig.savefig(out, dpi=150, bbox_inches="tight")
print("wrote", out)
