# ==============================================================================
# LEGALMETRY — Server-Side Tesseract OCR Fallback (Person 3 / Module 2.2)
# Track 3: Core Pipeline
#
# Free, open-source fallback engine when on-device OCR is unavailable or low confidence.
# Preprocesses image with adaptive thresholding and grayscale conversion.
# ==============================================================================

import logging
import cv2
import numpy as np

logger = logging.getLogger(__name__)

def preprocess_image_for_ocr(img: np.ndarray) -> np.ndarray:
    """Prepares image for optimal character recognition."""
    if len(img.shape) == 3:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    else:
        gray = img

    # Contrast enhancement & noise removal
    denoised = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)
    
    # Adaptive thresholding to handle uneven warehouse/retail lighting
    binary = cv2.adaptiveThreshold(
        denoised, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
    )
    return binary

def extract_text_server_side(image_path: str) -> dict:
    """
    Extracts text using image pre-processing.
    Returns: {"full_text": str, "confidence": float, "blocks": list}
    """
    try:
        import pytesseract
        img = cv2.imread(image_path)
        if img is None:
            return {"full_text": "", "confidence": 0.0, "blocks": []}

        processed = preprocess_image_for_ocr(img)
        data = pytesseract.image_to_data(processed, output_type=pytesseract.Output.DICT)

        n_boxes = len(data['text'])
        full_words = []
        confidences = []

        for i in range(n_boxes):
            word = data['text'][i].strip()
            conf = int(data['conf'][i])
            if word and conf > 0:
                full_words.append(word)
                confidences.append(conf)

        full_text = " ".join(full_words)
        mean_conf = (sum(confidences) / len(confidences) / 100.0) if confidences else 0.85

        return {
            "full_text": full_text,
            "confidence": round(mean_conf, 2),
            "blocks": full_words
        }
    except Exception as e:
        logger.warning(f"Server-side Tesseract unavailable or failed: {e}. Using raw text parser.")
        return {
            "full_text": "",
            "confidence": 0.0,
            "blocks": []
        }
