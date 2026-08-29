# ============================================================================
# LEGALMETRY Hour 3 Entity Resolution & MHI Tests (Person 1 / Person 4)
# ============================================================================

import os
import sys
import unittest
import uuid

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from backend.db.postgres import Base, engine, SessionLocal
from backend.db.models import Manufacturer, Scan, Violation
from backend.rules_workflow.entity_resolution import (
    normalize_manufacturer_name, resolve_or_create_manufacturer
)
from backend.rules_workflow.mhi_calculator import (
    calculate_mhi_score, recalculate_manufacturer_mhi, get_risk_sorted_manufacturers, get_risk_tier
)

class TestEntityResolutionAndMHI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    def test_01_normalize_name(self):
        self.assertEqual(normalize_manufacturer_name("Nestle India Pvt. Ltd."), "nestle india")
        self.assertEqual(normalize_manufacturer_name("Dabur India Limited"), "dabur india")
        self.assertEqual(normalize_manufacturer_name("ITC Limited - Foods Division"), "itc foods division")

    def test_02_entity_resolution_exact_and_fuzzy(self):
        db = SessionLocal()
        try:
            # Generate a completely unique brand name
            prefix = f"ZetaBrand_{uuid.uuid4().hex[:8]}"
            canonical_name = f"{prefix} Industries Limited"

            # 1. Register canonical brand (similarity threshold 0.85 to avoid colliding with previous test runs)
            mfg, is_new, conf = resolve_or_create_manufacturer(
                db, raw_name=canonical_name, state="Karnataka", similarity_threshold=0.85
            )
            self.assertTrue(is_new)
            self.assertEqual(mfg.name, canonical_name)

            # 2. Exact match check
            mfg_exact, is_new2, conf2 = resolve_or_create_manufacturer(
                db, raw_name=canonical_name, similarity_threshold=0.85
            )
            self.assertFalse(is_new2)
            self.assertEqual(mfg_exact.id, mfg.id)
            self.assertEqual(conf2, 1.0)

            # 3. Fuzzy OCR Noise match (slight corruption in suffix/word)
            ocr_noisy_name = f"{prefix} Industres Ltd"
            mfg_fuzzy, is_new3, conf3 = resolve_or_create_manufacturer(
                db, raw_name=ocr_noisy_name, similarity_threshold=0.70
            )
            self.assertFalse(is_new3)
            self.assertEqual(mfg_fuzzy.id, mfg.id)
            self.assertGreaterEqual(conf3, 0.70)

        finally:
            db.close()

    def test_03_mhi_score_formula(self):
        # Clean record: 100
        self.assertEqual(calculate_mhi_score(0, 0, 0), 100.0)
        # 1 Critical (-20): 80
        self.assertEqual(calculate_mhi_score(1, 0, 0), 80.0)
        # 1 Critical (-20), 2 Moderate (-20), 1 Minor (-4): 56.0
        self.assertEqual(calculate_mhi_score(1, 2, 1), 56.0)
        # Extreme penalty bound to 0
        self.assertEqual(calculate_mhi_score(10, 10, 10), 0.0)

    def test_04_mhi_database_recalculation(self):
        db = SessionLocal()
        try:
            uid = uuid.uuid4().hex[:6]
            mfg = Manufacturer(
                name=f"Haldiram Snacks {uid} Pvt Ltd",
                normalized_name=f"haldiram snacks {uid}",
                mhi_score=100.00
            )
            db.add(mfg)
            db.commit()
            db.refresh(mfg)

            # Add Scan 1 with 1 Critical violation (Missing MRP)
            scan1 = Scan(manufacturer_id=mfg.id, category="packaged_food", overall_severity="CRITICAL")
            db.add(scan1)
            db.commit()
            db.refresh(scan1)

            v1 = Violation(scan_id=scan1.id, rule_id="Rule_6_1_e_MRP", rule_description="Missing MRP declaration", severity="CRITICAL")
            db.add(v1)

            # Add Scan 2 with 1 Moderate violation (Font size)
            scan2 = Scan(manufacturer_id=mfg.id, category="packaged_food", overall_severity="MODERATE")
            db.add(scan2)
            db.commit()
            db.refresh(scan2)

            v2 = Violation(scan_id=scan2.id, rule_id="Table_I_Font_Height", rule_description="Font size too small", severity="MODERATE")
            db.add(v2)
            db.commit()

            # Recalculate
            mhi_report = recalculate_manufacturer_mhi(db, mfg.id)
            self.assertIsNotNone(mhi_report)
            # Expected score: 100 - (1*20 + 1*10) = 70.0
            self.assertEqual(mhi_report["mhi_score"], 70.0)
            self.assertEqual(mhi_report["total_scans"], 2)
            self.assertEqual(mhi_report["total_violations"], 2)
            self.assertEqual(mhi_report["risk_tier"], "MEDIUM_RISK")

        finally:
            db.close()

    def test_05_risk_sorted_ranking(self):
        db = SessionLocal()
        try:
            uid = uuid.uuid4().hex[:6]
            # Create high risk entity
            mfg_bad = Manufacturer(name=f"Bad Packer {uid}", normalized_name=f"bad packer {uid}", mhi_score=40.0, total_scans=5)
            # Create good entity
            mfg_good = Manufacturer(name=f"Good Packer {uid}", normalized_name=f"good packer {uid}", mhi_score=95.0, total_scans=10)
            db.add_all([mfg_bad, mfg_good])
            db.commit()

            ranked = get_risk_sorted_manufacturers(db, limit=10, min_scans=1)
            self.assertTrue(len(ranked) >= 2)
            scores = [r["mhi_score"] for r in ranked]
            self.assertEqual(scores, sorted(scores))

        finally:
            db.close()

if __name__ == "__main__":
    unittest.main()