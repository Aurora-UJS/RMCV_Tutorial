# Auto-aim system architecture & dataflow for the system-integration chapter.
# Draws the canonical ROS 2 orchestration: camera + detector in one
# intra-process container, tracker in the odom frame, serial driver bridging
# to the MCU. robot_state_publisher emits only the static chain on /tf_static;
# the load-bearing odom->gimbal_link is broadcast by the serial driver at
# whatever rate MCU packets arrive.
# Timing annotations show the staggered start (serial +1.5 s, tracker +2.0 s).
# Generates chapters/4.Application/images/app-autoaim-architecture.png
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
GREEN, ORANGE, INK = "#2F9E44", "#E8890C", "#222222"
mpl.rcParams.update({"font.size": 10.5, "axes.linewidth": 0.0})

fig, ax = plt.subplots(figsize=(11.0, 5.8), dpi=150)
ax.set_xlim(0, 112)
ax.set_ylim(0, 60)
ax.axis("off")

YB, HB = 34, 15          # box bottom / height for the main row
YM = YB + HB / 2         # vertical mid-line of the row


def box(x, w, title, sub, fc, ec, tcol="white"):
    ax.add_patch(FancyBboxPatch(
        (x, YB), w, HB, boxstyle="round,pad=0.6,rounding_size=1.4",
        linewidth=1.4, edgecolor=ec, facecolor=fc, zorder=3))
    ax.text(x + w / 2, YB + HB * 0.64, title, ha="center", va="center",
            fontsize=11, fontweight="bold", color=tcol, zorder=4)
    ax.text(x + w / 2, YB + HB * 0.28, sub, ha="center", va="center",
            fontsize=8.2, color=tcol, zorder=4, linespacing=1.35)


def topic(xc, label, col):
    ax.text(xc, YM, label, ha="center", va="center", fontsize=8.4, color=col,
            fontweight="bold", zorder=6, linespacing=1.2,
            bbox=dict(boxstyle="round,pad=0.22", fc="white", ec=col, lw=0.8))


# ---- box geometry (wide gaps so topic labels sit clear in the gaps) -------
cam = (3, 15)          # ends 18
det = (27, 15)         # ends 42
trk = (51, 17)         # ends 68
ser = (77, 13)         # ends 90
mcu = (98, 11)         # ends 109

# ---- intra-process container (camera + detector share one process) --------
ax.add_patch(Rectangle((1.4, 32), 42.2, 24.5, linewidth=1.3, edgecolor=GREEN,
                       facecolor="#2F9E4415", linestyle=(0, (5, 3)), zorder=1))
ax.text(22.5, 54.4, "component container  ·  use_intra_process_comms = True",
        ha="center", va="center", fontsize=8.8, color=GREEN, fontweight="bold")

box(*cam, "Camera Node", "expose 2.5 ms / gain 8\nBayer -> cv::Mat", BLUE, "#2A55B0")
box(*det, "Armor Detector", "4-stage cascade + MLP\nPnP -> camera frame", BLUE, "#2A55B0")
box(*trk, "Armor Tracker", "9-state EKF\nwhole-vehicle model\nframe: odom", MAGENTA, "#A61E4D")
box(*ser, "Serial Driver", "TX / RX threads\nTF broadcaster", ORANGE, "#B96A00")
box(*mcu, "MCU (STM32)", "ballistics\n+ fire", INK, "#000000")

# ---- forward pipeline arrows (drawn under the topic chips) -----------------
def fwd(x0, x1, col):
    ax.add_patch(FancyArrowPatch((x0, YM), (x1, YM), arrowstyle="-|>",
                 mutation_scale=15, linewidth=2.2, color=col,
                 shrinkA=1, shrinkB=1, zorder=2))

fwd(18, 27, BLUE);   topic(22.5, "/image_raw", BLUE)
fwd(42, 51, BLUE);   topic(46.5, "/detector/\narmors", BLUE)
fwd(68, 77, MAGENTA); topic(72.5, "/tracker/\ntarget", MAGENTA)
fwd(90, 98, ORANGE); topic(94, "Send\nPacket", ORANGE)

# ---- MCU -> serial feedback (gimbal pose + measured muzzle speed) ----------
ax.add_patch(FancyArrowPatch((98, YB + 3), (90, YB + 3), arrowstyle="-|>",
             mutation_scale=12, linewidth=1.5, color=INK, zorder=4))
ax.text(94, YB + 1.0, "gimbal q, v0", ha="center", va="center", fontsize=7.6,
        color=INK, zorder=5,
        bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.9))

# ---- robot_state_publisher / TF tree (bottom-centre) ----------------------
YT, HT = 9, 11
ax.add_patch(FancyBboxPatch((48, YT), 20, HT,
             boxstyle="round,pad=0.6,rounding_size=1.4", linewidth=1.4,
             edgecolor="#5A5A5A", facecolor=GRAY, zorder=3))
ax.text(58, YT + HT * 0.66, "robot_state_publisher", ha="center", va="center",
        fontsize=10, fontweight="bold", color="white", zorder=4)
ax.text(58, YT + HT * 0.30, "URDF -> /tf_static\ngimbal -> camera -> optical",
        ha="center", va="center", fontsize=8.0, color="white", zorder=4,
        linespacing=1.3)

# TF up into the tracker (poses get transformed camera -> odom here)
ax.add_patch(FancyArrowPatch((60, YT + HT), (59, YB), arrowstyle="-|>",
             mutation_scale=13, linewidth=1.6, color="#5A5A5A",
             linestyle=(0, (4, 2)), zorder=2))
ax.text(45.5, 25.5, "TF: pose ->\nodom frame", ha="center", va="center",
        fontsize=7.9, color="#5A5A5A", linespacing=1.2)

# serial feeds the live gimbal transform into the TF tree
ax.add_patch(FancyArrowPatch((80, YB), (66, YT + HT - 1),
             connectionstyle="arc3,rad=-0.18", arrowstyle="-|>",
             mutation_scale=12, linewidth=1.5, color=ORANGE,
             linestyle=(0, (4, 2)), zorder=2))
ax.text(79.5, 24.0, "odom->gimbal\n+ timestamp_offset", ha="center", va="center",
        fontsize=7.7, color="#B96A00", linespacing=1.2)

# serial -> detector: param set (detect_color / reset_tracker)
ax.add_patch(FancyArrowPatch((79, YB), (40, YB - 0.5),
             connectionstyle="arc3,rad=0.30", arrowstyle="-|>",
             mutation_scale=12, linewidth=1.4, color="#7048E8",
             linestyle=(0, (4, 2)), zorder=2))
ax.text(30, 26.0, "param set: detect_color / reset_tracker", ha="center",
        va="center", fontsize=7.9, color="#7048E8")

# ---- startup timeline (bottom lane) ---------------------------------------
ty = 2.6
ax.add_patch(FancyArrowPatch((5, ty), (108, ty), arrowstyle="-|>",
             mutation_scale=13, linewidth=1.4, color=INK, zorder=2))
ax.text(109, ty, "t", ha="left", va="center", fontsize=10, style="italic")
for tx, lab, col in [(10, "t = 0\ncontainer + robot_state_pub", GREEN),
                     (52, "t = 1.5 s\nserial driver", ORANGE),
                     (84, "t = 2.0 s\ntracker", MAGENTA)]:
    ax.plot([tx], [ty], "o", ms=7, color=col, zorder=4)
    ax.text(tx, ty - 1.3, lab, ha="center", va="top", fontsize=8.0, color=col,
            linespacing=1.2)

ax.set_title("Auto-aim dataflow: camera -> detect -> track (odom) -> serial -> MCU.   "
             "TF tree and startup order are load-bearing, not incidental.",
             fontsize=11.5, fontweight="bold", pad=8)

fig.tight_layout()
fig.savefig("chapters/4.Application/images/app-autoaim-architecture.png",
            bbox_inches="tight", facecolor="white")
print("saved app-autoaim-architecture.png")
