# Drag magnitude demo for the ballistics chapter (Practice part):
# left  -- aim with the vacuum model, then integrate the quadratic-drag ODE;
# right -- vertical difference between those two models versus distance.
# Generates chapters/3.Practice/images/practice-ballistics-drag.png
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT = REPO_ROOT / "chapters/3.Practice/images/practice-ballistics-drag.png"

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
BLUE_L, BLUE_D = "#9DB8E8", "#1E3F7E"          # sequential blues: speed low -> high
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})

g, rho, cd = 9.81, 1.184, 0.47  # illustrative: dry air near 25 C at 101.3 kPa

def k_of(d_m, m_kg):
    return 0.5 * rho * cd * np.pi * (d_m / 2) ** 2 / m_kg

K17 = k_of(0.0168, 0.0032)     # 17 mm, 3.2 g  -> 0.0193 /m
K42 = k_of(0.0425, 0.0445)     # 42 mm, 44.5 g -> 0.0089 /m
print(f"k17={K17:.5f} /m  k42={K42:.5f} /m  ratio={K42/K17:.3f}")

def vacuum_pitch(v0, d, h):
    """Closed-form low solution of the no-drag pitch equation."""
    disc = v0**4 - g * (g * d * d + 2 * h * v0 * v0)
    return np.arctan((v0**2 - np.sqrt(disc)) / (g * d))

def fly(v0, pitch, k, x_end, dt=1e-4):
    """Integrate dv/dt = -k|v|v - g e_z and interpolate at x_end."""
    p = np.zeros(2)
    v = v0 * np.array([np.cos(pitch), np.sin(pitch)])
    traj = [p.copy()]
    times = [0.0]
    while p[0] < x_end and p[1] > -2.0:
        p_prev = p.copy()
        t_prev = times[-1]
        a = -k * np.linalg.norm(v) * v - np.array([0.0, g])
        v = v + a * dt
        p = p + v * dt
        if p[0] >= x_end:
            alpha = (x_end - p_prev[0]) / (p[0] - p_prev[0])
            p = p_prev + alpha * (p - p_prev)
            traj.append(p.copy())
            times.append(t_prev + alpha * dt)
            break
        traj.append(p.copy())
        times.append(t_prev + dt)
    if traj[-1][0] < x_end:
        raise RuntimeError(f"projectile did not reach x={x_end:.3f} m")
    return np.array(traj), np.array(times)

# --- left panel: vacuum aim, drag world (v0 = 25 m/s, target 8 m away, 0.2 m up)
v0, d_t, h_t = 25.0, 8.0, 0.2
pitch = vacuum_pitch(v0, d_t, h_t)
tr_vac, t_vac = fly(v0, pitch, 0.0, d_t)
tr_drag, t_drag = fly(v0, pitch, K17, d_t)
tr_drag_fine, t_drag_fine = fly(v0, pitch, K17, d_t, dt=5e-5)
z_vac, z_drag = tr_vac[-1, 1], tr_drag[-1, 1]
difference = z_vac - z_drag
print(f"pitch={np.degrees(pitch):.2f} deg, vacuum lands {z_vac:.3f} m, "
      f"drag lands {z_drag:.3f} m, difference={100*difference:.1f} cm")
print(f"flight time: vacuum={t_vac[-1]*1000:.1f} ms, "
      f"drag={t_drag[-1]*1000:.1f} ms, extra={(t_drag[-1]-t_vac[-1])*1000:.1f} ms")
print(f"halve dt check: delta_height={abs(tr_drag_fine[-1, 1]-z_drag)*100:.4f} cm, "
      f"delta_time={abs(t_drag_fine[-1]-t_drag[-1])*1000:.4f} ms")

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(9.6, 4.0), dpi=150)

ax1.plot(tr_vac[:, 0], tr_vac[:, 1], color=GRAY, lw=1.6, ls="--",
         label="no drag (aim model)")
ax1.plot(tr_drag[:, 0], tr_drag[:, 1], color=BLUE, lw=2.4, alpha=0.9,
         label="quadratic-drag ODE (simulation)")
ax1.plot([d_t], [h_t], marker="*", ms=14, color=MAGENTA, ls="none",
         label="target", zorder=5)
ax1.plot([d_t, d_t], [z_drag, z_vac], color=MAGENTA, lw=1.4)
ax1.annotate(f"difference {100*difference:.1f} cm", xy=(d_t, (z_vac + z_drag) / 2),
             xytext=(6.35, 0.05), color=MAGENTA,
             arrowprops=dict(arrowstyle="-", color=MAGENTA, lw=0.8))
ax1.set_xlabel("horizontal distance (m)")
ax1.set_ylabel("height (m)")
ax1.set_title(f"Vacuum aim in a drag world\n17 mm, {v0:.0f} m/s, target at 8 m",
              fontsize=11)
ax1.legend(loc="upper left", fontsize=9, frameon=False)
ax1.grid(alpha=0.25, lw=0.5)

# --- right panel: for every distance, aim with the vacuum closed form and
#     integrate the full drag ODE; the result is a model difference, not a hit test
x = np.linspace(0.5, 10, 60)
def vertical_difference(v0, k, distance, height=0.0):
    pitch = vacuum_pitch(v0, distance, height)
    tr0, _ = fly(v0, pitch, 0.0, distance)
    trk, _ = fly(v0, pitch, k, distance)
    return (tr0[-1, 1] - trk[-1, 1]) * 100

def difference_curve(v0, k):
    return np.array([vertical_difference(v0, k, d) for d in x])

print("selected vertical differences (cm):")
for speed, distance in [(25, 3), (25, 5), (25, 8), (15, 8)]:
    print(f"  17 mm {speed} m/s at {distance} m -> "
          f"{vertical_difference(speed, K17, distance):.2f}")

for v, c in [(15, BLUE_L), (20, BLUE), (25, BLUE_D)]:
    y = difference_curve(v, K17)
    ax2.plot(x, y, color=c, lw=2.0)
    ax2.annotate(f"17 mm, {v} m/s", xy=(x[-1], y[-1]),
                 xytext=(-4, {15: 6, 20: -4, 25: -12}[v]),
                 textcoords="offset points", ha="right", color=c, fontsize=9)
y42 = difference_curve(12, K42)
ax2.plot(x, y42, color=MAGENTA, lw=2.0, ls="--")
ax2.annotate("42 mm, 12 m/s", xy=(x[-1], y42[-1]), xytext=(-4, 8),
             textcoords="offset points", ha="right", color=MAGENTA, fontsize=9)
EXAMPLE_BUDGET_CM = 6.0
ax2.axhline(EXAMPLE_BUDGET_CM, color=GRAY, lw=1.0, ls=":")
ax2.annotate("example vertical-error budget: 6 cm", xy=(0.6, EXAMPLE_BUDGET_CM),
             xytext=(0, 4),
             textcoords="offset points", color=GRAY, fontsize=9)

# Report where this simulated model difference crosses the example budget.
xf = np.linspace(0.5, 12, 400)
def budget_crossing(v0, k, threshold=EXAMPLE_BUDGET_CM):
    m_prev, d_prev = None, None
    for d in xf:
        m = vertical_difference(v0, k, d)
        if m_prev is not None and m_prev < threshold <= m:
            return d_prev + (threshold - m_prev) * (d - d_prev) / (m - m_prev)
        m_prev, d_prev = m, d
    return None
print(f"distance where model difference reaches {EXAMPLE_BUDGET_CM:.0f} cm:")
for v in (25, 20, 15):
    print(f"  17 mm {v} m/s -> {budget_crossing(v, K17):.2f} m")
print(f"  42 mm 12 m/s -> {budget_crossing(12, K42):.2f} m")
ax2.set_xlabel("target distance (m)")
ax2.set_ylabel("vertical model difference (cm)")
ax2.set_title("Vacuum aim at muzzle height, evaluated with the drag ODE\n"
              "difference grows with distance", fontsize=11)
ax2.set_ylim(0, 40)
ax2.grid(alpha=0.25, lw=0.5)

fig.tight_layout()
fig.savefig(OUTPUT, bbox_inches="tight")
print(f"saved {OUTPUT.relative_to(REPO_ROOT)}")
