# ==============================================================================
# LEGALMETRY — Evidence Hashing Service (Module 2.13)
# Track 5: UI / Reports (Person 5 - Backend Half)
#
# Tamper-evidence cryptographic fingerprinting for captured product photos
# Standard: SHA-256 computed at moment of capture
# ==============================================================================

import hashlib
import io
from typing import List, Dict, Optional, Union


def compute_sha256(data: Union[bytes, bytearray, io.BytesIO]) -> str:
    """
    Computes standard SHA-256 hexadecimal digest for raw image bytes.
    Ensures evidentiary integrity for legal prosecution under Legal Metrology Act.
    """
    if isinstance(data, io.BytesIO):
        data = data.getvalue()
    elif isinstance(data, bytearray):
        data = bytes(data)
    
    sha256_hash = hashlib.sha256()
    sha256_hash.update(data)
    return sha256_hash.hexdigest()


def compute_multi_photo_hashes(photo_bytes_list: List[bytes]) -> List[Dict[str, Union[int, str]]]:
    """
    Computes individual SHA-256 hashes for multi-angle capture batches.
    Edge Case Handled: Multi-angle photos each have their own independent hash.
    """
    hashes = []
    for idx, photo_bytes in enumerate(photo_bytes_list, start=1):
        digest = compute_sha256(photo_bytes)
        hashes.append({
            "angle_index": idx,
            "sha256_hash": digest,
            "byte_size": len(photo_bytes),
        })
    return hashes


def verify_evidence_integrity(photo_bytes: bytes, recorded_hash: str) -> bool:
    """
    Verifies that photo bytes match the recorded cryptographic hash.
    Returns True if untampered, False if mismatch or corrupted.
    """
    if not recorded_hash or not photo_bytes:
        return False
    current_hash = compute_sha256(photo_bytes)
    return current_hash.lower() == recorded_hash.lower().strip()


def format_evidence_manifest(
    scan_id: str,
    image_bytes: bytes,
    captured_by_user_id: str,
    timestamp_iso: str,
    additional_angles: Optional[List[bytes]] = None,
) -> Dict[str, Union[str, int, List[Dict[str, Union[int, str]]]]]:
    """
    Assembles a full cryptographic evidence manifest for statutory reports.
    """
    primary_hash = compute_sha256(image_bytes)
    manifest = {
        "scan_id": scan_id,
        "primary_evidence_hash": primary_hash,
        "primary_byte_size": len(image_bytes),
        "captured_by": captured_by_user_id,
        "timestamp": timestamp_iso,
        "algorithm": "SHA-256",
    }
    
    if additional_angles:
        manifest["additional_angle_hashes"] = compute_multi_photo_hashes(additional_angles)
    
    return manifest


class EvidenceHasher:
    """Class wrapper providing static hashing methods for cross-module compatibility."""

    @staticmethod
    def compute_bytes_hash(data: Union[bytes, bytearray, io.BytesIO]) -> str:
        return compute_sha256(data)

    @staticmethod
    def compute_sha256(data: Union[bytes, bytearray, io.BytesIO]) -> str:
        return compute_sha256(data)

    @staticmethod
    def verify_integrity(photo_bytes: bytes, recorded_hash: str) -> bool:
        return verify_evidence_integrity(photo_bytes, recorded_hash)
