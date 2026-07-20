# Drag magnitude demo for the ballistics chapter (Practice part):
# left  -- aim with the vacuum model, fly in a drag world: miss grows with range;
# right -- extra drop caused by drag vs distance, for 17 mm at three speeds and 42 mm.
# Generates chapters/3.Practice/images/practice-ballistics-drag.png
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
BLUE_L, BLUE_D = "#9DB8E8", "#1E3F7E"          # sequential blues: speed low -> high
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})

g, rho, cd = 9.8, 1.169, 0.47   # rho: 25 C standard-pressure air (official 2026)

def k_of(d_m, m_kg):
    return 0.5 * rho * cd * np.pi * (d_m / 2) ** 2 / m_kg

K17 = k_of(0.0168, 0.0032)     # 17 mm, 3.2 g  -> 0.0190 /m
K42 = k_of(0.0425, 0.0445)     # 42 mm, 44.5 g -> 0.0088 /m
print(f"k17={K17:.5f} /m  k42={K42:.5f} /m  ratio={K42/K17:.3f}")

def vacuum_pitch(v0, d, h):
    """Closed-form low solution of the no-drag pitch equation."""
    disc = v0**4 - g * (g * d * d + 2 * h * v0 * v0)
    return np.arctan((v0**2 - np.sqrt(disc)) / (g * d))

def fly(v0, pitch, k, x_end, dt=1e-4):
    """Full 2D integration: dv/dt = -k|v|v - g e_z (no decoupling)."""
    p = np.zeros(2)
    v = v0 * np.array([np.cos(pitch), np.sin(pitch)])
    traj = [p.copy()]
    while p[0] < x_end and p[1] > -2.0:
        a = -k * np.linalg.norm(v) * v - np.array([0.0, g])
        v = v + a * dt
        p = p + v * dt
        traj.append(p.copy())
    return np.array(traj)

# --- left panel: vacuum aim, drag world (v0 = 25 m/s, target 8 m away, 0.2 m up)
v0, d_t, h_t = 25.0, 8.0, 0.2
pitch = vacuum_pitch(v0, d_t, h_t)
tr_vac = fly(v0, pitch, 0.0, d_t)
tr_drag = fly(v0, pitch, K17, d_t)
z_vac, z_drag = tr_vac[-1, 1], tr_drag[-1, 1]
miss = z_vac - z_drag
print(f"pitch={np.degrees(pitch):.2f} deg, vacuum lands {z_vac:.3f} m, "
      f"drag lands {z_drag:.3f} m, miss={100*miss:.1f} cm")

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(9.6, 4.0), dpi=150)

ax1.plot(tr_vac[:, 0], tr_vac[:, 1], color=GRAY, lw=1.6, ls="--",
         label="no drag (aim model)")
ax1.plot(tr_drag[:, 0], tr_drag[:, 1], color=BLUE, lw=2.4, alpha=0.9,
         label="with drag (real flight)")
ax1.plot([d_t], [h_t], marker="*", ms=14, color=MAGENTA, ls="none",
         label="target", zorder=5)
ax1.plot([d_t, d_t], [z_drag, z_vac], color=MAGENTA, lw=1.4)
ax1.annotate(f"miss {100*miss:.0f} cm", xy=(d_t, (z_vac + z_drag) / 2),
             xytext=(6.35, 0.05), color=MAGENTA,
             arrowprops=dict(arrowstyle="-", color=MAGENTA, lw=0.8))
ax1.set_xlabel("horizontal distance (m)")
ax1.set_ylabel("height (m)")
ax1.set_title(f"Vacuum aim in a drag world\n17 mm, {v0:.0f} m/s, target at 8 m",
              fontsize=11)
ax1.legend(loc="upper left", fontsize=9, frameon=False)
ax1.grid(alpha=0.25, lw=0.5)

# --- right panel: miss vs distance, honest version -- for every distance aim
#     with the vacuum closed form, fly the full drag ODE, record how low it hits
x = np.linspace(0.5, 10, 60)
def miss_curve(v0, k):
    out = []
    for d in x:
        p = vacuum_pitch(v0, d, 0.0)
        out.append((fly(v0, p, 0.0, d)[-1, 1] - fly(v0, p, k, d)[-1, 1]) * 100)
    return np.array(out)

for v, c in [(15, BLUE_L), (20, BLUE), (25, BLUE_D)]:
    y = miss_curve(v, K17)
    ax2.plot(x, y, color=c, lw=2.0)
    ax2.annotate(f"17 mm, {v} m/s", xy=(x[-1], y[-1]),
                 xytext=(-4, {15: 6, 20: -4, 25: -12}[v]),
                 textcoords="offset points", ha="right", color=c, fontsize=9)
y42 = miss_curve(12, K42)
ax2.plot(x, y42, color=MAGENTA, lw=2.0, ls="--")
ax2.annotate("42 mm, 12 m/s", xy=(x[-1], y42[-1]), xytext=(-4, 8),
             textcoords="offset points", ha="right", color=MAGENTA, fontsize=9)
ax2.axhline(6, color=GRAY, lw=1.0, ls=":")
ax2.annotate("half armor height ~6 cm", xy=(0.6, 6), xytext=(0, 4),
             textcoords="offset points", color=GRAY, fontsize=9)

# failure distance = where the miss curve crosses the 6 cm half-armor line
xf = np.linspace(0.5, 12, 400)
def fail_dist(v0, k, thr=6.0):
    m_prev, d_prev = None, None
    for d in xf:
        m = (fly(v0, vacuum_pitch(v0, d, 0.0), 0.0, d)[-1, 1]
             - fly(v0, vacuum_pitch(v0, d, 0.0), k, d)[-1, 1]) * 100
        if m_prev is not None and m_prev < thr <= m:
            return d_prev + (thr - m_prev) * (d - d_prev) / (m - m_prev)
        m_prev, d_prev = m, d
    return None
print("failure distance (miss = 6 cm):")
for v in (25, 20, 15):
    print(f"  17 mm {v} m/s -> {fail_dist(v, K17):.2f} m")
print(f"  42 mm 12 m/s -> {fail_dist(12, K42):.2f} m")
ax2.set_xlabel("target distance (m)")
ax2.set_ylabel("miss below target (cm)")
ax2.set_title("When does drag matter?\nmiss if you aim with the vacuum model", fontsize=11)
ax2.set_ylim(0, 40)
ax2.grid(alpha=0.25, lw=0.5)

fig.tight_layout()
fig.savefig("chapters/3.Practice/images/practice-ballistics-drag.png",
            bbox_inches="tight")
print("saved practice-ballistics-drag.png")
