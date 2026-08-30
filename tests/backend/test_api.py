# ==============================================================================
# LEGALMETRY — Backend API Gateway Integration Tests
# ==============================================================================

import unittest
from backend.core_pipeline.zone_classifier import ZoneClassifier
from backend.core_pipeline.font_measurement import FontMeasurementEngine
from backend.rules_workflow.rule_engine import evaluate_compliance

class TestApiIntegration(unittest.TestCase):

    def test_full_pipeline_resolution(self):
        raw_text = (
            "GOOD DAY BUTTER COOKIES\n"
            "MFG BY: Britannia Industries Ltd, Plot 5, Bangalore 560001\n"
            "NET WT: 150g\n"
            "MRP Rs. 35.00 (INCL OF ALL TAXES)\n"
            "PKD: 02/2026\n"
            "CONSUMER CARE: care@britannia.co.in"
        )
        fields = ZoneClassifier.classify_text(raw_text)
        measurements = FontMeasurementEngine.evaluate_measurement(25.0, 0.085, 140.0)
        compliance = evaluate_compliance(fields, measurements)

        self.assertEqual(len(compliance["violations"]), 0)
        self.assertTrue(compliance["is_font_compliant"])

if __name__ == "__main__":
    unittest.main()
