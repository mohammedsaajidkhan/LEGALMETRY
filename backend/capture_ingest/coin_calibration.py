# ============ PERSON 2 ============
# Hough Circle Transform & mm-per-pixel ratio calculation
import sys
from pathlib import Path

import cv2
import numpy as np

# ---- Tunable parameters -----------------------------------------------
# These almost never work on the first try — adjust based on what the
# annotated output image shows.
KNOWN_COIN_DIAMETER_MM = 27.0  # ₹10 coin

BLUR_KERNEL = (9, 9)
HOUGH_DP = 1.2          # inverse ratio of accumulator resolution
HOUGH_MIN_DIST = 100    # min distance between detected circle centers (px)
HOUGH_PARAM1 = 100      # Canny edge detector upper threshold
HOUGH_PARAM2 = 40       # accumulator threshold — lower finds more circles (more false positives)
HOUGH_MIN_RADIUS = 20   # px — adjust based on your photo resolution
HOUGH_MAX_RADIUS = 300  # px
# -------------------------------------------------------------------------


def detect_circles(image_path: str):
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Could not read image: {image_path}")

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, BLUR_KERNEL, 0)

    circles = cv2.HoughCircles(
        blurred,
        cv2.HOUGH_GRADIENT,
        dp=HOUGH_DP,
        minDist=HOUGH_MIN_DIST,
        param1=HOUGH_PARAM1,
        param2=HOUGH_PARAM2,
        minRadius=HOUGH_MIN_RADIUS,
        maxRadius=HOUGH_MAX_RADIUS,
    )

    return img, circles


def annotate_and_save(img, circles, output_path: str):
    output = img.copy()

    if circles is not None:
        circles = np.round(circles[0, :]).astype("int")
        for i, (x, y, r) in enumerate(circles):
            cv2.circle(output, (x, y), r, (0, 255, 0), 3)
            cv2.circle(output, (x, y), 2, (0, 0, 255), 3)
            cv2.putText(
                output, f"#{i} r={r}px", (x - 40, y - r - 10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2,
            )

    cv2.imwrite(output_path, output)
    return circles


def calculate_mm_per_pixel(radius_px: float) -> float:
    diameter_px = radius_px * 2
    return KNOWN_COIN_DIAMETER_MM / diameter_px

DISTORTION_RATIO_THRESHOLD = 0.85  # below this, flag as too tilted


def check_distortion(img, x: int, y: int, r: int):
    """Fits an ellipse to the coin's actual edge within the detected region
    and returns how close it is to a perfect circle. A ratio near 1.0 means
    the photo was taken close to top-down; a lower ratio means the coin
    (and therefore the whole photo) was captured at too steep an angle for
    reliable mm-per-pixel calibration.
    """
    pad = int(r * 1.3)
    x0, y0 = max(0, x - pad), max(0, y - pad)
    x1, y1 = min(img.shape[1], x + pad), min(img.shape[0], y + pad)
    roi = img[y0:y1, x0:x1]

    gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    edges = cv2.Canny(blurred, 50, 150)

    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None, False

    largest = max(contours, key=cv2.contourArea)
    if len(largest) < 5:
        # fitEllipse needs at least 5 points
        return None, False

    ellipse = cv2.fitEllipse(largest)
    (_, _), (major, minor), _ = ellipse
    if major == 0:
        return None, False

    ratio = min(major, minor) / max(major, minor)
    acceptable = ratio >= DISTORTION_RATIO_THRESHOLD

    return ratio, acceptable

def main():
    if len(sys.argv) < 2:
        print("Usage: python coin_calibration.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    img, circles = detect_circles(image_path)

    output_path = str(Path(image_path).with_stem(Path(image_path).stem + "_annotated"))
    detected = annotate_and_save(img, circles, output_path)

    print(f"\nAnnotated output saved to: {output_path}")

    if detected is None:
        print("No circles detected. Open the annotated image (same as original, "
              "since nothing was drawn) and check lighting/contrast. "
              "Try lowering HOUGH_PARAM2 first.")
        return

    print(f"\nDetected {len(detected)} circle(s):")
    print(f"\nDetected {len(detected)} circle(s):")
    for i, (x, y, r) in enumerate(detected):
        mm_per_px = calculate_mm_per_pixel(r)
        ratio, acceptable = check_distortion(img, x, y, r)

        print(f"  #{i}: center=({x},{y}) radius={r}px -> mm_per_pixel={mm_per_px:.4f}")
        if ratio is not None:
            verdict = "OK" if acceptable else "TOO DISTORTED — recommend retake"
            print(f"       distortion ratio={ratio:.3f} -> {verdict}")
        else:
            print("       distortion ratio: could not determine (edge fit failed)")

    print(f"\nOpen {output_path} and confirm circle #0 (or whichever) is actually "
          f"the coin, not a false positive. If there are multiple circles, "
          f"the real one should look tightly fit around the coin's edge.")

if __name__ == "__main__":
    main()