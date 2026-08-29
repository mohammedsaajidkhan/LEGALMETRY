# ============================================================================
# LEGALMETRY Evidence Pipeline & Checkpoint 2 Unit Tests (Person 1)
# Verifies Two-Tier Storage, SHA-256 Tamper-Proofing, & Checkpoint 2 Queryability
# ============================================================================

import pytest
import hashlib
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from backend.db.postgres import Base, get_db
from backend.db.models import User, Manufacturer, Scan, Violation, EvidenceHash
from backend.db.evidence_service import evidence_service
from backend.auth.jwt_handler import get_password_hash, create_access_token
from backend.main import app

from sqlalchemy.pool import StaticPool

# Test In-Memory Database with StaticPool
TEST_DB_URL = "sqlite:///:memory:"
engine = create_engine(
    TEST_DB_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_test_db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()

    # Create demo test users
    inspector_user = User(
        username="inspector_ev_test",
        email="inspector_ev@legalmetry.gov.in",
        password_hash=get_password_hash("Inspect@123"),
        role="inspector",
        region_scope="MH-MUMBAI"
    )
    director_user = User(
        username="director_ev_test",
        email="director_ev@legalmetry.gov.in",
        password_hash=get_password_hash("Director@123"),
        role="director",
        region_scope="NATIONAL"
    )
    db.add(inspector_user)
    db.add(director_user)

    # Create demo test manufacturer
    mfg = Manufacturer(
        name="Apex Agro Products Ltd",
        normalized_name="apex agro products",
        registered_address="Plot 45, MIDC, Mumbai, Maharashtra",
        mhi_score=100.0,
        total_scans=0,
        total_violations=0
    )
    db.add(mfg)
    db.commit()
    db.close()
    yield
    Base.metadata.drop_all(bind=engine)

class TestEvidencePipeline:

    def test_01_two_tier_compliant_scan_skips_binary_upload(self):
        """Compliant scans must create lightweight DB records and skip MinIO upload."""
        db = TestingSessionLocal()
        try:
            mfg = db.query(Manufacturer).filter(Manufacturer.name == "Apex Agro Products Ltd").first()
            result = evidence_service.ingest_scan_record(
                db=db,
                category="Pre-Packaged Food & Beverages",
                commodity_name="Refined Sunflower Oil 1L",
                manufacturer_id=mfg.id,
                coin_calibrated=True,
                coin_type="RS_10",
                mm_per_pixel=0.085,
                confidence_score=95.5,
                extracted_fields={"mrp": "Rs. 150.00", "net_quantity": "1 L"},
                violations_data=[], # Zero violations -> Compliant
                photo_bytes=b"sample_compliant_photo_bytes",
                photo_filename="oil_bottle_front.jpg"
            )

            assert result["is_compliant"] is True
            assert result["overall_severity"] == "COMPLIANT"
            assert result["violations_count"] == 0
            assert result["evidence_stored"] is False

            # Verify no EvidenceHash was written for compliant scan
            scan_id = result["scan_id"]
            hashes = db.query(EvidenceHash).filter(EvidenceHash.scan_id == scan_id).all()
            assert len(hashes) == 0

            # Verify scan record exists
            scan = db.query(Scan).filter(Scan.id == scan_id).first()
            assert scan is not None
            assert scan.overall_severity == "COMPLIANT"
        finally:
            db.close()

    def test_02_two_tier_violation_scan_stores_photo_and_sha256(self):
        """Scans with violations must store photo metadata and immutable SHA-256 hash."""
        db = TestingSessionLocal()
        try:
            mfg = db.query(Manufacturer).filter(Manufacturer.name == "Apex Agro Products Ltd").first()
            photo_raw_data = b"\xFF\xD8\xFF\xE0\x00\x10JFIF_SAMPLE_VIOLATION_EVIDENCE_PHOTO_12345"
            expected_sha256 = hashlib.sha256(photo_raw_data).hexdigest()

            violations_input = [
                {
                    "rule_id": "RULE_6_1_C_MRP_MISSING",
                    "rule_description": "Retail sale price (MRP) is completely absent from label",
                    "severity": "CRITICAL"
                },
                {
                    "rule_id": "RULE_8_FONT_SIZE_DEFICIT",
                    "rule_description": "Net quantity font height is 1.2mm, below statutory minimum of 2.0mm",
                    "severity": "MODERATE"
                }
            ]

            result = evidence_service.ingest_scan_record(
                db=db,
                category="Pre-Packaged Food & Beverages",
                commodity_name="Biscuits 200g Pack",
                manufacturer_id=mfg.id,
                coin_calibrated=True,
                coin_type="RS_5",
                mm_per_pixel=0.075,
                confidence_score=92.0,
                extracted_fields={"net_quantity": "200g"},
                violations_data=violations_input,
                photo_bytes=photo_raw_data,
                photo_filename="biscuit_back_pdp.jpg"
            )

            assert result["is_compliant"] is False
            assert result["overall_severity"] == "CRITICAL"
            assert result["violations_count"] == 2
            assert result["evidence_stored"] is True
            assert result["evidence_metadata"]["sha256_hash"] == expected_sha256

            # Verify EvidenceHash record in DB
            scan_id = result["scan_id"]
            eh = db.query(EvidenceHash).filter(EvidenceHash.scan_id == scan_id).first()
            assert eh is not None
            assert eh.sha256_hash == expected_sha256
            assert eh.photo_filename == "biscuit_back_pdp.jpg"

            # Verify Violations linked to MinIO key and SHA-256
            viols = db.query(Violation).filter(Violation.scan_id == scan_id).all()
            assert len(viols) == 2
            for v in viols:
                assert v.photo_sha256 == expected_sha256
                assert v.photo_minio_key.startswith("scans/")

            # Verify MHI was recalculated ($100 - (20*1 + 10*1) = 70.0$)
            mfg_refreshed = db.query(Manufacturer).filter(Manufacturer.id == mfg.id).first()
            assert float(mfg_refreshed.mhi_score) == 70.0
            assert mfg_refreshed.total_violations == 2
        finally:
            db.close()

    def test_03_tamper_detection_and_chain_of_custody(self):
        """Verifies cryptographic tamper detection passes on original and flags modifications."""
        db = TestingSessionLocal()
        try:
            original_bytes = b"IMMUTABLE_COURT_EVIDENCE_PHOTO_BYTES_998877"
            tampered_bytes = b"IMMUTABLE_COURT_EVIDENCE_PHOTO_BYTES_998878" # 1 byte changed

            result = evidence_service.ingest_scan_record(
                db=db,
                category="Cosmetics & Personal Care",
                commodity_name="Shampoo 180ml",
                violations_data=[{"rule_id": "RULE_6_DATE_MISSING", "severity": "MODERATE", "rule_description": "Mfg date missing"}],
                photo_bytes=original_bytes,
                photo_filename="shampoo_bottle.jpg"
            )
            scan_uuid = result["scan_uuid"]

            # 1. Test authentic evidence verification
            verify_ok = evidence_service.verify_scan_tampering(scan_uuid, original_bytes, db)
            assert verify_ok["is_valid"] is True
            assert verify_ok["status"] == "CHAIN_OF_CUSTODY_VERIFIED"

            # 2. Test tampered/altered evidence verification
            verify_tampered = evidence_service.verify_scan_tampering(scan_uuid, tampered_bytes, db)
            assert verify_tampered["is_valid"] is False
            assert verify_tampered["status"] == "TAMPERED_OR_CORRUPTED"
        finally:
            db.close()

    def test_04_director_statutory_privacy_sanitization(self):
        """Verifies Director queries mask raw photo URLs and storage keys per statutory privacy rules."""
        db = TestingSessionLocal()
        try:
            photo_data = b"CONFIDENTIAL_INSPECTOR_PHOTO"
            result = evidence_service.ingest_scan_record(
                db=db,
                category="Pre-Packaged Food & Beverages",
                violations_data=[{"rule_id": "RULE_6_MRP", "severity": "CRITICAL", "rule_description": "MRP absent"}],
                photo_bytes=photo_data,
                photo_filename="privacy_test.jpg"
            )
            scan_uuid = result["scan_uuid"]

            # 1. Inspector manifest has photo URLs
            inspector_manifest = evidence_service.get_scan_evidence_manifest(scan_uuid, db, requesting_role="inspector")
            assert inspector_manifest["privacy_redacted"] is False
            assert len(inspector_manifest["evidence_hashes"]) > 0
            assert inspector_manifest["evidence_hashes"][0]["photo_url"] is not None

            # 2. Director manifest redacts photo URLs and object keys
            director_manifest = evidence_service.get_scan_evidence_manifest(scan_uuid, db, requesting_role="director")
            assert director_manifest["privacy_redacted"] is True
            assert director_manifest["evidence_hashes"][0]["photo_url"] is None
            assert director_manifest["evidence_hashes"][0]["minio_key"] is None
        finally:
            db.close()

    def test_05_evidence_api_endpoints_integration(self):
        """Tests /evidence/manifest and /evidence/verify-tamper REST endpoints."""
        db = TestingSessionLocal()
        try:
            photo_payload = b"REST_API_EVIDENCE_PHOTO_BYTES_445566"
            result = evidence_service.ingest_scan_record(
                db=db,
                category="Pre-Packaged Food & Beverages",
                violations_data=[{"rule_id": "RULE_6_NET_QTY", "severity": "CRITICAL", "rule_description": "Net quantity missing"}],
                photo_bytes=photo_payload,
                photo_filename="api_evidence.jpg"
            )
            scan_uuid = result["scan_uuid"]

            # Generate Inspector JWT
            token = create_access_token(data={"sub": "1", "username": "inspector_ev_test", "role": "inspector", "region_scope": "MH-MUMBAI"})
            headers = {"Authorization": f"Bearer {token}"}

            # 1. GET /evidence/manifest/{scan_uuid}
            response = client.get(f"/evidence/manifest/{scan_uuid}", headers=headers)
            assert response.status_code == 200
            manifest_json = response.json()
            assert manifest_json["scan_uuid"] == scan_uuid
            assert len(manifest_json["violations"]) == 1

            # 2. POST /evidence/verify-tamper/{scan_uuid} (Valid photo)
            files = {"photo": ("api_evidence.jpg", photo_payload, "image/jpeg")}
            tamper_resp = client.post(f"/evidence/verify-tamper/{scan_uuid}", files=files, headers=headers)
            assert tamper_resp.status_code == 200
            assert tamper_resp.json()["is_valid"] is True
            assert tamper_resp.json()["status"] == "CHAIN_OF_CUSTODY_VERIFIED"

            # 3. POST /evidence/verify-tamper/{scan_uuid} (Tampered photo)
            files_bad = {"photo": ("api_evidence.jpg", b"ALTERED_DATA", "image/jpeg")}
            tamper_bad_resp = client.post(f"/evidence/verify-tamper/{scan_uuid}", files=files_bad, headers=headers)
            assert tamper_bad_resp.status_code == 200
            assert tamper_bad_resp.json()["is_valid"] is False
            assert tamper_bad_resp.json()["status"] == "TAMPERED_OR_CORRUPTED"
        finally:
            db.close()
