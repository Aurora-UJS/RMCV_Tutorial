# Radar station: the "Tracking Progress" P recursion of RMUC 2026 (manual sec. 5.6.6).
#
# Top panel  -- VERIFICATION.  The manual spells out one worked example with 15
# explicit numbers.  We implement the recursion literally and check every number.
#
# Bottom panel -- DERIVED (not measured).  Same recursion driven by two error
# processes that share the *same mean accuracy* but differ in temporal structure:
#   (a) scattered : the bad judgements sit one at a time at random positions
#   (b) clustered : the *same number* of bad judgements, grouped into runs of 5
# Both arms are handed an identical error count, so only the arrangement differs.
# Measured quantity: median time to first reach P = 100 (the vulnerability line).
# Result: clustered is *faster*, because x accumulates only along an unbroken
# accurate streak; sum(1..14) = 105, so a clean 14-judgement streak alone clears
# the line (2.8 s at 5 Hz) and that floor dominates everything else.
#
# Recursion (manual Table 5-21), x updated first, then P, then P clamped [0,150]:
#   accurate      : x += 1.0 if previous in {acc, semi} else x = 1.0
#   semi-accurate : x += 0.5 if previous in {acc, semi} else x = 0.5
#   inaccurate    : x -= 0.8 if previous in {inacc, interrupt} else x = -0.8
#   interruption  : 0.5 s cumulative without data counts as one "inaccurate"
#
# Generates chapters/5.Advanced/images/adv-radar-mark-progress.png
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
INK = "#222222"
mpl.rcParams.update({"font.size": 10.5, "axes.linewidth": 0.9})

ACC, SEMI, INACC, INTR = "acc", "semi", "inacc", "intr"
GOOD = (ACC, SEMI)
BAD = (INACC, INTR)


def step(P, x, prev, status):
    """One referee-system update: returns (P, x, status-as-new-prev)."""
    if status == ACC:
        x = x + 1.0 if prev in GOOD else 1.0
    elif status == SEMI:
        x = x + 0.5 if prev in GOOD else 0.5
    else:                                   # inaccurate or data interruption
        x = x - 0.8 if prev in BAD else -0.8
    P = min(150.0, max(0.0, P + x))
    return P, x, status


def run(statuses):
    P, x, prev, out = 0.0, 0.0, None, []
    for s in statuses:
        P, x, prev = step(P, x, prev, s)
        out.append(P)
    return out


def first_reach(statuses, target=100.0):
    """Index (1-based) of the first judgement at which P >= target, else None."""
    P, x, prev = 0.0, 0.0, None
    for k, s in enumerate(statuses):
        P, x, prev = step(P, x, prev, s)
        if P >= target:
            return k + 1
    return None


# ---------------------------------------------------------------- top: manual
seq = [ACC] * 15 + [INACC] * 5 + [INTR] * 2 + [ACC] * 2
times = ([0.2 * (i + 1) for i in range(15)]
         + [3.0 + 0.2 * (i + 1) for i in range(5)]
         + [4.5, 5.0]
         + [5.2, 5.4])
P_hist = run(seq)

# the 15 numbers printed verbatim in the manual, keyed by index in `seq`
MANUAL = {0: 1.0, 1: 3.0, 2: 6.0, 3: 10.0, 4: 15.0, 14: 120.0,
          15: 119.2, 16: 117.6, 17: 115.2, 18: 112.0, 19: 108.0,
          20: 103.2, 21: 97.6, 22: 98.6, 23: 100.6}

fig, (ax0, ax1) = plt.subplots(2, 1, figsize=(9.4, 8.2), dpi=150)

for a, b, lab, fc in [(0.0, 3.0, "5 Hz, 100% accurate", "#EAF0FB"),
                      (3.0, 4.0, "0% accurate", "#FCEAF1"),
                      (4.0, 5.0, "no data\n→ 2 interruptions", "#EDEDED"),
                      (5.0, 5.6, "accurate\nagain", "#EAF0FB")]:
    ax0.axvspan(a, b, color=fc, zorder=0)
    ax0.text((a + b) / 2, 150, lab, ha="center", va="top", fontsize=8.0,
             color=GRAY, fontweight="bold", linespacing=1.2)

ax0.plot([0.0] + times, [0.0] + P_hist, color=BLUE, lw=2.2, zorder=3)
ax0.plot(times, P_hist, "o", ms=4.2, color=BLUE, mec="white", mew=0.8, zorder=4)
ax0.plot([times[i] for i in MANUAL], [MANUAL[i] for i in MANUAL], "x",
         ms=8.5, mew=2.0, color=INK, zorder=6, ls="none",
         label="value printed verbatim in the manual")

for y, lab in ((100.0, "P = 100  vulnerability begins"),
               (120.0, "P = 120  20% vulnerability")):
    ax0.axhline(y, color=MAGENTA, lw=1.0, ls=(0, (5, 3)), zorder=2)
    ax0.text(0.08, y + 1.8, lab, fontsize=8.6, color=MAGENTA, fontweight="bold")

ax0.set_xlim(0, 5.6)
ax0.set_ylim(0, 154)
ax0.set_xlabel("time  [s]")
ax0.set_ylabel("tracking progress  P")
ax0.set_title("Reproducing the manual's worked example — all %d printed values match"
              % len(MANUAL), fontsize=11.4, fontweight="bold", color=INK, pad=9)
ax0.legend(loc="lower right", frameon=False, fontsize=9.2)
ax0.grid(True, axis="y", color=GRAY, alpha=0.22, lw=0.7)
for s in ("top", "right"):
    ax0.spines[s].set_visible(False)

# ------------------------------- bottom: same mean accuracy, different structure
RATE, BURST, TRIALS, HORIZON = 5, 5, 800, 60.0
N = int(RATE * HORIZON)
rng = np.random.default_rng(20260720)


def n_bad_of(a):
    """Both processes get the *identical* number of bad judgements."""
    return int(round(BURST * round(N * (1.0 - a) / BURST)))


def scattered(a):
    """Same error count, positions uniformly permuted (one at a time)."""
    out = np.array([ACC] * N, dtype=object)
    nb = n_bad_of(a)
    if nb:
        out[rng.choice(N, size=nb, replace=False)] = INACC
    return list(out)


def clustered(a):
    """Same error count, but grouped into runs of BURST at random positions."""
    nb = n_bad_of(a)
    nblk = nb // BURST
    ngood = N - nb
    out, cuts = [], np.sort(rng.integers(0, ngood + 1, size=nblk))
    prev = 0
    for c in cuts:
        out.extend([ACC] * (c - prev))
        out.extend([INACC] * BURST)
        prev = c
    out.extend([ACC] * (ngood - prev))
    return out


accs = np.linspace(0.60, 1.00, 17)
t_sc, t_cl, a_sc, a_cl = [], [], [], []
for a in accs:
    ss, cc, ms, mc = [], [], [], []
    for _ in range(TRIALS):
        s = scattered(a)
        c = clustered(a)
        ms.append(np.mean([z == ACC for z in s]))
        mc.append(np.mean([z == ACC for z in c]))
        k = first_reach(s)
        ss.append(k / RATE if k else np.nan)
        k = first_reach(c)
        cc.append(k / RATE if k else np.nan)
    t_sc.append(np.nanmedian(ss))
    t_cl.append(np.nanmedian(cc))
    a_sc.append(np.mean(ms))
    a_cl.append(np.mean(mc))
t_sc, t_cl = np.asarray(t_sc), np.asarray(t_cl)

FLOOR = 14 / RATE       # sum(1..14) = 105 >= 100 -> 14 consecutive judgements
ax1.axhline(FLOOR, color=GRAY, lw=1.2, ls=(0, (5, 3)), zorder=2)
ax1.text(60.4, FLOOR - 0.5,
         "hard floor %.1f s: 14 consecutive accurate judgements\n"
         "already give 1+2+…+14 = 105" % FLOOR,
         ha="left", va="top", fontsize=8.6, color=GRAY, fontweight="bold",
         linespacing=1.25)

ax1.plot(accs * 100, t_sc, color=BLUE, lw=2.4, marker="o", ms=4.5,
         mec="white", mew=0.8, zorder=4,
         label="errors spread one at a time")
ax1.plot(accs * 100, t_cl, color=MAGENTA, lw=2.4, marker="s", ms=4.2,
         mec="white", mew=0.8, zorder=4,
         label="same errors, grouped into runs of %d" % BURST)
ax1.fill_between(accs * 100, t_cl, t_sc, where=t_sc >= t_cl, color=GRAY,
                 alpha=0.18, lw=0, zorder=1)

j = int(np.argmin(np.abs(accs - 0.80)))
ax1.annotate("at 80%%: %.1f s vs %.1f s\nsame error rate, %.1f× the wait"
             % (t_sc[j], t_cl[j], t_sc[j] / t_cl[j]),
             (accs[j] * 100, t_sc[j]), textcoords="offset points",
             xytext=(14, 8), ha="left", fontsize=8.8, color=INK,
             fontweight="bold", linespacing=1.25,
             arrowprops=dict(arrowstyle="-", color=GRAY, lw=0.9))

ax1.set_xlim(59, 101)
ax1.set_ylim(0, max(t_sc) * 1.22)
ax1.set_xlabel("mean fraction of judgements landing in the 'accurate' band  [%]")
ax1.set_ylabel("median time to reach P = 100  [s]")
ax1.set_title("DERIVED, not measured: what P rewards is the longest unbroken streak\n"
              "same error rate, errors merely spread thin → far slower to reach vulnerability",
              fontsize=11.4, fontweight="bold", color=INK, pad=9)
ax1.legend(loc="upper right", frameon=False, fontsize=9.2)
ax1.grid(True, color=GRAY, alpha=0.22, lw=0.7)
for s in ("top", "right"):
    ax1.spines[s].set_visible(False)

fig.subplots_adjust(left=0.085, right=0.985, top=0.925, bottom=0.068, hspace=0.42)
fig.savefig("chapters/5.Advanced/images/adv-radar-mark-progress.png", dpi=150)

# ---- verification printout ---------------------------------------------------
ok = True
for i, want in MANUAL.items():
    got = P_hist[i]
    good = abs(got - want) < 1e-9
    ok &= good
    print("%-2d t=%.1fs  manual=%7.1f  computed=%7.1f  %s"
          % (i, times[i], want, got, "OK" if good else "MISMATCH"))
print("all %d manual values reproduced: %s" % (len(MANUAL), ok))
print("consecutive-accurate sum: 13 -> %d, 14 -> %d" % (13 * 14 // 2, 14 * 15 // 2))
for a in (0.60, 0.70, 0.80, 0.90, 1.00):
    j = int(np.argmin(np.abs(accs - a)))
    print("mean acc %3.0f%% (realised scat %.3f / clus %.3f) -> "
          "scattered %5.2f s, clustered %5.2f s"
          % (accs[j] * 100, a_sc[j], a_cl[j], t_sc[j], t_cl[j]))
