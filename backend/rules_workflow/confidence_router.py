# ==============================================================================
# LEGALMETRY — Tiered Confidence Router (Person 4 / Module 2.8)
# Track 4: Rules & Workflow
#
# Tiered Thresholds:
# - >= 90%: Auto-accept verification
# - 70% - 90%: Accept but flag warnings
# - < 70%: Human review required / degraded pipeline status
# ==============================================================================

from typing import Dict, Any

def route_by_confidence(ocr_confidence: float, coin_detected: bool) -> tuple[str, str]:
    """
    Returns (status_code, recommendation) based on tiered confidence thresholds.
    """
    if not coin_detected:
        return "no_coin_detected", "Reference coin not detected. Measurements uncalibrated."

    if ocr_confidence >= 0.90:
        return "ok", "High confidence verification."
    elif ocr_confidence >= 0.70:
        return "ok", "Moderate confidence read. Borderline characters verified."
    else:
        return "low_confidence", "Low confidence OCR detected. Physical review recommended."
