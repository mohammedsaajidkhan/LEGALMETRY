# ============================================================================
# LEGALMETRY Evidence Service (Person 1 - Data/Infra Track)
# Two-Tier Report Engine & Cryptographic Evidence Chain of Custody
# ============================================================================

import uuid
import logging
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session

from backend.db.models import Scan, Violation, EvidenceHash, Manufacturer
from backend.db.minio_client import minio_service, BUCKET_EVIDENCE
from backend.rules_workflow.mhi_calculator import recalculate_manufacturer_mhi

logger = logging.getLogger(__name__)

SEVERITY_HIERARCHY = ["CRITICAL", "MODERATE", "MINOR", "COMPLIANT"]

class EvidenceService:
    """
    Manages two-tier report generation, MinIO photo storage, SHA-256 evidence
    hashing, and tamper-proof verification for legal metrology inspections.
    """

    @staticmethod
    def determine_overall_severity(violations: List[Dict[str, Any]]) -> str:
        """
        Determines the highest severity among a set of detected violations.
        Returns 'COMPLIANT' if no violations exist.
        """
        if not violations:
            return "COMPLIANT"
        
        severities = {v.get("severity", "MINOR").upper() for v in violations}
        for sev in ["CRITICAL", "MODERATE", "MINOR"]:
            if sev in severities:
                return sev
        return "MINOR"

    @classmethod
    def ingest_scan_record(
        cls,
        db: Session,
        category: str,
        commodity_name: Optional[str] = None,
        manufacturer_id: Optional[int] = None,
        inspector_id: Optional[int] = None,
        coin_calibrated: bool = False,
        coin_type: Optional[str] = None,
        mm_per_pixel: Optional[float] = None,
        confidence_score: Optional[float] = None,
        raw_ocr_text: Optional[str] = None,
        extracted_fields: Optional[Dict[str, Any]] = None,
        measurements: Optional[Dict[str, Any]] = None,
        violations_data: Optional[List[Dict[str, Any]]] = None,
        photo_bytes: Optional[bytes] = None,
        photo_filename: str = "capture.jpg",
        verification_notes: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Ingests inspection scan adhering strictly to the Two-Tier Report Design:
        1. Compliant scans get a lightweight DB record only (zero MinIO binary upload).
        2. Non-compliant scans (violations detected) upload photo evidence to MinIO,
           compute SHA-256 cryptographic hash, record EvidenceHash, and link violations.
        """
        violations_data = violations_data or []
        extracted_fields = extracted_fields or {}
        measurements = measurements or {}
        overall_severity = cls.determine_overall_severity(violations_data)
        is_compliant = (overall_severity == "COMPLIANT")
        scan_uuid_str = str(uuid.uuid4())

        # 1. Create Scan Record
        scan = Scan(
            scan_uuid=scan_uuid_str,
            inspector_id=inspector_id,
            manufacturer_id=manufacturer_id,
            commodity_name=commodity_name,
            category=category,
            overall_severity=overall_severity,
            coin_calibrated=coin_calibrated,
            coin_type=coin_type,
            mm_per_pixel=mm_per_pixel,
            confidence_score=confidence_score,
            raw_ocr_text=raw_ocr_text,
            extracted_fields=extracted_fields,
            measurements=measurements,
            verification_notes=verification_notes
        )
        db.add(scan)
        db.flush() # Populate scan.id

        evidence_meta: Optional[Dict[str, Any]] = None
        violation_records: List[Violation] = []

        # 2. Two-Tier Storage Decision
        if not is_compliant:
            # Non-Compliant Case: Upload photo evidence to MinIO and record SHA-256
            if photo_bytes:
                evidence_meta = minio_service.store_violation_evidence(
                    scan_id=scan.scan_uuid,
                    photo_bytes=photo_bytes,
                    filename=photo_filename
                )
                
                # Record immutable Evidence Hash
                evidence_hash_entry = EvidenceHash(
                    scan_id=scan.id,
                    photo_filename=photo_filename,
                    minio_bucket=evidence_meta.get("bucket", BUCKET_EVIDENCE),
                    minio_key=evidence_meta.get("key", f"scans/{scan.scan_uuid}/{photo_filename}"),
                    sha256_hash=evidence_meta.get("sha256_hash", ""),
                    uploaded_by_user_id=inspector_id
                )
                db.add(evidence_hash_entry)

            # Record individual violations
            for v_data in violations_data:
                viol = Violation(
                    scan_id=scan.id,
                    rule_id=v_data.get("rule_id", "UNKNOWN_RULE"),
                    rule_description=v_data.get("rule_description", ""),
                    severity=v_data.get("severity", "MINOR").upper(),
                    photo_minio_bucket=evidence_meta.get("bucket") if evidence_meta else None,
                    photo_minio_key=evidence_meta.get("key") if evidence_meta else None,
                    photo_sha256=evidence_meta.get("sha256_hash") if evidence_meta else None,
                    status="DETECTED"
                )
                db.add(viol)
                violation_records.append(viol)
        else:
            # Compliant Case: Lightweight record only, skip binary upload
            logger.info(f"Scan {scan.scan_uuid} is COMPLIANT. Skipping MinIO binary photo upload per two-tier design.")

        # 3. Update Manufacturer Statistics & Recalculate MHI if manufacturer is assigned
        updated_mhi_info = None
        if manufacturer_id:
            manufacturer = db.query(Manufacturer).filter(Manufacturer.id == manufacturer_id).first()
            if manufacturer:
                manufacturer.total_scans = (manufacturer.total_scans or 0) + 1
                if not is_compliant:
                    manufacturer.total_violations = (manufacturer.total_violations or 0) + len(violations_data)
                db.flush()
                # Dynamically recalculate MHI inside active transaction
                updated_mhi_info = recalculate_manufacturer_mhi(db=db, manufacturer_id=manufacturer_id)

        db.commit()
        db.refresh(scan)

        return {
            "scan_id": scan.id,
            "scan_uuid": scan.scan_uuid,
            "category": scan.category,
            "overall_severity": scan.overall_severity,
            "is_compliant": is_compliant,
            "violations_count": len(violation_records),
            "evidence_stored": evidence_meta is not None,
            "evidence_metadata": evidence_meta,
            "manufacturer_mhi": updated_mhi_info,
            "created_at": scan.created_at.isoformat() if scan.created_at else None
        }

    @classmethod
    def get_scan_evidence_manifest(
        cls,
        scan_uuid: str,
        db: Session,
        requesting_role: str = "inspector"
    ) -> Optional[Dict[str, Any]]:
        """
        Retrieves full evidentiary manifest for a scan.
        Applies statutory data isolation rules (Central Director sees aggregated data,
        with individual photos redacted).
        """
        scan = db.query(Scan).filter(Scan.scan_uuid == scan_uuid).first()
        if not scan:
            return None

        evidence_hashes = db.query(EvidenceHash).filter(EvidenceHash.scan_id == scan.id).all()
        violations = db.query(Violation).filter(Violation.scan_id == scan.id).all()

        is_director = (requesting_role.lower() == "director")

        evidence_list = []
        for eh in evidence_hashes:
            evidence_list.append({
                "id": eh.id,
                "photo_filename": eh.photo_filename,
                "sha256_hash": eh.sha256_hash,
                "minio_bucket": None if is_director else eh.minio_bucket,
                "minio_key": None if is_director else eh.minio_key,
                "photo_url": None if is_director else minio_service.get_presigned_download_url(eh.minio_bucket, eh.minio_key),
                "created_at": eh.created_at.isoformat() if eh.created_at else None
            })

        violation_list = []
        for v in violations:
            violation_list.append({
                "id": v.id,
                "rule_id": v.rule_id,
                "rule_description": v.rule_description,
                "severity": v.severity,
                "status": v.status,
                "photo_sha256": v.photo_sha256,
                "photo_url": None if is_director else (
                    minio_service.get_presigned_download_url(v.photo_minio_bucket, v.photo_minio_key)
                    if v.photo_minio_key else None
                )
            })

        return {
            "scan_id": scan.id,
            "scan_uuid": scan.scan_uuid,
            "category": scan.category,
            "commodity_name": scan.commodity_name,
            "overall_severity": scan.overall_severity,
            "coin_calibrated": scan.coin_calibrated,
            "mm_per_pixel": float(scan.mm_per_pixel) if scan.mm_per_pixel else None,
            "evidence_hashes": evidence_list,
            "violations": violation_list,
            "privacy_redacted": is_director,
            "created_at": scan.created_at.isoformat() if scan.created_at else None
        }

    @classmethod
    def verify_scan_tampering(
        cls,
        scan_uuid: str,
        uploaded_photo_bytes: bytes,
        db: Session
    ) -> Dict[str, Any]:
        """
        Verifies if an evidentiary photo has been modified or corrupted against
        the immutable SHA-256 hash recorded at ingestion.
        """
        scan = db.query(Scan).filter(Scan.scan_uuid == scan_uuid).first()
        if not scan:
            return {"error": "Scan not found", "is_valid": False}

        stored_evidence = db.query(EvidenceHash).filter(EvidenceHash.scan_id == scan.id).first()
        if not stored_evidence:
            return {"error": "No stored evidence hash found for this scan", "is_valid": False}

        is_valid = minio_service.verify_photo_hash(uploaded_photo_bytes, stored_evidence.sha256_hash)
        computed_hash = minio_service.compute_sha256(uploaded_photo_bytes)

        return {
            "scan_uuid": scan_uuid,
            "is_valid": is_valid,
            "status": "CHAIN_OF_CUSTODY_VERIFIED" if is_valid else "TAMPERED_OR_CORRUPTED",
            "stored_sha256": stored_evidence.sha256_hash,
            "computed_sha256": computed_hash
        }

evidence_service = EvidenceService()
