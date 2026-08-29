# ============ PERSON 2 ============
# Post-capture blur and glare quality validation
import sys
import cv2
import numpy as np

# ---- Tunable thresholds -------------------------------------------------
# Tune these against real test photos, not blind.
BLUR_THRESHOLD = 20.0     # Laplacian variance below this = too blurry
GLARE_BRIGHTNESS = 240     # pixel value considered "blown out"
GLARE_AREA_THRESHOLD = 0.03  # fraction of image that's blown out = too much glare
# ---------------------------------------------------------------------------


BLUR_RESIZE_WIDTH = 1000  # normalize all images to this width before scoring
BLUR_CROP_FRACTION = 0.6  # central 60% of the image — avoids background noise


def check_blur(img) -> tuple[float, bool]:
    h, w = img.shape[:2]
    scale = BLUR_RESIZE_WIDTH / w
    resized = cv2.resize(img, (BLUR_RESIZE_WIDTH, int(h * scale)))

    rh, rw = resized.shape[:2]
    crop_w, crop_h = int(rw * BLUR_CROP_FRACTION), int(rh * BLUR_CROP_FRACTION)
    x0, y0 = (rw - crop_w) // 2, (rh - crop_h) // 2
    cropped = resized[y0:y0 + crop_h, x0:x0 + crop_w]

    gray = cv2.cvtColor(cropped, cv2.COLOR_BGR2GRAY)
    variance = cv2.Laplacian(gray, cv2.CV_64F).var()
    is_blurry = variance < BLUR_THRESHOLD
    return variance, is_blurry


def check_glare(img) -> tuple[float, bool]:
    """Returns (blown_out_fraction, has_glare). Flags large blown-out
    highlight regions, which is different from ordinary bright lighting —
    isolated small hotspots (like a coin's shine) shouldn't trip this,
    only broad overexposed patches that would obscure text/declarations."""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blown_out = np.sum(gray >= GLARE_BRIGHTNESS)
    total_pixels = gray.size
    fraction = blown_out / total_pixels
    has_glare = fraction > GLARE_AREA_THRESHOLD
    return fraction, has_glare


def run_quality_gate(image_path: str) -> dict:
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Could not read image: {image_path}")

    blur_score, is_blurry = check_blur(img)
    glare_fraction, has_glare = check_glare(img)

    passed = not is_blurry and not has_glare

    return {
        "passed": passed,
        "blur_score": round(blur_score, 2),
        "is_blurry": is_blurry,
        "glare_fraction": round(glare_fraction, 4),
        "has_glare": has_glare,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: python quality_gate.py <image_path>")
        sys.exit(1)

    result = run_quality_gate(sys.argv[1])

    print(f"\n----- Quality Gate: {sys.argv[1]} -----")
    print(f"Blur score (higher=sharper): {result['blur_score']}  -> {'BLURRY' if result['is_blurry'] else 'OK'}")
    print(f"Glare fraction: {result['glare_fraction']}  -> {'TOO MUCH GLARE' if result['has_glare'] else 'OK'}")
    print(f"Overall: {'PASS' if result['passed'] else 'FAIL - request retake'}")


if __name__ == "__main__":
    main()