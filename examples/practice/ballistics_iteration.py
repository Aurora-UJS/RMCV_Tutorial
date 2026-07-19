# Solver-convergence demo for the ballistics chapter (Practice part):
# left  -- Newton root-finding on the flight-time equation (quadratic convergence,
#          a bisection reference shows what "merely geometric" looks like);
# right -- the outer fixed point T <-> pitch <-> predicted target position
#          (geometric contraction, ratio ~ target speed / bullet speed).
# Generates chapters/3.Practice/images/practice-ballistics-iteration.png
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})

g, k, v0 = 9.8, 0.01867, 25.0        # 17 mm, 3.5 g, cd 0.47

# ---------- left: Newton vs bisection on f(T) = (1/k)ln(1+k vx0 T) - (d + dd T)
d, dd = 8.0, 1.5                      # target 8 m away, receding at 1.5 m/s
vx0 = v0 * np.cos(np.radians(5.0))

def f(T):  return np.log(1 + k * vx0 * T) / k - (d + dd * T)
def fp(T): return vx0 / (1 + k * vx0 * T) - dd

T = d / vx0                           # vacuum guess as the initial value
newton = [abs(f(T))]
for _ in range(8):
    T = T - f(T) / fp(T)
    newton.append(abs(f(T)))
    if newton[-1] < 1e-15:
        break
T_star = T
print(f"Newton: T*={T_star:.6f} s, |f| per iter: "
      + ", ".join(f"{e:.1e}" for e in newton))

lo, hi = 0.0, 1.0                     # bisection reference on the same equation
bisect = []
for _ in range(len(newton) + 4):
    mid = (lo + hi) / 2
    bisect.append(abs(f(mid)))
    if f(mid) < 0: lo = mid
    else:          hi = mid

# ---------- right: outer fixed point with a moving target ---------------------
p0 = np.array([8.0, 0.0])             # current horizontal position (odom)
vt = np.array([1.5, 2.5])             # target velocity: receding + strafing
h = 0.2                               # height difference, assumed constant here

theta, T = 0.0, np.linalg.norm(p0) / v0
hist_T, hist_th = [T], [theta]
for _ in range(20):
    pf = p0 + vt * T                              # CV stand-in for the KF predictor
    dist = np.linalg.norm(pf)
    T = (np.exp(k * dist) - 1) / (k * v0 * np.cos(theta))   # horizontal step
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

ax1.semilogy(range(len(bisect)), bisect, color=GRAY, lw=1.6, ls="--",
             marker="o", ms=4, label="bisection (x0.5 per step)")
show = newton[:4]                     # stop at machine precision, hide fp noise
ax1.semilogy(range(len(show)), show, color=BLUE, lw=2.2,
             marker="o", ms=5, label="Newton (quadratic)")
ax1.set_xlabel("iteration")
ax1.set_ylabel("|f(T)|  (m)")
ax1.set_title("Solving flight time: Newton, not gradient descent\n"
              "tangent jumps hit machine precision in 3 steps", fontsize=11)
ax1.legend(fontsize=9, frameon=False, loc="lower left")
ax1.grid(alpha=0.25, lw=0.5, which="both")

it = np.arange(len(errT))
ax2.semilogy(it[1:], np.maximum(errT[1:], 1e-12), color=BLUE, lw=2.2,
             marker="o", ms=5, label="|T - T*|  (s)")
ax2.semilogy(it[1:], np.maximum(errth[1:], 1e-12), color=MAGENTA, lw=2.0,
             marker="s", ms=5, label="|pitch - pitch*|  (deg)")
ax2.set_xlabel("outer round")
ax2.set_title("Outer loop: T <-> pitch <-> predicted position\n"
              f"geometric, x{ratios.mean():.2f} per round -> 3 rounds suffice",
              fontsize=11)
ax2.legend(fontsize=9, frameon=False, loc="upper right")
ax2.grid(alpha=0.25, lw=0.5, which="both")

fig.tight_layout()
fig.savefig("chapters/3.Practice/images/practice-ballistics-iteration.png",
            bbox_inches="tight")
print("saved practice-ballistics-iteration.png")
