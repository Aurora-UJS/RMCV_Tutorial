# rm_vision ROS 2 wiring diagram for the project-analysis chapter.
# This figure shows the default hardware launch, not every repository linked by
# the umbrella README. The selected camera and armor_detector are ComposableNodes
# inside one component_container with use_intra_process_comms; everything
# downstream crosses DDS. The Unity simulator is an external, manual input path.
# Generates chapters/6.Projects/images/proj-rmvision-dataflow.png
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
GREEN, ORANGE, INK = "#2F9E44", "#E8890C", "#222222"
mpl.rcParams.update({"font.size": 10.0, "axes.linewidth": 0.0})

fig, ax = plt.subplots(figsize=(12.8, 7.2), dpi=150)
ax.set_xlim(0, 126)
ax.set_ylim(4, 82)
ax.axis("off")

YB, HB = 44.0, 13.0
YM = YB + HB / 2.0
YLAB = YM + 12.5

# ---- the intra-process container -------------------------------------------
ax.add_patch(Rectangle((2.0, YB - 11.0), 47.0, HB + 14.0, linewidth=1.6,
                       edgecolor=GREEN, facecolor="#EAF7EE", linestyle=(0, (5, 3)),
                       zorder=1))
ax.text(25.5, YB - 4.6, "component_container: one process\nuse_intra_process_comms: True",
        ha="center", va="center", fontsize=8.4, color=GREEN, fontweight="bold",
        zorder=2, linespacing=1.4)
ax.text(25.5, YB - 9.0, "vision_bringup.launch.py:24-45", ha="center", va="center",
        fontsize=7.6, color=GREEN, style="italic", zorder=2)


def node(x, w, title, sub, fc, ec, tcol="white"):
    ax.add_patch(FancyBboxPatch((x, YB), w, HB,
                                boxstyle="round,pad=0.55,rounding_size=1.3",
                                linewidth=1.4, edgecolor=ec, facecolor=fc, zorder=3))
    ax.text(x + w / 2, YB + HB * 0.68, title, ha="center", va="center",
            fontsize=10.2, fontweight="bold", color=tcol, zorder=4)
    ax.text(x + w / 2, YB + HB * 0.27, sub, ha="center", va="center",
            fontsize=7.5, color=tcol, zorder=4, linespacing=1.3)


node(4.5, 18.0, "camera_node", "Hik or MindVision\nselected at launch", GRAY, GRAY)
node(29.0, 18.0, "armor_detector", "detector.cpp 245 L\ndetector_node.cpp 292 L", BLUE, BLUE)
node(56.5, 19.0, "armor_tracker", "tracker.cpp 239 L\ntracker_node.cpp 350 L", BLUE, BLUE)
node(85.0, 19.0, "rm_serial_driver", "Apache-2.0\nrm_serial_driver.cpp", MAGENTA, MAGENTA)
node(112.0, 11.5, "STM32", "MCU", "white", INK, tcol=INK)


def edge(x0, x1, y, col, lw):
    ax.add_patch(FancyArrowPatch((x0, y), (x1, y), arrowstyle="-|>",
                                 mutation_scale=15, linewidth=lw, color=col,
                                 shrinkA=0, shrinkB=0, zorder=5))


def label(xc, y, txt, col, fs=7.8):
    ax.text(xc, y, txt, ha="center", va="center", fontsize=fs, color=col,
            fontweight="bold", zorder=6, linespacing=1.35,
            bbox=dict(boxstyle="round,pad=0.28", fc="white", ec=col, lw=0.9))


# ---- forward chain ---------------------------------------------------------
edge(22.5, 29.0, YM, GREEN, 3.6)
label(20.0, YLAB,
      "/image_raw + /camera_info\nsensor_msgs/Image + sensor_msgs/CameraInfo\n"
      "Hik: sensor-data QoS . MV: default reliable\nintra-process within container",
      GREEN)
ax.plot([25.7, 25.7], [YLAB - 4.2, YM + 1.4], lw=0.9, color=GREEN, ls=(0, (2, 2)), zorder=2)

edge(47.0, 56.5, YM, BLUE, 2.2)
label(51.7, YLAB, "/detector/armors\nauto_aim_interfaces/Armors\nSensorDataQoS . DDS", BLUE)
ax.plot([51.7, 51.7], [YLAB - 4.2, YM + 1.4], lw=0.9, color=BLUE, ls=(0, (2, 2)), zorder=2)

edge(75.5, 85.0, YM, BLUE, 2.2)
label(81.5, YLAB, "/tracker/target\nauto_aim_interfaces/Target\nSensorDataQoS . DDS", BLUE)
ax.plot([81.5, 81.5], [YLAB - 4.2, YM + 1.4], lw=0.9, color=BLUE, ls=(0, (2, 2)), zorder=2)

edge(104.0, 112.0, YM, MAGENTA, 2.2)
label(110.5, YLAB, "SendPacket: 48 B under reviewed ABI\n0xA5 + whole-car state + CRC16\nUART budget: 83% at 200 Hz if 115200 8N1", MAGENTA)
ax.plot([110.5, 110.5], [YLAB - 4.2, YM + 1.4], lw=0.9, color=MAGENTA, ls=(0, (2, 2)), zorder=2)

# The MCU reply is the source of the pose, color, reset, and aim-marker branches.
YRX = YB - 5.0
ax.plot([117.75, 117.75], [YB - 0.6, YRX], lw=1.8, color=MAGENTA, zorder=5)
ax.plot([117.75, 101.0], [YRX, YRX], lw=1.8, color=MAGENTA, zorder=5)
ax.add_patch(FancyArrowPatch((101.0, YRX), (101.0, YB - 0.6), arrowstyle="-|>",
                             mutation_scale=13, linewidth=1.8, color=MAGENTA,
                             shrinkA=0, shrinkB=0, zorder=5))
label(110.0, YRX - 3.0,
      "ReceivePacket: 28 B under reviewed ABI\npose + color + reset + aim marker",
      MAGENTA, fs=6.8)

# ---- reverse channel 1: params + service -----------------------------------
YR = YB - 16.0
ax.plot([94.5, 94.5], [YB - 0.6, YR], lw=1.8, color=ORANGE, zorder=5)
ax.plot([94.5, 38.0], [YR, YR], lw=1.8, color=ORANGE, zorder=5)
for xa in (38.0, 66.0):
    ax.add_patch(FancyArrowPatch((xa, YR), (xa, YB - 0.6), arrowstyle="-|>",
                                 mutation_scale=13, linewidth=1.8, color=ORANGE,
                                 shrinkA=0, shrinkB=0, zorder=5))
label(54.0, YR,
      "param write-back: detect_color (AsyncParametersClient)   .   service /tracker/reset (std_srvs/Trigger)",
      ORANGE)

# ---- reverse channel 2: TF -------------------------------------------------
YT = YB - 27.0
ax.plot([99.0, 99.0], [YB - 0.6, YT], lw=1.8, color=INK, zorder=5)
ax.plot([99.0, 71.5], [YT, YT], lw=1.8, color=INK, zorder=5)
ax.add_patch(FancyArrowPatch((71.5, YT), (71.5, YB - 0.6), arrowstyle="-|>",
                             mutation_scale=13, linewidth=1.8, color=INK,
                             shrinkA=0, shrinkB=0, zorder=5))
label(40.0, YT,
      "/tf   odom -> gimbal_link   broadcast by the SERIAL node at packet rate,\n"
      "stamped with (ROS processing time + 0.006 s); packet has no IMU sample timestamp",
      INK)

ax.add_patch(FancyBboxPatch((3.0, YT - 11.0), 44.0, 6.6,
                            boxstyle="round,pad=0.4,rounding_size=1.0",
                            linewidth=1.2, edgecolor=GRAY, facecolor="#F4F4F4", zorder=3))
ax.text(25.0, YT - 7.7,
        "robot_state_publisher -> /tf_static, published once\n"
        "gimbal_link -> camera_link -> camera_optical_frame",
        ha="center", va="center", fontsize=7.8, color=GRAY, fontweight="bold",
        zorder=4, linespacing=1.4)

# ---- header ----------------------------------------------------------------
ax.text(63.0, 79.5,
        "rm_vision hardware wiring: Hik or MindVision feeds the same pipeline",
        ha="center", va="center", fontsize=12.6, fontweight="bold", color=INK)
ax.text(63.0, 74.8,
        "Green marks the shared component container; downstream nodes communicate across process boundaries.\n"
        "The serial node sends target state; the MCU reply supplies TF, color, reset, and aim-marker data.",
        ha="center", va="center", fontsize=8.8, color=INK, linespacing=1.5)

output = (Path(__file__).resolve().parents[2]
          / "chapters/6.Projects/images/proj-rmvision-dataflow.png")
fig.savefig(output, dpi=150, bbox_inches="tight", facecolor="white")
print("saved dataflow")
