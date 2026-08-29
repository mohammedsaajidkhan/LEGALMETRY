# ============================================================================
# LEGALMETRY Hour 1 Infrastructure Tests (Person 1 - Data/Infra)
# ============================================================================

import os
import sys
import unittest
import hashlib

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from backend.db.postgres import Base, engine, SessionLocal, check_db_connection
from backend.db.models import User, Manufacturer, Scan, Violation, ImprovementNotice, EvidenceHash
from backend.db.minio_client import minio_service

class TestInfraLayer(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)

    def test_01_db_connection_health(self):
        health = check_db_connection()
        self.assertEqual(health.get("status"), "healthy")

    def test_02_create_user_and_manufacturer(self):
        db = SessionLocal()
        try:
            # Create user
            user = User(
                username="test_inspector_h1",
                email="test_inspector_h1@gov.in",
                password_hash="mock_hash_123",
                role="inspector",
                region_scope="NORTH_ZONE",
                badge_number="INSP-001"
            )
            db.add(user)

            # Create manufacturer
            mfg = Manufacturer(
                name="Parle Products Pvt Ltd",
                normalized_name="parle products pvt ltd",
                registered_address="Vile Parle East, Mumbai, MH",
                state="Maharashtra",
                gstin="27AABCP1234F1Z5",
                mhi_score=95.50
            )
            db.add(mfg)
            db.commit()
            db.refresh(user)
            db.refresh(mfg)

            self.assertIsNotNone(user.id)
            self.assertIsNotNone(mfg.id)
            self.assertEqual(user.username, "test_inspector_h1")
            self.assertEqual(mfg.name, "Parle Products Pvt Ltd")

            # Create scan and violation
            scan = Scan(
                inspector_id=user.id,
                manufacturer_id=mfg.id,
                commodity_name="Parle-G 800g",
                category="packaged_food",
                overall_severity="MODERATE",
                coin_calibrated=True,
                coin_type="1_rupee",
                mm_per_pixel=0.045
            )
            db.add(scan)
            db.commit()
            db.refresh(scan)

            violation = Violation(
                scan_id=scan.id,
                rule_id="Table_I_Font_Minimum",
                rule_description="Net quantity font height 1.8mm is below 2.0mm minimum required for 800g package",
                severity="MODERATE"
            )
            db.add(violation)
            db.commit()
            db.refresh(violation)

            self.assertIsNotNone(violation.id)
            self.assertEqual(violation.severity, "MODERATE")

        finally:
            db.close()

    def test_03_minio_hash_computation(self):
        test_payload = b"test_violation_photo_content_bytes"
        expected_hash = hashlib.sha256(test_payload).hexdigest()
        actual_hash = minio_service.compute_sha256(test_payload)
        self.assertEqual(actual_hash, expected_hash)

if __name__ == "__main__":
    unittest.main()