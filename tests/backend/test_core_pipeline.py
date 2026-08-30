# ==============================================================================
# Unit Tests for LEGALMETRY Core Pipeline & Measurement Engine
# ==============================================================================

import unittest
from backend.core_pipeline.zone_classifier import ZoneClassifier
from backend.core_pipeline.font_measurement import FontMeasurementEngine
from backend.core_pipeline.category_router import CategoryVerificationRouter

class TestCorePipeline(unittest.TestCase):

    def test_zone_classifier_standard_label(self):
        sample_label = (
            "GOOD DAY BUTTER COOKIES\n"
            "MFG BY: Britannia Industries Ltd, Plot 5, Industrial Area, Bangalore\n"
            "NET WT: 150g\n"
            "MRP Rs. 35.00 (INCL OF ALL TAXES)\n"
            "PKD: 02/2026\n"
            "CONSUMER CARE: care@britannia.co.in, Tel: 18004254444"
        )
        extracted = ZoneClassifier.classify_text(sample_label)

        self.assertIsNotNone(extracted["mrp"])
        self.assertIn("35.00", extracted["mrp"])
        self.assertEqual(extracted["net_quantity"], "150g")
        self.assertIn("Britannia", extracted["manufacturer_name"])
        self.assertEqual(extracted["mfg_date"], "02/2026")
        self.assertIn("care@britannia.co.in", extracted["consumer_care"])

    def test_font_measurement_compliance(self):
        # 140 cm2 PDP area requires minimum 2.0mm font
        result = FontMeasurementEngine.evaluate_measurement(
            pixel_height=26.0,
            mm_per_pixel=0.085, # 26 * 0.085 = 2.21 mm
            pdp_area_sq_cm=140.0
        )
        self.assertTrue(result["is_font_compliant"])
        self.assertGreaterEqual(result["font_height_mm"], 2.0)
        self.assertEqual(result["font_deficit_mm"], 0.0)

    def test_font_measurement_deficit(self):
        # 16 pixels * 0.085 = 1.36 mm (< 2.0 mm required for 140 cm2 PDP)
        result = FontMeasurementEngine.evaluate_measurement(
            pixel_height=16.0,
            mm_per_pixel=0.085,
            pdp_area_sq_cm=140.0
        )
        self.assertFalse(result["is_font_compliant"])
        self.assertAlmostEqual(result["font_deficit_mm"], 0.64, places=2)

    def test_category_router_directives(self):
        directive_oil = CategoryVerificationRouter.get_directive("Edible Oils & Vanaspati")
        self.assertIn("Rule 12 Directive", directive_oil)

        directive_water = CategoryVerificationRouter.get_directive("Packaged Drinking Water & Beverages")
        self.assertIn("Second Schedule Item 12", directive_water)

if __name__ == "__main__":
    unittest.main()
