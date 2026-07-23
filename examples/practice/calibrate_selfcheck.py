# Synthetic self-check for the intrinsic-calibration evaluation code. It uses
# fixed parameters, injects an explicit Gaussian-noise model, and exercises
# OpenCV calibration plus per-view diagnostics without a camera. Passing this
# check does not validate real images, board geometry, or the chosen lens model.
import cv2
import numpy as np

rng = np.random.default_rng(7)

# Fixed synthetic truth copied from the example camera_info.yaml in the chapter.
W, H = 1440, 1080
K_true = np.array([[1807.12121, 0, 711.11997],
                   [0, 1806.46896, 562.49495],
                   [0, 0, 1]])
D_true = np.array([-0.078049, 0.158627, 0.000304, -0.000566, 0.0])

# a 9x6 inner-corner board, 25 mm squares
BW, BH, SQ = 9, 6, 0.025
objp = np.zeros((BW * BH, 3), np.float32)
objp[:, :2] = np.mgrid[0:BW, 0:BH].T.reshape(-1, 2) * SQ

NOISE = 0.15          # px per coordinate in this synthetic noise model
N_VIEWS = 25
BAD_VIEW, BAD_NOISE = 17, 1.5   # one deliberately noisy synthetic view


def random_view():
    """A random rotation vector, distance, and projected board-center target."""
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

flags = cv2.CALIB_FIX_K3            # use the chapter's lower-order example model


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
