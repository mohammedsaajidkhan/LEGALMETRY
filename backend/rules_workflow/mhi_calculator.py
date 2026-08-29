# ============================================================================
# LEGALMETRY Manufacturer Hazard Index (MHI) Calculator (Person 1 / Person 4)
# Auditable Weighted Compliance Scoring Formula from PostgreSQL Violation History
# ============================================================================

import logging
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func

from backend.db.models import Manufacturer, Scan, Violation

logger = logging.getLogger(__name__)

# Statutory Severity Deductions
WEIGHT_CRITICAL = 20.0    # Missing mandatory declaration (MRP, Net Qty, Mfg Address)
WEIGHT_MODERATE = 10.0    # Font height violation (Table I), Date formatting error
WEIGHT_MINOR = 4.0        # Minor abbreviation, secondary declaration defect

def calculate_mhi_score(
    critical_count: int,
    moderate_count: int,
    minor_count: int,
    base_score: float = 100.0
) -> float:
    """
    Computes deterministic MHI score:
    MHI = 100 - (20 * Critical + 10 * Moderate + 4 * Minor)
    Bounded between [0.00, 100.00].
    """
    penalty = (
        (critical_count * WEIGHT_CRITICAL) +
        (moderate_count * WEIGHT_MODERATE) +
        (minor_count * WEIGHT_MINOR)
    )
    score = max(0.0, min(100.0, base_score - penalty))
    return round(score, 2)

def recalculate_manufacturer_mhi(
    db: Session,
    manufacturer_id: int
) -> Optional[Dict[str, Any]]:
    """
    Recalculates and persists MHI metrics for a manufacturer in an isolated transaction.
    """
    mfg = db.query(Manufacturer).filter(Manufacturer.id == manufacturer_id).with_for_update().first()
    if not mfg:
        logger.warning(f"MHI Recalculation: Manufacturer ID {manufacturer_id} not found.")
        return None

    # Total scans count
    total_scans = db.query(func.count(Scan.id)).filter(Scan.manufacturer_id == manufacturer_id).scalar() or 0

    # Violations breakdown by severity
    violation_counts = (
        db.query(Violation.severity, func.count(Violation.id))
        .join(Scan, Violation.scan_id == Scan.id)
        .filter(Scan.manufacturer_id == manufacturer_id)
        .group_by(Violation.severity)
        .all()
    )

    counts_map = {"CRITICAL": 0, "MODERATE": 0, "MINOR": 0}
    total_violations = 0
    for sev, cnt in violation_counts:
        sev_upper = str(sev).upper()
        if sev_upper in counts_map:
            counts_map[sev_upper] = cnt
        total_violations += cnt

    # Compute new MHI
    new_mhi = calculate_mhi_score(
        critical_count=counts_map["CRITICAL"],
        moderate_count=counts_map["MODERATE"],
        minor_count=counts_map["MINOR"]
    )

    # Update manufacturer entity
    mfg.mhi_score = new_mhi
    mfg.total_scans = total_scans
    mfg.total_violations = total_violations
    db.commit()
    db.refresh(mfg)

    logger.info(
        f"Updated MHI for '{mfg.name}' [ID: {mfg.id}] -> Score: {new_mhi} "
        f"(Scans: {total_scans}, Violations: {total_violations} [C:{counts_map['CRITICAL']}, M:{counts_map['MODERATE']}, m:{counts_map['MINOR']}])"
    )

    return {
        "manufacturer_id": mfg.id,
        "manufacturer_name": mfg.name,
        "mhi_score": float(mfg.mhi_score),
        "total_scans": mfg.total_scans,
        "total_violations": mfg.total_violations,
        "breakdown": counts_map,
        "risk_tier": get_risk_tier(float(mfg.mhi_score))
    }

def get_risk_tier(score: float) -> str:
    """Classifies MHI score into actionable supervisory risk tiers."""
    if score < 60.0:
        return "HIGH_RISK"
    elif score <= 85.0:
        return "MEDIUM_RISK"
    return "LOW_RISK"

def get_risk_sorted_manufacturers(
    db: Session,
    limit: int = 20,
    min_scans: int = 0
) -> List[Dict[str, Any]]:
    """
    Returns risk-ranked manufacturer list for the Inspector / Officer dashboard.
    Sorted ASC by mhi_score (highest risk first).
    """
    query = db.query(Manufacturer)
    if min_scans > 0:
        query = query.filter(Manufacturer.total_scans >= min_scans)
        
    mfgs = query.order_by(Manufacturer.mhi_score.asc()).limit(limit).all()

    return [
        {
            "id": m.id,
            "name": m.name,
            "state": m.state,
            "mhi_score": float(m.mhi_score) if m.mhi_score is not None else 100.0,
            "total_scans": m.total_scans,
            "total_violations": m.total_violations,
            "risk_tier": get_risk_tier(float(m.mhi_score or 100.0))
        }
        for m in mfgs
    ]