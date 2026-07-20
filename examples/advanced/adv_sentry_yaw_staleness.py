#!/usr/bin/env python3
"""Why a stale gimbal yaw wrecks the cmd_vel rotation (sentry decision chapter).

Setting (all numbers read out of SMBU pb2025_sentry_nav reality/nav2_params.yaml):
  controller_frequency : 20.0 Hz   -> one control period = 50 ms
  scan rate (assumed)  : 3 rad/s   <- gimbal yaw rate, NOT the chassis spin param
  velocity_smoother max_velocity[0] : 2.5 m/s
and a doubled scan rate of 6 rad/s. NOTE: init_spin_speed / PublishSpinSpeed are
pb2025_sentry_behavior/behavior_trees/rmul_2025.xml.

Model (derivation, not measurement):
  The node sends R(-psi)*v to the chassis; the chassis re-applies R(psi).
  If the psi used in the transform is stale by dt, the executed world
  velocity is R(delta)*v with delta = omega*dt.
    error vector  e = R(delta)*v - v
    |e| = 2|v| sin(delta/2)
    perpendicular component = |v| sin(delta)
    parallel     component = |v| (cos(delta) - 1)   ~ O(delta^2)
  So to first order the error is purely perpendicular to the intended motion.

Output: chapters/5.Advanced/images/adv-sentry-yaw-staleness.png
"""

import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

BLUE = "#3B6FD4"
MAGENTA = "#D6336C"
GRAY = "#8A8A8A"

V = 2.5          # m/s, velocity_smoother max_velocity[0]
T_CTRL = 0.05    # s, 1 / controller_frequency (20 Hz)
OMEGA_A = 3.0    # rad/s, assumed gimbal scan rate (speed-reference-frame yaw rate)
OMEGA_B = 6.0    # rad/s, same at doubled scan rate


def rot(a):
    return np.array([[np.cos(a), -np.sin(a)], [np.sin(a), np.cos(a)]])


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.normpath(
        os.path.join(here, "..", "..", "chapters", "5.Advanced", "images",
                     "adv-sentry-yaw-staleness.png"))

    delta = OMEGA_A * T_CTRL              # 0.150 rad = 8.6 deg
    v_want = np.array([V, 0.0])
    v_exec = rot(delta) @ v_want
    err = v_exec - v_want
    err_mag = 2 * V * np.sin(delta / 2)
    err_perp = V * np.sin(delta)
    err_para = V * (np.cos(delta) - 1)

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12.4, 5.0))

    # ---------- left: vector picture in the world frame ----------
    ax1.arrow(0, 0, v_want[0], v_want[1], width=0.035, head_width=0.14,
              head_length=0.18, length_includes_head=True, color=BLUE,
              alpha=0.85, zorder=3)
    ax1.arrow(0, 0, v_exec[0], v_exec[1], width=0.020, head_width=0.11,
              head_length=0.16, length_includes_head=True, color=MAGENTA,
              zorder=4)
    ax1.annotate("", xy=(v_exec[0], v_exec[1]), xytext=(v_want[0], v_want[1]),
                 arrowprops=dict(arrowstyle="-|>", color=GRAY, lw=2.0,
                                 shrinkA=0, shrinkB=0), zorder=5)

    arc = np.linspace(0, delta, 60)
    ax1.plot(1.05 * np.cos(arc), 1.05 * np.sin(arc), color=GRAY, lw=1.2)
    ax1.text(1.18, 0.07, r"$\delta = \omega\,\Delta t = 8.6^\circ$",
             color=GRAY, fontsize=10)

    ax1.text(V * 0.52, -0.20, "intended  $v$  (world frame), 2.5 m/s",
             color=BLUE, fontsize=10.5, ha="center")
    ax1.text(v_exec[0] * 0.46, v_exec[1] * 0.46 + 0.16,
             "executed  $R(\\delta)\\,v$", color=MAGENTA, fontsize=10.5,
             rotation=np.degrees(delta), ha="center")
    ax1.plot([v_want[0], v_want[0]], [0, v_exec[1]], color=GRAY, lw=0.8,
             ls=":", zorder=2)
    ax1.text(v_want[0] + 0.10, v_exec[1] * 0.5 - 0.02,
             f"error {err_mag:.2f} m/s\n({err_mag / V * 100:.0f}% of command)\n"
             f"$\\perp$ part {err_perp:.3f}\n$\\parallel$ part {err_para:+.3f}",
             color=GRAY, fontsize=9.5, va="center")

    ax1.set_xlim(-0.25, 3.40)
    ax1.set_ylim(-0.42, 0.92)
    ax1.set_aspect("equal")
    ax1.axhline(0, color="0.85", lw=0.8, zorder=0)
    ax1.axvline(0, color="0.85", lw=0.8, zorder=0)
    ax1.set_xlabel("world x  [m/s]")
    ax1.set_ylabel("world y  [m/s]")
    ax1.set_title("One control period of stale yaw = the whole velocity\n"
                  "rotated by 9$^\\circ$, error almost purely sideways",
                  fontsize=11.5)
    ax1.grid(alpha=0.18)

    # ---------- right: error vs staleness ----------
    dt = np.linspace(0, 0.15, 400)
    for omega, color, ls, tag in ((OMEGA_A, BLUE, "-", r"$\omega$ = 3 rad/s  (scan rate, assumed)"),
                                  (OMEGA_B, MAGENTA, "--", r"$\omega$ = 6 rad/s  (twice as fast)")):
        e = 2 * V * np.sin(omega * dt / 2)
        ax2.plot(dt * 1000, e, color=color, ls=ls, lw=2.4, label=tag)

    ax2.axvline(T_CTRL * 1000, color=GRAY, lw=1.4, ls=":")
    ax2.text(T_CTRL * 1000 + 3, 0.30,
             "one control period\n(20 Hz) = 50 ms", color=GRAY, fontsize=9.5)

    for omega, color in ((OMEGA_A, BLUE), (OMEGA_B, MAGENTA)):
        e = 2 * V * np.sin(omega * T_CTRL / 2)
        ax2.plot([T_CTRL * 1000], [e], "o", color=color, ms=7, zorder=5)
        ax2.annotate(f"{e:.2f} m/s = {e / V * 100:.0f}%",
                     xy=(T_CTRL * 1000, e), xytext=(T_CTRL * 1000 + 8, e + 0.09),
                     color=color, fontsize=10)

    ax2.axhline(0.05 * V, color=GRAY, lw=1.0, ls="-.", alpha=0.8)
    ax2.text(100, 0.05 * V - 0.10, "5% of command", color=GRAY, fontsize=9)

    ax2.set_xlim(0, 150)
    ax2.set_ylim(0, 1.95)
    ax2.set_xlabel("yaw staleness  $\\Delta t$  [ms]")
    ax2.set_ylabel("velocity error  $|R(\\delta)v - v|$  [m/s]")
    ax2.set_title("Error grows with how old the yaw is,\n"
                  "not with how good the controller is", fontsize=11.5)
    ax2.grid(alpha=0.25)
    ax2.legend(loc="upper left", fontsize=9.5, framealpha=0.95)

    fig.suptitle("Stale yaw in the cmd_vel rotation: 50 ms of staleness at a 3 rad/s scan rate "
                 "= 0.37 m/s sideways (15% of command)  [derived, not measured]",
                 fontsize=12.5, y=0.995)
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    fig.savefig(out, dpi=150, bbox_inches="tight")
    print("wrote", out)
    print(f"delta={delta:.4f} rad = {np.degrees(delta):.2f} deg")
    print(f"|e|={err_mag:.4f} m/s  perp={err_perp:.4f}  para={err_para:.4f}  "
          f"ratio={err_mag / V * 100:.2f}%")
    print(f"omega=6.0: |e|={2 * V * np.sin(OMEGA_B * T_CTRL / 2):.4f} m/s "
          f"({2 * V * np.sin(OMEGA_B * T_CTRL / 2) / V * 100:.1f}%)")


if __name__ == "__main__":
    main()
