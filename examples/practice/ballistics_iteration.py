# Solver-convergence demo for the ballistics chapter (Practice part):
# left  -- Newton and bisection on a verified earliest-root bracket; a bisection
#          half-width shows the guaranteed factor-of-two bound for this case;
# right -- the outer fixed point T <-> pitch <-> predicted target position
#          (local geometric contraction in the stated example).
# Generates chapters/3.Practice/images/practice-ballistics-iteration.png
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT = REPO_ROOT / "chapters/3.Practice/images/practice-ballistics-iteration.png"

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})

g, k, v0 = 9.81, 0.01927, 25.0       # illustrative 17 mm parameters

# ---------- left: Newton vs bisection on f(T) = (1/k)ln(1+k vx0 T) - (d + dd T)
d, dd = 8.0, 1.5                      # target 8 m away, receding at 1.5 m/s
vx0 = v0 * np.cos(np.radians(5.0))

def f(T):  return np.log1p(k * vx0 * T) / k - (d + dd * T)
def fp(T): return vx0 / (1 + k * vx0 * T) - dd

# Establish the earliest sign-changing bracket for this example, then use a
# long bisection run as an independent numerical reference for T*.
lo_ref, hi_ref = 0.0, 1.0
T_peak = (vx0 / dd - 1) / (k * vx0)
assert hi_ref <= T_peak and f(lo_ref) < 0 < f(hi_ref)
for _ in range(100):
    mid = (lo_ref + hi_ref) / 2
    if f(mid) < 0:
        lo_ref = mid
    else:
        hi_ref = mid
T_star = (lo_ref + hi_ref) / 2

T = d / vx0                           # vacuum guess as the initial value
newton_T = [T]
for _ in range(8):
    T_next = T - f(T) / fp(T)
    newton_T.append(T_next)
    if abs(T_next - T) < 1e-14:
        break
    T = T_next
newton_err = np.abs(np.array(newton_T) - T_star)
print(f"Newton: T*={T_star:.6f} s, |T-T*| per iter: "
      + ", ".join(f"{e:.1e}" for e in newton_err))

lo, hi = 0.0, 1.0                     # bisection on the same earliest bracket
bisect_bound = []
for _ in range(13):
    bisect_bound.append((hi - lo) / 2)  # guaranteed absolute-error bound
    mid = (lo + hi) / 2
    if f(mid) < 0:
        lo = mid
    else:
        hi = mid

# ---------- right: outer fixed point with a moving target ---------------------
p0 = np.array([8.0, 0.0])             # current horizontal position (odom)
vt = np.array([1.5, 2.5])             # target velocity: receding + strafing
h = 0.2                               # height difference, assumed constant here

theta, T = 0.0, np.linalg.norm(p0) / v0
hist_T, hist_th = [T], [theta]
for _ in range(20):
    pf = p0 + vt * T                              # CV stand-in for the KF predictor
    dist = np.linalg.norm(pf)
    T = np.expm1(k * dist) / (k * v0 * np.cos(theta))        # horizontal step
    theta = np.arcsin((h + 0.5 * g * T * T) / (v0 * T))     # vertical step
    hist_T.append(T); hist_th.append(theta)
hist_T, hist_th = np.array(hist_T), np.array(hist_th)
Tf, thf = hist_T[-1], hist_th[-1]
errT = np.abs(hist_T - Tf)[:8]
errth = np.degrees(np.abs(hist_th - thf))[:8]
print(f"fixed point: T={Tf:.4f} s, pitch={np.degrees(thf):.2f} deg, "
      f"|dT| per round: " + ", ".join(f"{e:.1e}" for e in errT[:5]))
ratios = errT[2:5] / errT[1:4]
print(f"contraction ratio ~ {ratios.mean():.3f}")

# ---------- plot --------------------------------------------------------------
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(9.6, 4.0), dpi=150)

ax1.semilogy(range(len(bisect_bound)), bisect_bound, color=GRAY, lw=1.6, ls="--",
             marker="o", ms=4, label="bisection error bound (x0.5)")
show = np.maximum(newton_err[:5], 1e-16)
ax1.semilogy(range(len(show)), show, color=BLUE, lw=2.2,
             marker="o", ms=5, label="Newton actual error (local quadratic)")
ax1.set_xlabel("iteration")
ax1.set_ylabel("time error or guaranteed bound (s)")
ax1.set_title("Flight-time root in the stated bracket\n"
              "Newton reaches numerical precision in this case", fontsize=11)
ax1.legend(fontsize=9, frameon=False, loc="lower left")
ax1.grid(alpha=0.25, lw=0.5, which="both")

it = np.arange(len(errT))
ax2.semilogy(it[1:], np.maximum(errT[1:], 1e-12), color=BLUE, lw=2.2,
             marker="o", ms=5, label="|T - T*|  (s)")
ax2.semilogy(it[1:], np.maximum(errth[1:], 1e-12), color=MAGENTA, lw=2.0,
             marker="s", ms=5, label="|pitch - pitch*|  (deg)")
ax2.set_xlabel("outer round")
ax2.set_ylabel("absolute error (s or deg; see legend)")
ax2.set_title("Outer loop: T <-> pitch <-> predicted position\n"
              f"this example contracts locally by about x{ratios.mean():.2f} per round",
              fontsize=11)
ax2.legend(fontsize=9, frameon=False, loc="upper right")
ax2.grid(alpha=0.25, lw=0.5, which="both")

fig.tight_layout()
fig.savefig(OUTPUT, bbox_inches="tight")
print(f"saved {OUTPUT.relative_to(REPO_ROOT)}")
