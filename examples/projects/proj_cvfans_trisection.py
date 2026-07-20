# Two angle estimators with OPPOSITE systematic-error signs.
#
# Data source: the 10-row measured table published in rm.cv.fans'
# engineering log  aimer/auto_aim/README.md:503-514  (entry dated 4月25日).
# Columns: true l_to_zn angle (hand-computed under constant-spin assumption),
# the area-ratio estimator, and the ternary-search ("三分法") estimator that
# at that time minimised the two-armour AREA-RATIO residual.
#
# Nothing here is simulated -- the three columns are transcribed verbatim.
# Everything else on the figure (errors, RMS, the fitted constant offset)
# is computed from those three columns by this script.
#
# The read-it rule: the two error curves cross zero at DIFFERENT angles and
# run with opposite slope, so neither is uniformly better -- but their mean
# has an almost angle-independent bias, i.e. one constant fixes it.
#
# Generates chapters/6.Projects/images/proj-cvfans-trisection.png
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

mpl.rcParams.update({"font.size": 10.5})

BLUE, MAGENTA, GREY = "#3B6FD4", "#D6336C", "#8A8A8A"

# ---- the published table, verbatim -----------------------------------------
true = np.array([25.3, 29.3, 34.9, 40.5, 46.2, 50.5, 56.2, 61.8, 67.5, 71.7])
area = np.array([21.3, 26.0, 32.0, 41.3, 46.0, 52.8, 61.0, 68.0, 73.7, 78.2])
tri = np.array([31.0, 35.0, 41.0, 44.0, 50.0, 52.0, 55.0, 61.0, 65.0, 70.0])

err_area = area - true
err_tri = tri - true
fused = 0.5 * (area + tri)
err_fused = fused - true
bias = err_fused.mean()


def rms(e):
    return float(np.sqrt(np.mean(e**2)))


rms_area, rms_tri = rms(err_area), rms(err_tri)
rms_fused, rms_fused_c = rms(err_fused), rms(err_fused - bias)

# ---- zero crossings of each error curve (linear interp) --------------------
# The area-ratio curve wobbles across zero around 39-46 deg before turning
# decisively positive, so we report the LAST (decisive) crossing for both.
def cross(x, y):
    out = None
    for i in range(len(x) - 1):
        if y[i] * y[i + 1] < 0:
            out = x[i] + (x[i + 1] - x[i]) * (-y[i]) / (y[i + 1] - y[i])
    return out


x0_area = cross(true, err_area)
x0_tri = cross(true, err_tri)

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.6, 4.7))

# ================= panel 1: estimate vs truth ===============================
lim = [20, 82]
ax1.plot(lim, lim, color=GREY, lw=1.0, ls="--", zorder=1)
ax1.text(74, 77.5, "ideal  y = x", color=GREY, fontsize=9,
         rotation=38, ha="center", va="center")

ax1.plot(true, area, "-o", color=MAGENTA, lw=1.8, ms=5.5,
         label="area-ratio method", zorder=3)
ax1.plot(true, tri, "-s", color=BLUE, lw=1.8, ms=5.0,
         label="ternary search (area-ratio cost, Apr-25 version)", zorder=3)

# grey links = the error itself, drawn with its own size and direction
for t, a, s in zip(true, area, tri):
    ax1.plot([t, t], [t, a], color=MAGENTA, lw=0.8, alpha=0.35, zorder=2)
    ax1.plot([t, t], [t, s], color=BLUE, lw=0.8, alpha=0.35, zorder=2)

ax1.set_xlim(lim)
ax1.set_ylim(lim)
ax1.set_aspect("equal")
ax1.set_xlabel("true armour angle  l_to_zn  [deg]")
ax1.set_ylabel("estimated angle  [deg]")
ax1.set_title("Estimate vs truth (10 measured points)", fontsize=11)
ax1.legend(loc="upper left", fontsize=9, framealpha=0.95)
ax1.grid(alpha=0.25, lw=0.6)

# ================= panel 2: signed error ====================================
ax2.axhspan(-8, 0, color=GREY, alpha=0.08, zorder=0)
ax2.axhline(0, color="k", lw=1.0, zorder=2)
ax2.text(24.2, -7.4, "under-estimate", color=GREY, fontsize=8.5,
         ha="left", va="center")

ax2.plot(true, err_area, "-o", color=MAGENTA, lw=2.0, ms=5.5,
         label=f"area-ratio       RMS {rms_area:.2f}°", zorder=4)
ax2.plot(true, err_tri, "-s", color=BLUE, lw=2.0, ms=5.0,
         label=f"ternary search  RMS {rms_tri:.2f}°", zorder=4)
ax2.plot(true, err_fused, "-^", color="#2E7D32", lw=2.6, ms=5.0, alpha=0.85,
         label=f"mean of the two  RMS {rms_fused:.2f}°", zorder=5)
ax2.axhline(bias, color="#2E7D32", lw=1.2, ls=":", zorder=3)
ax2.annotate(f"flat bias {bias:.2f}°\n(residual RMS {rms_fused_c:.2f}°)",
             xy=(33.5, bias), xytext=(25.5, -5.9),
             color="#2E7D32", fontsize=8.8, va="center", ha="left",
             arrowprops=dict(arrowstyle="->", color="#2E7D32", lw=1.0,
                             shrinkA=2, shrinkB=2))

for x0, c in ((x0_area, MAGENTA), (x0_tri, BLUE)):
    if x0 is not None:
        ax2.plot([x0], [0], marker="v", color=c, ms=8, zorder=6, clip_on=False)
        ax2.annotate(f"sign flip {x0:.0f}°", xy=(x0, 0), xytext=(x0, -2.6),
                     color=c, fontsize=8.5, ha="center", va="top",
                     rotation=90)

ax2.set_xlim(23, 79)
ax2.set_ylim(-8, 8)
ax2.set_xlabel("true armour angle  l_to_zn  [deg]")
ax2.set_ylabel("signed error  (estimate − truth)  [deg]")
ax2.set_title("Signed error: opposite slopes, different zero crossings",
              fontsize=11)
ax2.legend(loc="lower right", fontsize=8.8, framealpha=0.95)
ax2.grid(alpha=0.25, lw=0.6)

fig.suptitle(
    "Two angle estimators with mirrored bias: area-ratio reads LOW then HIGH, "
    "ternary search HIGH then LOW\n"
    f"averaging them collapses a ±6° angle-dependent bias into a flat "
    f"{bias:.1f}° offset (RMS {rms_area:.1f}°/{rms_tri:.1f}° → "
    f"{rms_fused_c:.1f}° after removing it)",
    fontsize=11.5, y=1.005)
fig.tight_layout(rect=(0, 0, 1, 0.99))
fig.savefig("chapters/6.Projects/images/proj-cvfans-trisection.png",
            dpi=150, bbox_inches="tight")

print(f"area   RMS {rms_area:.3f}  zero at {x0_area}")
print(f"tri    RMS {rms_tri:.3f}  zero at {x0_tri}")
print(f"fused  RMS {rms_fused:.3f}  bias {bias:.3f}  "
      f"residual {rms_fused_c:.3f}")
print("err_area", np.round(err_area, 2))
print("err_tri ", np.round(err_tri, 2))
