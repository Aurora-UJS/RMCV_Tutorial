# Pinhole camera model: similar triangles Y/Z = y/f.
# Generates chapters/2.Theory/images/theory-camera-pinhole.png
import matplotlib.pyplot as plt
import matplotlib as mpl

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})

f = 1.6          # focal length (drawing units)
Z, Y = 5.2, 1.8  # object point distance / height
y = f * Y / Z    # image height on the virtual (front) plane

fig, ax = plt.subplots(figsize=(9, 4.2), dpi=150)

# optical axis
ax.axhline(0, color=GRAY, lw=0.8, ls=(0, (6, 4)))
ax.annotate("optical axis", (5.35, 0.06), color=GRAY, fontsize=9)

# optical center
ax.plot(0, 0, "o", color="black", ms=6, zorder=5)
ax.annotate("O (optical center)", (-0.08, -0.34), ha="right", fontsize=10)

# real image plane (behind O, inverted image) -- drawn faint
ax.plot([-f, -f], [-1.1, 1.1], color=GRAY, lw=1.2, ls=":")
ax.plot([-f], [-y], "o", color=GRAY, ms=5)
ax.plot([Y and -f, 0], [-y, 0], color=GRAY, lw=1.0, ls=":")
ax.annotate("real image plane\n(inverted)", (-f, 1.2), ha="center", color=GRAY, fontsize=9)
ax.annotate("$-y$", (-f - 0.12, -y - 0.05), ha="right", color=GRAY, fontsize=10)

# virtual image plane at +f (the one everybody computes with)
ax.plot([f, f], [-1.1, 2.0], color=BLUE, lw=1.6)
ax.annotate("virtual image plane\n(upright, at $z=f$)", (f, 2.08), ha="center", color=BLUE, fontsize=9)

# object point and the ray through O
ax.plot([Z], [Y], "o", color=MAGENTA, ms=7, zorder=5)
ax.annotate("P = (Y, Z)", (Z + 0.12, Y + 0.02), color=MAGENTA, fontsize=11)
ax.plot([Z, -f], [Y, -y], color=MAGENTA, lw=1.4)  # full ray P -> O -> real plane
ax.plot([f], [y], "o", color=BLUE, ms=6, zorder=5)
ax.annotate("p = (y, f)", (f + 0.14, y + 0.14), color=BLUE, fontsize=11)

# similar triangles: drop the two verticals
ax.plot([Z, Z], [0, Y], color=MAGENTA, lw=1.0, ls="--")
ax.plot([f, f], [0, y], color=BLUE, lw=2.6, solid_capstyle="butt")
ax.fill([0, Z, Z], [0, 0, Y], color=MAGENTA, alpha=0.06, lw=0)
ax.fill([0, f, f], [0, 0, y], color=BLUE, alpha=0.12, lw=0)

# dimension labels
ax.annotate("", xy=(Z, -0.55), xytext=(0, -0.55),
            arrowprops=dict(arrowstyle="<->", color="black", lw=0.8))
ax.annotate("$Z$", (Z / 2, -0.78), ha="center", fontsize=12)
ax.annotate("", xy=(f, -0.25), xytext=(0, -0.25),
            arrowprops=dict(arrowstyle="<->", color="black", lw=0.8))
ax.annotate("$f$", (f / 2, -0.48), ha="center", fontsize=12)
ax.annotate("$Y$", (Z + 0.14, Y / 2), fontsize=12, color=MAGENTA)
ax.annotate("$y$", (f - 0.28, y / 2 + 0.03), fontsize=12, color=BLUE)

# the law itself
ax.annotate(r"$\dfrac{y}{f} = \dfrac{Y}{Z}\;\;\Rightarrow\;\; y = f\,\dfrac{Y}{Z}$",
            (3.4, 1.05), fontsize=14,
            bbox=dict(boxstyle="round,pad=0.45", fc="white", ec=GRAY, lw=0.8))

ax.set_xlim(-2.4, 6.6)
ax.set_ylim(-1.35, 2.65)
ax.set_aspect("equal")
ax.axis("off")
fig.tight_layout()
fig.savefig("/home/neomelt/RMCV_Tutorial/chapters/2.Theory/images/theory-camera-pinhole.png",
            dpi=150, bbox_inches="tight", facecolor="white")
print("saved theory-camera-pinhole.png")
