# ============================================================================
# LEGALMETRY SQLAlchemy ORM Models (Person 1 - Data/Infra)
# ============================================================================

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, Integer, String, Text, Boolean, Numeric, 
    DateTime, ForeignKey, JSON
)
from sqlalchemy.orm import relationship
from backend.db.postgres import Base

def utc_now():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False, default="inspector") # inspector, officer, controller, director, consumer
    region_scope = Column(String(100), default="NATIONAL")
    badge_number = Column(String(50), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    scans = relationship("Scan", back_populates="inspector")

class Manufacturer(Base):
    __tablename__ = "manufacturers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    normalized_name = Column(String(255), index=True)
    registered_address = Column(Text, nullable=True)
    state = Column(String(100), nullable=True)
    gstin = Column(String(30), nullable=True)
    mhi_score = Column(Numeric(5, 2), default=100.00)
    total_scans = Column(Integer, default=0)
    total_violations = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    scans = relationship("Scan", back_populates="manufacturer")
    improvement_notices = relationship("ImprovementNotice", back_populates="manufacturer")

class Scan(Base):
    __tablename__ = "scans"

    id = Column(Integer, primary_key=True, index=True)
    scan_uuid = Column(String(36), default=lambda: str(uuid.uuid4()), unique=True, index=True)
    inspector_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    manufacturer_id = Column(Integer, ForeignKey("manufacturers.id"), nullable=True, index=True)
    commodity_name = Column(String(255), nullable=True)
    category = Column(String(100), nullable=False)
    overall_severity = Column(String(50), nullable=False, default="COMPLIANT")
    coin_calibrated = Column(Boolean, default=False)
    coin_type = Column(String(50), nullable=True)
    mm_per_pixel = Column(Numeric(8, 5), nullable=True)
    confidence_score = Column(Numeric(5, 2), nullable=True)
    raw_ocr_text = Column(Text, nullable=True)
    extracted_fields = Column(JSON, default=dict)
    measurements = Column(JSON, default=dict)
    verification_notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, index=True)

    inspector = relationship("User", back_populates="scans")
    manufacturer = relationship("Manufacturer", back_populates="scans")
    violations = relationship("Violation", back_populates="scan", cascade="all, delete-orphan")
    evidence_hashes = relationship("EvidenceHash", back_populates="scan", cascade="all, delete-orphan")

class Violation(Base):
    __tablename__ = "violations"

    id = Column(Integer, primary_key=True, index=True)
    scan_id = Column(Integer, ForeignKey("scans.id", ondelete="CASCADE"), nullable=False, index=True)
    rule_id = Column(String(100), nullable=False, index=True)
    rule_description = Column(Text, nullable=False)
    severity = Column(String(50), nullable=False, index=True) # CRITICAL, MODERATE, MINOR
    photo_minio_bucket = Column(String(100), default="legalmetry-evidence")
    photo_minio_key = Column(String(255), nullable=True)
    photo_sha256 = Column(String(64), nullable=True)
    status = Column(String(50), default="DETECTED")
    created_at = Column(DateTime(timezone=True), default=utc_now)

    scan = relationship("Scan", back_populates="violations")
    improvement_notice = relationship("ImprovementNotice", back_populates="violation", uselist=False)

class ImprovementNotice(Base):
    __tablename__ = "improvement_notices"

    id = Column(Integer, primary_key=True, index=True)
    notice_number = Column(String(100), unique=True, nullable=False, index=True)
    violation_id = Column(Integer, ForeignKey("violations.id", ondelete="CASCADE"), nullable=False)
    manufacturer_id = Column(Integer, ForeignKey("manufacturers.id", ondelete="CASCADE"), nullable=False, index=True)
    issue_date = Column(DateTime(timezone=True), default=utc_now)
    window_end_date = Column(DateTime(timezone=True), nullable=False)
    status = Column(String(50), nullable=False, default="NOTICE_ISSUED", index=True)
    resolution_notes = Column(Text, nullable=True)
    supervisor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    violation = relationship("Violation", back_populates="improvement_notice")
    manufacturer = relationship("Manufacturer", back_populates="improvement_notices")

class EvidenceHash(Base):
    __tablename__ = "evidence_hashes"

    id = Column(Integer, primary_key=True, index=True)
    scan_id = Column(Integer, ForeignKey("scans.id", ondelete="CASCADE"), nullable=False, index=True)
    photo_filename = Column(String(255), nullable=False)
    minio_bucket = Column(String(100), nullable=False, default="legalmetry-evidence")
    minio_key = Column(String(255), nullable=False)
    sha256_hash = Column(String(64), nullable=False, index=True)
    uploaded_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)

    scan = relationship("Scan", back_populates="evidence_hashes")