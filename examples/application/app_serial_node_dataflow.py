#!/usr/bin/env python3
"""Execution paths and ROS 2 interfaces of the serial-driver node.

Mechanism figure for the "串口模块" chapter. Shows how the ROS serial-driver node
connects the MCU-side serial stream to the vision pipeline.

Output: chapters/4.Application/images/app-serial-node-dataflow.png (dpi 150).
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

C_NODE = "#2f6f9f"
C_RXTH = "#3b7fb0"
C_TXCB = "#8a5a2b"
C_DEV = "#4a4a55"
C_TF = "#2e8b57"
C_PARAM = "#d97a2b"
C_RESET = "#7d4fb0"
C_SUB = "#555555"

fig, ax = plt.subplots(figsize=(11.2, 6.4))
ax.set_xlim(0, 112)
ax.set_ylim(0, 64)
ax.axis("off")


def box(x, y, w, h, text, fc, tc="white", fs=10, ec=None, lw=1.2, style="round,pad=0.3"):
    p = FancyBboxPatch((x, y), w, h, boxstyle=style,
                       linewidth=lw, edgecolor=ec or fc, facecolor=fc)
    ax.add_patch(p)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            color=tc, fontsize=fs, zorder=5)


def arrow(x1, y1, x2, y2, color, lw=2.0, style="-|>", ls="-", rad=0.0):
    a = FancyArrowPatch((x1, y1), (x2, y2), arrowstyle=style,
                        mutation_scale=16, linewidth=lw, color=color,
                        linestyle=ls, connectionstyle=f"arc3,rad={rad}",
                        shrinkA=2, shrinkB=2, zorder=4)
    ax.add_patch(a)


# --- serial device (left) ---
box(2, 27, 15, 10, "/dev/rm_serial\n(udev SYMLINK)", C_DEV, fs=9.5)
ax.text(9.5, 24.3, "UART or USB CDC\n(rate from configuration)", ha="center", va="center",
        fontsize=8, color="#666666", style="italic")

# --- the node (center) ---
box(27, 8, 40, 48, "", "#eef4fa", ec=C_NODE, lw=1.6, style="round,pad=0.4")
ax.text(47, 52.5, "RMSerialDriver  node", ha="center", va="center",
        fontsize=11.5, color=C_NODE, weight="bold")

# receive thread
box(30, 33, 34, 13, "receive_thread\n(blocking read loop)\nsync header 0x5A -> CRC16",
    C_RXTH, fs=9)
# send callback
box(30, 12, 34, 11, "sendData callback\nfill SendPacket 0xA5\nCRC16 -> write_some",
    C_TXCB, fs=9)

# Both paths can enter the same reopen routine concurrently.
box(32, 25.5, 30, 5.5, "shared reopenPort()\nrecursive retry; calls may overlap\n(no lock)",
    "#fae7e7", tc="#a52a2a", ec="#b03030", lw=1.2, fs=7.4)
arrow(47, 33, 47, 31, "#b03030", lw=1.4, ls=(0, (4, 3)))
arrow(47, 23, 47, 25.5, "#b03030", lw=1.4, ls=(0, (4, 3)))

# device <-> node bidirectional
arrow(17, 40, 30, 40, C_RXTH, lw=2.4)          # RX in
arrow(30, 17.5, 17, 17.5, C_TXCB, lw=2.4)      # TX out
ax.text(23.5, 42.4, "bytes in", ha="center", fontsize=8, color=C_RXTH)
ax.text(23.5, 19.9, "bytes out", ha="center", fontsize=8, color=C_TXCB)

# --- three receive-side outputs ---
box(78, 46, 31, 9, "tf: odom -> gimbal_link\n(+ timestamp_offset)", C_TF, fs=9)
box(78, 33.5, 31, 9, "setParam detect_color\n-> armor_detector", C_PARAM, fs=9)
box(78, 21, 31, 9, "reset_tracker\n-> /tracker/reset", C_RESET, fs=9)

arrow(64, 42, 78, 50.5, C_TF, lw=2.0, rad=0.12)
arrow(64, 40, 78, 38, C_PARAM, lw=2.0, rad=0.05)
arrow(64, 37, 78, 25.5, C_RESET, lw=2.0, rad=-0.14)

# --- subscription into send callback (from tracker) ---
box(78, 10, 31, 9, "/tracker/target\n(tracker node)", "#ffffff", tc=C_SUB,
    ec=C_SUB, lw=1.3, fs=9)
arrow(78, 14.5, 64, 16.5, C_SUB, lw=2.0, rad=0.10)
ax.text(72, 12.0, "subscribe", ha="center", fontsize=8, color=C_SUB)

# Label for the receive-side outputs.
ax.text(93.5, 57.2, "outputs derived from a valid receive packet", ha="center",
        fontsize=9, color="#444444", weight="bold")

# Title and reading note.
fig.suptitle("Serial node: one receive thread, one send callback, and three receive-side outputs",
             fontsize=12.5, weight="bold", y=0.975)
ax.text(56, 2.0,
        "The receive thread validates incoming packets before updating TF, detect_color, and tracker reset.\n"
        "The target subscription callback formats and writes outgoing packets; either path can call reopenPort() after an exception.",
        ha="center", va="center", fontsize=8.4, color="#333333")

plt.tight_layout(rect=[0, 0.02, 1, 0.95])
output_path = Path(__file__).resolve().parents[2] / "chapters/4.Application/images/app-serial-node-dataflow.png"
plt.savefig(output_path, dpi=150,
            bbox_inches="tight", facecolor="white")
print(f"saved {output_path}")
