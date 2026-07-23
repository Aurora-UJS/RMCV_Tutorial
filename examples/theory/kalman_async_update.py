# Asynchronous-update CV Kalman filter demo for the target-tracking section:
# predict at 1 kHz, measure at 100 Hz, with a 0.6 s measurement dropout.
# Generates chapters/2.Theory/images/theory-kalman-async-update.png
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})
rng = np.random.default_rng(7)

# --- scenario: a strafing target seen by a 100 Hz detector ---------------
T, dt = 3.0, 0.001                    # 3 s, 1 kHz prediction clock
t = np.arange(0.0, T, dt)
x_true = 0.8 * np.sin(1.2 * t)        # lateral position, |a| <= 1.16 m/s^2
v_true = 0.8 * 1.2 * np.cos(1.2 * t)

meas_every = 10                       # camera: every 10 ms (100 Hz)
sigma_z = 0.02                        # 2 cm measurement noise
drop = (t >= 1.2) & (t < 1.8)         # occlusion: no measurements

# --- CV Kalman filter -----------------------------------------------------
# Process noise: continuous-time white acceleration with PSD q, discretized
# exactly (Q = q [[dt^3/3, dt^2/2], [dt^2/2, dt]]).  This keeps the injected
# uncertainty independent of the prediction step size, so predicting in
# 1 ms steps stays consistent.
q = 0.35                              # (m/s^2)^2 * s, maneuver strength
H = np.array([[1.0, 0.0]])
R = np.array([[sigma_z**2]])
x = np.array([x_true[0], 0.0])        # deliberately wrong initial velocity
P = np.diag([0.05**2, 1.0**2])

est, sig = [], []
meas_t, meas_z = [], []
F = np.array([[1.0, dt], [0.0, 1.0]])
Q = q * np.array([[dt**3 / 3, dt**2 / 2], [dt**2 / 2, dt]])
for k in range(len(t)):
    if k > 0:                                     # predict every 1 ms
        x = F @ x
        P = F @ P @ F.T + Q
    if k > 0 and k % meas_every == 0 and not drop[k]:
        z = x_true[k] + rng.normal(0.0, sigma_z)  # full update on measurement
        S = H @ P @ H.T + R
        K = np.linalg.solve(S.T, (P @ H.T).T).T
        x = x + (K @ (np.array([z]) - H @ x)).ravel()
        I_KH = np.eye(2) - K @ H
        P = I_KH @ P @ I_KH.T + K @ R @ K.T
        P = 0.5 * (P + P.T)
        meas_t.append(t[k])
        meas_z.append(z)
    est.append(x.copy()); sig.append(np.sqrt(np.diag(P)))
est, sig = np.array(est), np.array(sig)

drift = np.abs(est[drop, 0] - x_true[drop]).max()
sig_end = 3 * sig[drop, 0].max()
print(f"max |error| during dropout: {100*drift:.1f} cm, "
      f"3-sigma grows to {100*sig_end:.1f} cm")

# --- plot -----------------------------------------------------------------
fig, (ax1, ax2) = plt.subplots(
    2, 1, sharex=True, figsize=(9, 5.6), dpi=150,
    gridspec_kw={"height_ratios": [2.0, 1.2]})

for ax in (ax1, ax2):
    ax.axvspan(1.2, 1.8, color=GRAY, alpha=0.18, lw=0)
ax1.set_title(f"Predict-only through a 0.6 s dropout: drift reaches "
              f"{100*drift:.0f} cm, 3$\\sigma$ band opens to "
              f"{100*sig_end:.0f} cm; measurement updates then resume",
              fontsize=11.5)

ax1.fill_between(t, est[:, 0] - 3 * sig[:, 0], est[:, 0] + 3 * sig[:, 0],
                 color=BLUE, alpha=0.15, lw=0, label="$\\pm 3\\sigma$")
ax1.plot(t, est[:, 0], color=BLUE, lw=2.6, alpha=0.75, label="KF estimate")
ax1.plot(t, x_true, color="black", lw=1.0, label="truth")
ax1.plot(meas_t, meas_z, ".", color=GRAY, ms=3.5, label="measurements (100 Hz)")
ax1.annotate("measurement dropout", (1.5, 0.93), ha="center",
             color="#555555", fontsize=10)
ax1.set_ylabel("position (m)")
ax1.set_ylim(-1.0, 1.1)
ax1.legend(loc="lower left", fontsize=9, ncol=2, framealpha=0.9)

ax2.plot(t, est[:, 1], color=BLUE, lw=2.6, alpha=0.75, label="KF estimate")
ax2.plot(t, v_true, color="black", lw=1.0, label="truth")
ax2.annotate("velocity is never measured --\ninferred from positions",
             (0.35, -0.85), color="#555555", fontsize=9)
ax2.set_ylabel("velocity (m/s)")
ax2.set_xlabel("time (s)")
ax2.set_ylim(-1.4, 1.5)
ax2.legend(loc="upper right", fontsize=9, framealpha=0.9)

fig.tight_layout()
output = (Path(__file__).resolve().parents[2]
          / "chapters/2.Theory/images/theory-kalman-async-update.png")
fig.savefig(output, bbox_inches="tight")
print("saved theory-kalman-async-update.png")
