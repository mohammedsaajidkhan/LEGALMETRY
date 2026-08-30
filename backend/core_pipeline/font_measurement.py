# ==============================================================================
# LEGALMETRY — Optical Font Measurement Engine (Person 3 / Module 2.4)
# Track 3: Core Pipeline
#
# Deliberately NOT AI. Plain deterministic geometry:
# Font height in mm = pixel height of characters * coin-calibrated mm_per_pixel ratio.
# Compares measured height against Table I statutory legal minimums.
# ==============================================================================

from typing import Dict, Any, Optional

class FontMeasurementEngine:
    """Calculates real-world optical font dimensions in millimeters."""

    @staticmethod
    def calculate_font_height_mm(
        pixel_height: float,
        mm_per_pixel: float
    ) -> float:
        """
        Converts bounding box character pixel height to physical millimeters.
        """
        if pixel_height <= 0 or mm_per_pixel <= 0:
            return 0.0
        return round(pixel_height * mm_per_pixel, 2)

    @staticmethod
    def get_table_i_minimum(pdp_area_sq_cm: float = 140.0) -> float:
        """
        Returns Table I statutory minimum font height in mm for given PDP area.
        """
        if pdp_area_sq_cm <= 50.0:
            return 1.0
        elif pdp_area_sq_cm <= 100.0:
            return 1.5
        elif pdp_area_sq_cm <= 500.0:
            return 2.0
        elif pdp_area_sq_cm <= 2500.0:
            return 4.0
        else:
            return 6.0

    @classmethod
    def evaluate_measurement(
        cls,
        pixel_height: Optional[float],
        mm_per_pixel: Optional[float],
        pdp_area_sq_cm: Optional[float] = 140.0
    ) -> Dict[str, Any]:
        """
        Performs full geometric measurement audit against Table I.
        """
        pdp = pdp_area_sq_cm or 140.0
        min_required = cls.get_table_i_minimum(pdp)

        if pixel_height is None or mm_per_pixel is None or mm_per_pixel <= 0:
            return {
                "font_height_mm": None,
                "table_i_minimum_mm": min_required,
                "principal_display_area_sq_cm": pdp,
                "is_font_compliant": False,
                "font_deficit_mm": min_required,
                "calibration_status": "uncalibrated"
            }

        measured_mm = cls.calculate_font_height_mm(pixel_height, mm_per_pixel)
        is_pass = measured_mm >= min_required
        deficit = max(0.0, round(min_required - measured_mm, 2))

        return {
            "font_height_mm": measured_mm,
            "table_i_minimum_mm": min_required,
            "principal_display_area_sq_cm": pdp,
            "is_font_compliant": is_pass,
            "font_deficit_mm": deficit,
            "calibration_status": "calibrated"
        }
