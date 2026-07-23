# Bandwidth budget of a 115200-baud serial link.
# Left: occupancy = frame_size x rate vs the 11520 B/s ceiling (8N1: 10 bits/byte).
# Right: a 48-byte frame occupies the wire for 4.17 ms rather than arriving as a
# point event; at 200 Hz only 0.83 ms of each nominal period remains unoccupied.
# Output: chapters/3.Practice/images/practice-protocol-bandwidth.png
import numpy as np
import matplotlib.pyplot as plt

BYTES_PER_S = 115200 / 10          # 8N1: start + 8 data + stop = 10 bits per byte
TX_SIZE = 48                        # vision -> MCU packet (bytes)
RX_SIZE = 28                        # MCU -> vision packet (bytes)
FRAME_MS = TX_SIZE * 10 / 115200 * 1e3   # 4.17 ms on the wire

C_TX = "#1565c0"   # 48-byte frame (vision -> MCU)
C_RX = "#d1495b"   # 28-byte frame (MCU -> vision)

fig, (axL, axR) = plt.subplots(1, 2, figsize=(10.5, 4.0),
                               gridspec_kw={"width_ratios": [1.15, 1]})

# --- Left: occupancy vs frame rate ---------------------------------------
f = np.linspace(0, 450, 300)
occ_tx = TX_SIZE * f / BYTES_PER_S * 100
occ_rx = RX_SIZE * f / BYTES_PER_S * 100

axL.set_title("115200 baud, 8N1 = 11520 bytes/s per direction", fontsize=10.5)
axL.axhspan(100, 130, color="#9e9e9e", alpha=0.30, lw=0)
axL.axhspan(70, 100, color="#bdbdbd", alpha=0.18, lw=0)
axL.axhline(100, color="#424242", lw=1.2)
axL.text(8, 113, "offered load exceeds the line rate",
         fontsize=8.5, color="#424242")
axL.text(8, 84, "70-100%: inspect burst and scheduling margin",
         fontsize=8.5, color="#757575")

axL.plot(f, occ_tx, color=C_TX, lw=2.2)
axL.plot(f, occ_rx, color=C_RX, lw=2.2)
axL.annotate("48 B frame\n(vision → MCU)", (150, 48 * 150 / BYTES_PER_S * 100),
             textcoords="offset points", xytext=(-82, 2), fontsize=9, color=C_TX)
axL.annotate("28 B frame\n(MCU → vision)", (345, 28 * 345 / BYTES_PER_S * 100),
             textcoords="offset points", xytext=(4, -36), fontsize=9, color=C_RX)

# typical operating points
axL.plot(100, 48 * 100 / BYTES_PER_S * 100, "o", color=C_TX, ms=7,
         mec="white", mew=1.2, zorder=5)
axL.annotate("100 Hz → 41.7%", (100, 41.7), textcoords="offset points",
             xytext=(10, -4), fontsize=9, color=C_TX)
axL.plot(200, 28 * 200 / BYTES_PER_S * 100, "o", color=C_RX, ms=7,
         mec="white", mew=1.2, zorder=5)
axL.annotate("200 Hz → 48.6%", (200, 48.6), textcoords="offset points",
             xytext=(10, -10), fontsize=9, color=C_RX)
# saturation point of the 48 B frame
axL.plot(240, 100, "s", color=C_TX, ms=7, mec="white", mew=1.2, zorder=5)
axL.annotate("saturates at 240 Hz", (240, 100), textcoords="offset points",
             xytext=(12, -18), fontsize=9, color=C_TX)

axL.set_xlim(0, 450); axL.set_ylim(0, 130)
axL.set_xlabel("frame rate [Hz]"); axL.set_ylabel("link occupancy [%]")
axL.grid(alpha=0.25, lw=0.5)

# --- Right: wire timeline of the 48-byte frame ---------------------------
axR.set_title(f"one 48-byte frame = {FRAME_MS:.2f} ms on the wire", fontsize=10.5)
rows = [("100 Hz", 10.0, 1.0), ("200 Hz", 5.0, 0.0)]
for label, period, y in rows:
    t0 = 0.0
    while t0 < 21.5:
        axR.barh(y, min(FRAME_MS, 21.5 - t0), left=t0, height=0.42,
                 color=C_TX, edgecolor="white", lw=0.8)
        t0 += period
    duty = FRAME_MS / period * 100
    axR.text(21.9, y, f"{duty:.0f}% busy", fontsize=9, color="#424242",
             va="center")
# label one frame's duration
axR.annotate("", xy=(FRAME_MS, 1.38), xytext=(0, 1.38),
             arrowprops=dict(arrowstyle="<->", color="#424242", lw=1))
axR.text(FRAME_MS / 2, 1.48, f"{FRAME_MS:.2f} ms", fontsize=8.5,
         color="#424242", ha="center")
axR.set_yticks([1.0, 0.0], [r[0] for r in rows])
axR.set_xlim(0, 25); axR.set_ylim(-0.55, 1.75)
axR.set_xlabel("time [ms]")
axR.set_xticks([0, 5, 10, 15, 20])
axR.grid(axis="x", alpha=0.25, lw=0.5)
for s in ("top", "right", "left"):
    axR.spines[s].set_visible(False)

fig.tight_layout()
fig.savefig("chapters/3.Practice/images/practice-protocol-bandwidth.png", dpi=150)
print("saved practice-protocol-bandwidth.png")
