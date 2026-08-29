# ============================================================================
# LEGALMETRY Evidence API Router (Person 1 - Data/Infra Track)
# Endpoints for Evidence Retrieval, Chain-of-Custody Manifests & Tamper Verification
# ============================================================================

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.orm import Session
from typing import Optional

from backend.db.postgres import get_db
from backend.db.evidence_service import evidence_service
from backend.auth.rbac import get_current_user
from backend.db.models import User

evidence_router = APIRouter(prefix="/evidence", tags=["Evidence & Chain-of-Custody"])

@evidence_router.get("/manifest/{scan_uuid}")
def get_evidence_manifest(
    scan_uuid: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Returns full cryptographic evidence manifest including SHA-256 hashes and
    presigned MinIO photo URLs. Automatically redacts individual photo links
    for Central Director role per statutory privacy requirements.
    """
    manifest = evidence_service.get_scan_evidence_manifest(
        scan_uuid=scan_uuid,
        db=db,
        requesting_role=current_user.role
    )
    if not manifest:
        raise HTTPException(status_code=404, detail="Scan evidence record not found")
    return manifest

@evidence_router.post("/verify-tamper/{scan_uuid}")
async def verify_photo_tamper(
    scan_uuid: str,
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Verifies uploaded photo bytes against the immutable SHA-256 hash recorded
    at ingestion time. Confirms forensic chain-of-custody for legal proceedings.
    """
    photo_bytes = await photo.read()
    result = evidence_service.verify_scan_tampering(
        scan_uuid=scan_uuid,
        uploaded_photo_bytes=photo_bytes,
        db=db
    )
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result
