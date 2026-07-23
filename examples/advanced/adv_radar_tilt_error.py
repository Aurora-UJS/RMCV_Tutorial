# Radar station: first-order error from applying a flat-ground model to a tilted field.
#
# DERIVED, NOT MEASURED.  The RMUC 2026 manual (sec. 4.1) states the battlefield
# floor is not level: it tilts 1 to 2 degrees toward both long sides along the
# central axis.  A radar that back-projects pixels onto an assumed *horizontal*
# plane therefore intersects the wrong plane.  To first order the horizontal
# position error is
#       e ~= R * dz / h
# with R the ground range, h the radar height above the field and dz the height
# offset of the true ground w.r.t. the assumed horizontal plane.  The field is
# 15 m wide, so the maximum lateral offset from the central axis is 7.5 m and
#       dz = 7.5 * tan(theta).
# Rule thresholds compared against: d < 0.8 m accurate, d >= 1.6 m inaccurate.
#
# Generates chapters/5.Advanced/images/adv-radar-tilt-error.png
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
INK = "#222222"
mpl.rcParams.update({"font.size": 10.5, "axes.linewidth": 0.9})

HALF_WIDTH = 7.5      # m, field is 28 x 15 m -> centre axis to long side
H_NOMINAL = 2.5       # m, radar foundation platform height (manual sec. 4.2.5)
H_HIGH = 4.0          # m, sensitivity check: radar mounted higher than nominal
ACC, INACC = 0.8, 1.6  # m, rule thresholds


def dz(theta_deg):
    return HALF_WIDTH * np.tan(np.radians(theta_deg))


def err(R, theta_deg, h):
    return R * dz(theta_deg) / h


R = np.linspace(4.0, 25.0, 400)
fig, ax = plt.subplots(figsize=(9.4, 5.4), dpi=150)

# sensitivity band: h swept from nominal 2.5 m up to 4 m
for theta, col in ((1.0, BLUE), (2.0, MAGENTA)):
    ax.fill_between(R, err(R, theta, H_HIGH), err(R, theta, H_NOMINAL),
                    color=GRAY, alpha=0.20, lw=0, zorder=1)
    ax.plot(R, err(R, theta, H_NOMINAL), color=col, lw=2.4, zorder=4,
            label=f"tilt {theta:.0f}°  (h = {H_NOMINAL} m)")
    ax.plot(R, err(R, theta, H_HIGH), color=col, lw=1.0, ls=(0, (2, 2)),
            alpha=0.8, zorder=3)

# rule thresholds
for y, txt, col in ((ACC, "0.8 m — 'accurate' limit", INK),
                    (INACC, "1.6 m — 'inaccurate' begins", INK)):
    ax.axhline(y, color=col, lw=1.2, ls=(0, (6, 3)), zorder=2)
    ax.text(24.7, y + 0.045, txt, ha="right", va="bottom", fontsize=9.2,
            color=col, fontweight="bold")

# table anchor points
for theta, col in ((1.0, BLUE), (2.0, MAGENTA)):
    for Rp in (10.0, 15.0, 20.0):
        e = err(Rp, theta, H_NOMINAL)
        ax.plot([Rp], [e], "o", ms=6.0, color=col, mec="white", mew=1.2, zorder=6)
        ax.annotate(f"{e:.2f}", (Rp, e), textcoords="offset points",
                    xytext=(0, 9), ha="center", fontsize=8.8, color=col,
                    fontweight="bold", zorder=6)

# where each curve crosses the 0.8 m accurate line
for theta, col, off, ha in ((1.0, BLUE, (26, -13), "left"),
                            (2.0, MAGENTA, (0, -17), "center")):
    Rc = ACC * H_NOMINAL / dz(theta)
    ax.plot([Rc], [ACC], "v", ms=8, color=col, mec="white", mew=1.0, zorder=7)
    ax.annotate(f"first-order estimate = 0.8 m\nat {Rc:.1f} m", (Rc, ACC),
                textcoords="offset points", xytext=off, ha=ha, va="top",
                fontsize=8.6, color=col, fontweight="bold", linespacing=1.2)

ax.set_xlim(4, 25)
ax.set_ylim(0, 2.9)
ax.set_xlabel("ground range from radar  R  [m]")
ax.set_ylabel("first-order horizontal error estimate  e ≈ R·Δz/h  [m]")
ax.set_title("First-order tilt-error estimate under a simplified vertical-section model\n"
             "comparison with the 0.8 m and 1.6 m rule thresholds; not a field measurement",
             fontsize=11.6, fontweight="bold", color=INK, pad=11)
ax.grid(True, color=GRAY, alpha=0.22, lw=0.7)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)

band = mpl.patches.Patch(facecolor=GRAY, alpha=0.20,
                         label="sensitivity band: h = 2.5 → 4.0 m")
h, l = ax.get_legend_handles_labels()
ax.legend(handles=h + [band], loc="upper left", frameon=False, fontsize=9.4)

fig.text(0.012, 0.008,
         "Δz = 7.5·tan θ (half field width); e ≈ R·Δz/h. First-order estimate, not a bound.\n"
         "Field 28×15 m, tilt 1–2° per RMUC 2026 manual §4.1; h = 2.5 m per §4.2.5.",
         fontsize=7.8, color=GRAY, linespacing=1.25)

fig.tight_layout(rect=(0, 0.060, 1, 1))
fig.savefig("chapters/5.Advanced/images/adv-radar-tilt-error.png", dpi=150)

# ---- numbers quoted in the chapter table -------------------------------------
print("dz(1 deg) = %.4f m   dz(2 deg) = %.4f m" % (dz(1.0), dz(2.0)))
for theta in (1.0, 2.0):
    row = "  ".join("R=%2d: %.2f" % (Rp, err(Rp, theta, H_NOMINAL))
                    for Rp in (10, 15, 20))
    print("tilt %.0f deg, h=2.5 m -> %s" % (theta, row))
print("sensitivity h=4.0 m, tilt 2 deg, R=20 -> %.2f m" % err(20.0, 2.0, H_HIGH))
for theta in (1.0, 2.0):
    print("tilt %.0f deg crosses 0.8 m at R = %.2f m, 1.6 m at R = %.2f m"
          % (theta, ACC * H_NOMINAL / dz(theta), INACC * H_NOMINAL / dz(theta)))
