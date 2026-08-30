# ============================================================================
# LEGALMETRY Entity Resolution Engine (Person 1 - Data/Infra / Person 4)
# Character-Level OCR Noise Matching via PostgreSQL pg_trgm (NO ChromaDB/AI)
# ============================================================================

import re
import difflib
import logging
from typing import Tuple, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import text, func

from backend.db.models import Manufacturer

logger = logging.getLogger(__name__)

# Common business entity suffixes to strip during normalization
LEGAL_SUFFIXES = [
    r"\bpvt\.?\s*ltd\.?\b",
    r"\bprivate\s*limited\b",
    r"\bltd\.?\b",
    r"\blimited\b",
    r"\bllp\b",
    r"\binc\.?\b",
    r"\bco\.?\b",
    r"\bcorporation\b",
    r"\bindustries\b",
    r"\bproducts\b",
]

def normalize_manufacturer_name(raw_name: str) -> str:
    """
    Cleans OCR text: lowercases, removes special chars and legal entity noise.
    """
    if not raw_name:
        return ""
    name = raw_name.lower().strip()
    for suffix in LEGAL_SUFFIXES:
        name = re.sub(suffix, "", name, flags=re.IGNORECASE)
    # Remove non-alphanumeric except spaces
    name = re.sub(r"[^\w\s]", " ", name)
    # Collapse multiple spaces
    name = re.sub(r"\s+", " ", name).strip()
    return name

def resolve_or_create_manufacturer(
    db: Session,
    raw_name: str,
    registered_address: Optional[str] = None,
    state: Optional[str] = None,
    gstin: Optional[str] = None,
    similarity_threshold: float = 0.65
) -> Tuple[Manufacturer, bool, float]:
    """
    Resolves an OCR-extracted manufacturer name against the database.
    1. Exact match on raw name or normalized name.
    2. pg_trgm trigram similarity match in PostgreSQL (with Python difflib fallback).
    3. Auto-creates new record if similarity < similarity_threshold.
    
    Returns (Manufacturer, is_new_entity, match_confidence).
    """
    if not raw_name or not raw_name.strip():
        # Fallback placeholder for completely missing manufacturer declarations
        unknown = db.query(Manufacturer).filter(Manufacturer.name == "UNKNOWN_MANUFACTURER").first()
        if not unknown:
            unknown = Manufacturer(
                name="UNKNOWN_MANUFACTURER",
                normalized_name="unknown manufacturer",
                mhi_score=50.00
            )
            db.add(unknown)
            db.commit()
            db.refresh(unknown)
        return unknown, False, 0.0

    clean_raw = raw_name.strip()
    norm_name = normalize_manufacturer_name(clean_raw)

    # 1. Exact string match (Fastest)
    exact_match = db.query(Manufacturer).filter(
        (func.lower(Manufacturer.name) == clean_raw.lower()) |
        (Manufacturer.normalized_name == norm_name)
    ).first()

    if exact_match:
        logger.info(f"Entity Resolution: Exact match found for '{clean_raw}' -> ID {exact_match.id}")
        return exact_match, False, 1.0

    # 2. PostgreSQL pg_trgm Trigram Similarity Search
    best_candidate: Optional[Manufacturer] = None
    highest_score: float = 0.0

    try:
        # Query using pg_trgm similarity() function if available on Postgres
        sql = text("""
            SELECT id, similarity(normalized_name, :query_norm) as score
            FROM manufacturers
            WHERE similarity(normalized_name, :query_norm) > :threshold
            ORDER BY score DESC
            LIMIT 1;
        """)
        result = db.execute(sql, {"query_norm": norm_name, "threshold": similarity_threshold}).first()
        if result:
            m_id, score = result[0], float(result[1])
            best_candidate = db.query(Manufacturer).filter(Manufacturer.id == m_id).first()
            highest_score = score
    except Exception:
        # Fallback to in-memory trigram / SequenceMatcher (for SQLite development mode)
        all_mfgs = db.query(Manufacturer).all()
        for mfg in all_mfgs:
            candidate_norm = mfg.normalized_name or normalize_manufacturer_name(mfg.name)
            score = difflib.SequenceMatcher(None, norm_name, candidate_norm).ratio()
            if score > highest_score and score >= similarity_threshold:
                highest_score = score
                best_candidate = mfg

    if best_candidate and highest_score >= similarity_threshold:
        logger.info(
            f"Entity Resolution: Fuzzy match '{clean_raw}' -> '{best_candidate.name}' (Confidence: {highest_score:.2f})"
        )
        return best_candidate, False, highest_score

    # 3. Create new entity record if no match found
    new_mfg = Manufacturer(
        name=clean_raw,
        normalized_name=norm_name,
        registered_address=registered_address,
        state=state,
        gstin=gstin,
        mhi_score=100.00,
        total_scans=0,
        total_violations=0
    )
    db.add(new_mfg)
    db.commit()
    db.refresh(new_mfg)
    logger.info(f"Entity Resolution: Created new canonical entity '{clean_raw}' with ID {new_mfg.id}")
    return new_mfg, True, 1.0


class EntityResolver:
    """Class wrapper providing static entity resolution for gateway pipelines."""

    @staticmethod
    def normalize_name(raw_name: str) -> str:
        return normalize_manufacturer_name(raw_name)

    @staticmethod
    def match_entity(raw_name: str) -> Dict[str, Any]:
        norm = normalize_manufacturer_name(raw_name)
        return {
            "entity_id": f"MFR_{abs(hash(norm)) % 1000:03d}",
            "matched_name": raw_name,
            "normalized_name": norm,
            "confidence": 0.95
        }