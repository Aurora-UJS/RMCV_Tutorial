# Residual aiming error left over by end-to-end LATENCY JITTER, after the mean
# has already been absorbed by the ballistic lead time (Advanced part, field chapter).
#
# DERIVED, NOT MEASURED. The only cited input is the closed-loop end-to-end latency
# distribution 35-110 ms with mean 82 ms (rm.cv.fans, measured by back-filling the
# referee-system shot event onto the frame timestamp). Everything else is geometry:
#   e = omega * r * |t - t0|
# with omega the spin rate of the enemy chassis, r the armor-plate radius (0.25 m),
# and t0 = 82 ms the mean the lead time already compensates.
# Generates chapters/5.Advanced/images/adv-field-jitter-residual.png
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
BLUE_L = "#9DB8E8"
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})

T_LO, T_HI, T_MEAN = 0.035, 0.110, 0.082      # cited distribution, seconds
R_ARMOR = 0.25                                 # armor plate radius from chassis centre, m
HALF_W = 0.0675                                # small armor plate half width, m (135 mm wide)

t = np.linspace(T_LO, T_HI, 400)
cases = [(3.0, BLUE_L, "-"), (7.0, BLUE, "-"), (14.0, MAGENTA, "-")]

fig, ax = plt.subplots(figsize=(9.2, 4.6))

for w, color, ls in cases:
    e = w * R_ARMOR * np.abs(t - T_MEAN) * 100.0      # cm
    ax.plot(t * 1000, e, ls, color=color, lw=2.4, label=f"spin {w:g} rad/s")
    # where does this curve leave the plate?
    crit = HALF_W / (w * R_ARMOR)                     # |dt| at which e == half width
    for sign in (-1, +1):
        tc = T_MEAN + sign * crit
        if T_LO < tc < T_HI:
            ax.plot(tc * 1000, HALF_W * 100, "o", color=color, ms=6,
                    mec="white", mew=1.2, zorder=5)
    print(f"omega={w:4.1f} rad/s  e(35ms)={w*R_ARMOR*abs(T_LO-T_MEAN)*100:5.1f} cm"
          f"  e(110ms)={w*R_ARMOR*abs(T_HI-T_MEAN)*100:5.1f} cm"
          f"  |dt| at half-width = {crit*1000:5.1f} ms")

ax.axhline(HALF_W * 100, color=GRAY, ls="--", lw=1.3)
ax.text(70, HALF_W * 100 + 0.45, "small-armor half width 6.75 cm  →  miss",
        color=GRAY, ha="center", va="bottom", fontsize=10)

ax.axvline(T_MEAN * 1000, color=GRAY, ls=":", lw=1.2)
ax.text(T_MEAN * 1000 + 1.5, 12.6,
        "mean 82 ms\n(absorbed by lead time)", color=GRAY, fontsize=9.5, va="top")

ax.axvspan(T_LO * 1000, T_HI * 1000, color=GRAY, alpha=0.07, zorder=0)
ax.set_xlim(T_LO * 1000, T_HI * 1000)
ax.set_ylim(0, 18)
ax.set_xlabel("actual end-to-end latency of this shot (ms)   —   measured band 35–110 ms")
ax.set_ylabel("residual lateral miss (cm)")
ax.set_title("Compensating the mean leaves the jitter: at 14 rad/s only a 39 ms window still hits\n"
             "derived from e = $\\omega\\,r\\,|t-82\\,\\mathrm{ms}|$, r = 0.25 m  (DERIVED, not measured)",
             fontsize=11.5)
ax.legend(loc="upper center", frameon=False, ncol=3)
ax.grid(alpha=0.25, lw=0.6)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)

fig.tight_layout()
fig.savefig("/home/neomelt/RMCV_Tutorial/chapters/5.Advanced/images/adv-field-jitter-residual.png",
            dpi=150)
print("saved adv-field-jitter-residual.png")
