# Self-check for the whole intrinsic-calibration evaluation loop, no camera
# needed: synthesize corner observations from KNOWN parameters (the community
# camera_info.yaml: 1440x1080, fx~1807, plumb_bob), add realistic corner noise,
# run cv2.calibrateCamera, and confirm that
#   (1) RMS ~= the corner noise you injected,
#   (2) the recovered fx lands on the truth,
#   (3) per-view errors single out a deliberately ruined view.
# If your evaluation script passes this, you can trust what it says about
# real photos.
import cv2
import numpy as np

rng = np.random.default_rng(7)

# ground truth: the real community calibration file
W, H = 1440, 1080
K_true = np.array([[1807.12121, 0, 711.11997],
                   [0, 1806.46896, 562.49495],
                   [0, 0, 1]])
D_true = np.array([-0.078049, 0.158627, 0.000304, -0.000566, 0.0])

# a 9x6 inner-corner board, 25 mm squares
BW, BH, SQ = 9, 6, 0.025
objp = np.zeros((BW * BH, 3), np.float32)
objp[:, :2] = np.mgrid[0:BW, 0:BH].T.reshape(-1, 2) * SQ

NOISE = 0.15          # px, realistic sub-pixel corner detector noise
N_VIEWS = 25
BAD_VIEW, BAD_NOISE = 17, 1.5   # one deliberately ruined view (motion blur)


def random_view():
    """A board pose: tilted 15-40 deg, 0.5-0.9 m away, spread over the frame."""
    axis = rng.normal(size=3)
    axis /= np.linalg.norm(axis)
    rvec = axis * np.deg2rad(rng.uniform(15, 40))
    z = rng.uniform(0.5, 0.9)
    u, v = rng.uniform(0.15, 0.85) * W, rng.uniform(0.15, 0.85) * H
    center = np.array([(u - K_true[0, 2]) * z / K_true[0, 0],
                       (v - K_true[1, 2]) * z / K_true[1, 1], z])
    tvec = center - cv2.Rodrigues(rvec)[0] @ objp.mean(axis=0)
    return rvec, tvec


obj_pts, img_pts = [], []
while len(img_pts) < N_VIEWS:
    rvec, tvec = random_view()
    proj, _ = cv2.projectPoints(objp, rvec, tvec, K_true, D_true)
    proj = proj.reshape(-1, 2)
    if proj.min() < 10 or proj[:, 0].max() > W - 10 or proj[:, 1].max() > H - 10:
        continue                      # board partly out of frame: retake
    sigma = BAD_NOISE if len(img_pts) == BAD_VIEW else NOISE
    obj_pts.append(objp)
    img_pts.append((proj + rng.normal(0, sigma, proj.shape)).astype(np.float32))

flags = cv2.CALIB_FIX_K3            # narrow FOV: k1 k2 p1 p2 only


def run(op, ip, tag):
    rms, K, D, *_, per_view = cv2.calibrateCameraExtended(
        op, ip, (W, H), None, None, flags=flags)
    per_view = per_view.ravel()
    print(f"[{tag}] RMS = {rms:.3f} px | fx = {K[0, 0]:.1f} (truth 1807.1)")
    print(f"    worst view: #{per_view.argmax()} at {per_view.max():.2f} px")
    return per_view


per_view = run(obj_pts, img_pts, "all 25 views")
keep = [i for i in range(N_VIEWS) if i != per_view.argmax()]
run([obj_pts[i] for i in keep], [img_pts[i] for i in keep],
    "bad view removed")
