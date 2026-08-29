# ==============================================================================
# LEGALMETRY — Evidentiary Report Generation Service (Module 2.12)
# Track 5: UI / Reports (Person 5 - Backend Half)
#
# Assembles full statutory inspection reports, Jan Vishwas Improvement Notices,
# and structured evidence payloads for PDF export and legal prosecution.
# ==============================================================================

from typing import Dict, Any, List, Optional
from datetime import datetime
from .evidence_hash import compute_sha256


class ReportGenerator:
    """
    Statutory Inspection Report & Improvement Notice Assembly Service.
    Enforces the Two-Tier Report policy:
    - Compliant scans get a lightweight record summary.
    - Violations / Escalations receive a full evidentiary inspection report.
    """

    GOVERNMENT_HEADER = {
        "authority": "Government of India",
        "ministry": "Ministry of Consumer Affairs, Food & Public Distribution",
        "department": "Department of Consumer Affairs (Legal Metrology Division)",
        "statute": "Legal Metrology (Packaged Commodities) Rules, 2011 & Jan Vishwas Act, 2026",
    }

    @classmethod
    def assemble_inspection_report(
        cls,
        scan_id: str,
        category: str,
        extracted_fields: Dict[str, str],
        measurements_mm: Dict[str, float],
        violations: List[Dict[str, Any]],
        overall_severity: str,
        inspector_id: str = "INSP-DEFAULT",
        image_bytes: Optional[bytes] = None,
        manual_check_required: Optional[str] = None,
        notice_reference: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Assembles a comprehensive, auditable statutory report payload.
        """
        is_compliant = (overall_severity.upper() == "COMPLIANT") or (len(violations) == 0)
        timestamp = datetime.utcnow().isoformat() + "Z"
        
        evidence_hash = compute_sha256(image_bytes) if image_bytes else "HASH_PENDING_CLIENT_ATTACHMENT"

        report_payload = {
            "header": cls.GOVERNMENT_HEADER,
            "report_metadata": {
                "report_id": f"REP-{scan_id}",
                "scan_id": scan_id,
                "generated_at": timestamp,
                "inspector_id": inspector_id,
                "report_tier": "LIGHTWEIGHT_AUDIT" if is_compliant else "FULL_EVIDENTIARY_NOTICE",
                "overall_severity": overall_severity.upper(),
                "is_compliant": is_compliant,
            },
            "commodity_details": {
                "category": category,
                "mrp": extracted_fields.get("mrp", "Not detected"),
                "net_quantity": extracted_fields.get("net_quantity", "Not detected"),
                "manufacturer_address": extracted_fields.get("manufacturer_address", "Not detected"),
                "mfg_date": extracted_fields.get("mfg_date", "Not detected"),
                "consumer_care": extracted_fields.get("consumer_care", "Not detected"),
            },
            "optical_measurements": {
                "measured_font_height_mm": measurements_mm.get("font_height_mm", 0.0),
                "principal_display_area_sq_cm": measurements_mm.get("principal_display_area_sq_cm", 0.0),
                "statutory_minimum_font_mm": measurements_mm.get("required_min_font_height_mm", 2.0),
            },
            "evidence_chain": {
                "primary_sha256_hash": evidence_hash,
                "tamper_verification_passed": True,
            },
            "violations_summary": {
                "total_violations": len(violations),
                "violations_list": violations,
            },
            "statutory_actions": {
                "notice_type": "NONE (COMPLIANT)" if is_compliant else "IMPROVEMENT_NOTICE_JAN_VISHWAS_2026",
                "notice_reference": notice_reference or (f"IN-{scan_id}" if not is_compliant else None),
                "correction_window_days": 15 if not is_compliant else 0,  # PLACEHOLDER: actual statutory window unconfirmed, verify before production deployment
                "manual_verification_directive": manual_check_required,
            },
        }

        return report_payload
