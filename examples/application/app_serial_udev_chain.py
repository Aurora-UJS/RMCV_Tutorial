#!/usr/bin/env python3
"""Sysfs parent matching and udev symlink creation for a USB serial device.

Mechanism figure for the udev section of the "串口模块" chapter. Two ideas on one
canvas: (left) the sysfs parent chain that explains ATTR vs ATTRS matching, and
(right) the kernel-event -> udevd -> rule -> stable symlink flow.

Output: chapters/4.Application/images/app-serial-udev-chain.png (dpi 150).
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

C_TTY = "#6b7a8f"
C_IFACE = "#6b7a8f"
C_USB = "#2e8b57"      # highlight: idVendor/idProduct live here
C_EVENT = "#2f6f9f"
C_RULE = "#d97a2b"
C_LINK = "#7d4fb0"
C_BAD = "#b03030"

fig, ax = plt.subplots(figsize=(11.4, 6.8))
ax.set_xlim(0, 114)
ax.set_ylim(0, 68)
ax.axis("off")


def box(x, y, w, h, text, fc, tc="white", fs=9.5, ec=None, lw=1.3, style="round,pad=0.3"):
    p = FancyBboxPatch((x, y), w, h, boxstyle=style,
                       linewidth=lw, edgecolor=ec or fc, facecolor=fc)
    ax.add_patch(p)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            color=tc, fontsize=fs, zorder=5)


def arrow(x1, y1, x2, y2, color, lw=2.0, style="-|>", ls="-", rad=0.0):
    a = FancyArrowPatch((x1, y1), (x2, y2), arrowstyle=style,
                        mutation_scale=15, linewidth=lw, color=color,
                        linestyle=ls, connectionstyle=f"arc3,rad={rad}",
                        shrinkA=2, shrinkB=2, zorder=4)
    ax.add_patch(a)


# ============ LEFT: sysfs parent chain (bottom = leaf, top = root) ============
ax.text(24, 63.5, "sysfs device chain  (udevadm info -a -n /dev/ttyUSB0)",
        ha="center", fontsize=9.3, color="#333333", weight="bold")

box(4, 45.5, 40, 9,
    'usb device   SUBSYSTEM=="usb"\nATTRS{idVendor}=="1a86"\nATTRS{idProduct}=="7523"',
    C_USB, fs=8.3)
box(4, 33, 40, 6.5, 'usb-serial interface   DRIVER=="ch341"', C_IFACE, fs=8.3)
box(4, 21, 40, 6.5, 'ttyUSB0   SUBSYSTEM=="tty"', C_TTY, fs=8.5)

# parent arrows (child -> parent, pointing up)
arrow(24, 27.5, 24, 33, "#888888", lw=1.6)
arrow(24, 39.5, 24, 45.5, "#888888", lw=1.6)
ax.text(27.5, 30.6, "parent", fontsize=7.4, color="#888888", ha="left")
ax.text(27.5, 42.6, "parent", fontsize=7.4, color="#888888", ha="left")

# ATTR checks the current tty; ATTRS may match one parent in this chain.
arrow(44.6, 24.5, 47, 24.5, C_USB, lw=1.8)
arrow(47, 24.5, 47, 50, C_USB, lw=1.8, rad=0)
arrow(47, 50, 44.6, 50, C_USB, lw=1.8)
ax.text(49.0, 37, "ATTRS{}\nmay match\none parent",
        ha="left", va="center", fontsize=7.1, color=C_USB, weight="bold")
ax.text(24, 18.5,
        "ATTR{idVendor}: current tty only -> no match here    |    ATTRS{idVendor}: USB parent -> match",
        ha="center", va="center", fontsize=7.4, color="#555555")

# name-jump problem
box(3, 6, 42, 8.5, "enumeration order can change after boot or replug\nttyUSB0  <->  ttyUSB1",
    "#f4e3e3", tc=C_BAD, ec=C_BAD, lw=1.3, fs=8.6)

# ============ RIGHT: event -> udevd -> rule -> symlink ============
ax.text(86, 63.5, "udev rule evaluation and symlink creation", ha="center",
        fontsize=9.3, color="#333333", weight="bold")

box(60, 54, 52, 6.5, "kernel plug event  (uevent, netlink)", C_EVENT, fs=9)
box(60, 42.5, 52, 8, "systemd-udevd  matches rules files\n/etc/udev/rules.d/*.rules  (lexical order)",
    C_EVENT, fs=8.6)
ax.text(86, 39.6, '99-rm-serial.rules   ( == is match,   = / += is assign )',
        ha="center", fontsize=7.6, color="#7a4a18", style="italic")
box(59, 26, 54, 11,
    'SUBSYSTEM=="tty",\nATTRS{idVendor}=="1a86",  ATTRS{idProduct}=="7523",\n'
    'MODE="0660",  GROUP="dialout",  SYMLINK+="rm_serial"',
    C_RULE, fs=7.3)
box(66, 14, 40, 8, "/dev/rm_serial  ->  ttyUSB(x)\n(valid only while this match is unique)",
    C_LINK, fs=8.4)

arrow(86, 54, 86, 50.5, C_EVENT, lw=2.0)
arrow(86, 42.5, 86, 37.5, C_EVENT, lw=2.0)
arrow(86, 26, 86, 21.5, C_RULE, lw=2.0)

box(63, 5, 46, 6.5,
    "VID/PID alone cannot distinguish\ntwo devices of the same model.",
    "#f4e3e3", tc=C_BAD, ec=C_BAD, lw=1.2, fs=8.0)

# bridge arrow: the chain feeds the rule match
arrow(44, 49, 58.5, 33, C_USB, lw=1.6, ls=(0, (5, 3)), rad=-0.10)

# Title.
fig.suptitle("Matching a USB serial device through its sysfs parent chain",
             fontsize=12.5, weight="bold", y=0.975)

plt.tight_layout(rect=[0, 0.01, 1, 0.95])
output_path = Path(__file__).resolve().parents[2] / "chapters/4.Application/images/app-serial-udev-chain.png"
plt.savefig(output_path, dpi=150,
            bbox_inches="tight", facecolor="white")
print(f"saved {output_path}")
