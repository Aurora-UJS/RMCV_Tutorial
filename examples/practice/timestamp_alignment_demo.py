# Timestamp alignment demo: why a static target grows a "tail" in the odom
# frame when image/IMU timestamps are mismatched, and how an offset scan
# recovers the true offset.
#
# Setup (top view, x forward, y left, camera at gimbal origin):
#   - target static in odom at (4, 0) m;
#   - gimbal yaw sweeps sinusoidally: psi(t) = A sin(2*pi*f*t),
#     A = 40 deg, f = 0.8 Hz -> peak omega = A*2*pi*f = 3.5 rad/s (~200 deg/s);
#   - camera 100 fps; image stamp = exposure time + 6 ms (pipeline delay,
#     the true offset the scan must find);
#   - attitude arrives as a 1 kHz sample buffer, queried by interpolation
#     (same structure as the ring buffer in the chapter);
#   - PnP noise: sigma_depth = 15 mm (sub-pixel width error at 4 m),
#     sigma_lateral = 2.3 mm (1 px at fx = 1739) -- chosen to match the
#     magnitudes derived in the camera-model chapter.
#
# Output: chapters/3.Practice/images/practice-timestamp-alignment.png
import numpy as np
import matplotlib.pyplot as plt

rng = np.random.default_rng(7)

# --- scenario -------------------------------------------------------------
A = np.deg2rad(40.0)          # sweep amplitude [rad]
f = 0.8                       # sweep frequency [Hz]
w0 = 2 * np.pi * f
t_d_true = 0.006              # image stamp lags exposure by 6 ms
T_total = 6.0                 # s of data
fps = 100.0
p_odom = np.array([4.0, 0.0])  # static target, odom frame [m]

yaw = lambda t: A * np.sin(w0 * t)

# --- 1 kHz attitude buffer (what the serial thread would store) -----------
t_imu = np.arange(0.0, T_total + 0.1, 1e-3)
yaw_imu = yaw(t_imu)

def yaw_lookup(t_query):
    """Interpolate attitude from the 1 kHz buffer (scalar yaw -> lerp == slerp)."""
    return np.interp(t_query, t_imu, yaw_imu)

# --- camera frames --------------------------------------------------------
t_exp = np.arange(0.0, T_total, 1.0 / fps)   # true exposure instants
t_stamp = t_exp + t_d_true                   # what the driver writes as stamp
psi_exp = yaw(t_exp)

# measurement in the camera frame: p_C = Rz(psi)^T p_odom + PnP noise
# (camera frame drawn with x forward / y left as well; depth = x axis)
cos, sin = np.cos(psi_exp), np.sin(psi_exp)
p_cam = np.stack([cos * p_odom[0] + sin * p_odom[1],
                  -sin * p_odom[0] + cos * p_odom[1]], axis=1)
sigma_depth, sigma_lat = 0.015, 0.0023       # m, see header
p_cam[:, 0] += rng.normal(0.0, sigma_depth, len(t_exp))
p_cam[:, 1] += rng.normal(0.0, sigma_lat, len(t_exp))

def reconstruct(offset):
    """Rebuild odom-frame target using attitude at (stamp - offset)."""
    psi = yaw_lookup(t_stamp - offset)
    c, s = np.cos(psi), np.sin(psi)
    return np.stack([c * p_cam[:, 0] - s * p_cam[:, 1],
                     s * p_cam[:, 0] + c * p_cam[:, 1]], axis=1)

def rms_spread(pts):
    """RMS distance to the cloud mean (truth-free metric, same as on the car)."""
    d = pts - pts.mean(axis=0)
    return np.sqrt(np.mean(np.sum(d**2, axis=1)))

p_naive = reconstruct(0.0)          # use the stamp as-is
p_aligned = reconstruct(t_d_true)   # offset applied
rms_naive, rms_aligned = rms_spread(p_naive), rms_spread(p_aligned)

# --- offset scan ----------------------------------------------------------
offsets = np.arange(-4.0, 16.01, 0.25) * 1e-3
scan = np.array([rms_spread(reconstruct(d)) for d in offsets])
d_best = offsets[np.argmin(scan)]

print(f"peak omega        : {A * w0:.2f} rad/s")
print(f"RMS naive         : {rms_naive * 100:.1f} cm")
print(f"RMS aligned       : {rms_aligned * 100:.1f} cm")
print(f"scan minimum at   : {d_best * 1000:.2f} ms (true {t_d_true * 1000:.1f} ms)")

# --- figure ---------------------------------------------------------------
C_BAD = "#d1495b"    # misaligned (the misleading view)
C_GOOD = "#1565c0"   # aligned (the truthful view)
HALF_ARMOR = 0.0675  # small armor half-width [m]

fig, (axL, axR) = plt.subplots(1, 2, figsize=(10.5, 4.4),
                               gridspec_kw={"width_ratios": [1.15, 1]})

# Left: both clouds on the same axes, as deviation from the true point [cm]
dev_n = (p_naive - p_odom) * 100
dev_a = (p_aligned - p_odom) * 100
axL.set_title(f"Static target in odom: RMS {rms_naive*100:.1f} cm "
              f"$\\to$ {rms_aligned*100:.1f} cm", fontsize=10.5)
axL.plot(dev_n[:, 1], dev_n[:, 0], ".", color=C_BAD, ms=3, alpha=0.45,
         label=f"offset = 0 (naive), RMS {rms_naive*100:.1f} cm")
axL.plot(dev_a[:, 1], dev_a[:, 0], ".", color=C_GOOD, ms=3, alpha=0.6,
         label=f"offset = 6 ms (aligned), RMS {rms_aligned*100:.1f} cm")
axL.plot(0, 0, "*", color="#222222", ms=14, zorder=5)
axL.annotate("true position", (0, 0), textcoords="offset points",
             xytext=(8, -14), fontsize=9, color="#222222")
th = np.linspace(0, 2 * np.pi, 200)
axL.plot(HALF_ARMOR * 100 * np.cos(th), HALF_ARMOR * 100 * np.sin(th),
         "--", color="#888888", lw=1.2)
axL.annotate("small-armor half-width 6.75 cm", (0, HALF_ARMOR * 100),
             textcoords="offset points", xytext=(0, 5), fontsize=8.5,
             color="#666666", ha="center")
axL.set_xlabel("lateral deviation y [cm]")
axL.set_ylabel("depth deviation x [cm]")
axL.set_aspect("equal")
axL.set_xlim(-12, 12); axL.set_ylim(-9, 9)
axL.grid(alpha=0.25, lw=0.5)
axL.legend(fontsize=8.5, loc="lower left", framealpha=0.9)

# Right: offset scan, the U-curve
axR.set_title(f"Offset scan: minimum at {d_best*1000:.1f} ms "
              f"(true {t_d_true*1000:.0f} ms)", fontsize=10.5)
axR.plot(offsets * 1000, scan * 100, "-", color="#333333", lw=1.8)
axR.axvline(t_d_true * 1000, color=C_GOOD, lw=1.2, ls="--")
axR.plot(d_best * 1000, scan.min() * 100, "o", color=C_GOOD, ms=7)
axR.annotate("PnP noise floor", (offsets[-1] * 1000, rms_aligned * 100),
             textcoords="offset points", xytext=(-92, 6), fontsize=9,
             color="#666666")
axR.axhline(rms_aligned * 100, color="#999999", lw=1.0, ls=":")
axR.annotate("naive (offset = 0)", (0, rms_naive * 100),
             textcoords="offset points", xytext=(8, 2), fontsize=9,
             color=C_BAD)
axR.plot(0, rms_naive * 100, "s", color=C_BAD, ms=6)
axR.set_xlabel("candidate offset [ms]")
axR.set_ylabel("RMS spread [cm]")
axR.grid(alpha=0.25, lw=0.5)

fig.tight_layout()
out = "chapters/3.Practice/images/practice-timestamp-alignment.png"
fig.savefig(out, dpi=150, bbox_inches="tight")
print(f"saved {out}")
