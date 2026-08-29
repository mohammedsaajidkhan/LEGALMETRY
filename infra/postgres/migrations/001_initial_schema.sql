-- ============================================================================
-- LEGALMETRY: PostgreSQL Initial Schema (Person 1 - Data/Infra)
-- Compliance Scanner for Legal Metrology (Packaged Commodities) Rules, 2011
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 1. USERS & ROLES TABLE
-- Roles: inspector, officer, controller, director, consumer
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'inspector',
    region_scope VARCHAR(100) DEFAULT 'NATIONAL',
    badge_number VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 2. MANUFACTURERS / PACKERS TABLE
-- Trigram index for character-level OCR fuzzy matching (No ChromaDB)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS manufacturers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255),
    registered_address TEXT,
    state VARCHAR(100),
    gstin VARCHAR(30),
    mhi_score NUMERIC(5, 2) DEFAULT 100.00,
    total_scans INTEGER DEFAULT 0,
    total_violations INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- GIN index for pg_trgm similarity matching
CREATE INDEX IF NOT EXISTS idx_manufacturers_name_trgm ON manufacturers USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_manufacturers_norm_name_trgm ON manufacturers USING gin (normalized_name gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- 3. SCANS TABLE
-- Records each commodity capture & evaluation
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scans (
    id SERIAL PRIMARY KEY,
    scan_uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    inspector_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    manufacturer_id INTEGER REFERENCES manufacturers(id) ON DELETE SET NULL,
    commodity_name VARCHAR(255),
    category VARCHAR(100) NOT NULL, -- e.g. packaged_food, cosmetics, electronics
    overall_severity VARCHAR(50) NOT NULL DEFAULT 'COMPLIANT', -- COMPLIANT, MINOR, MODERATE, CRITICAL
    coin_calibrated BOOLEAN DEFAULT FALSE,
    coin_type VARCHAR(50),
    mm_per_pixel NUMERIC(8, 5),
    confidence_score NUMERIC(5, 2),
    raw_ocr_text TEXT,
    extracted_fields JSONB DEFAULT '{}'::jsonb,
    measurements JSONB DEFAULT '{}'::jsonb,
    verification_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_scans_manufacturer_id ON scans(manufacturer_id);
CREATE INDEX IF NOT EXISTS idx_scans_inspector_id ON scans(inspector_id);
CREATE INDEX IF NOT EXISTS idx_scans_overall_severity ON scans(overall_severity);
CREATE INDEX IF NOT EXISTS idx_scans_created_at ON scans(created_at DESC);

-- ----------------------------------------------------------------------------
-- 4. VIOLATIONS TABLE
-- Individual Rule infractions tied to scans
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS violations (
    id SERIAL PRIMARY KEY,
    scan_id INTEGER NOT NULL REFERENCES scans(id) ON DELETE CASCADE,
    rule_id VARCHAR(100) NOT NULL, -- e.g. Rule_6_1_a, Table_I_Font_Height
    rule_description TEXT NOT NULL,
    severity VARCHAR(50) NOT NULL, -- CRITICAL, MODERATE, MINOR
    photo_minio_bucket VARCHAR(100) DEFAULT 'legalmetry-evidence',
    photo_minio_key VARCHAR(255),
    photo_sha256 VARCHAR(64),
    status VARCHAR(50) DEFAULT 'DETECTED',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_violations_scan_id ON violations(scan_id);
CREATE INDEX IF NOT EXISTS idx_violations_rule_id ON violations(rule_id);
CREATE INDEX IF NOT EXISTS idx_violations_severity ON violations(severity);

-- ----------------------------------------------------------------------------
-- 5. IMPROVEMENT NOTICES TABLE (Jan Vishwas Reform Workflow)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS improvement_notices (
    id SERIAL PRIMARY KEY,
    notice_number VARCHAR(100) UNIQUE NOT NULL,
    violation_id INTEGER REFERENCES violations(id) ON DELETE CASCADE,
    manufacturer_id INTEGER REFERENCES manufacturers(id) ON DELETE CASCADE,
    issue_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    window_end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'NOTICE_ISSUED', 
    -- NOTICE_ISSUED, DISPUTED, PENDING_SUPERVISOR_VERIFICATION, ESCALATED_PENDING_VERIFICATION, SECOND_OFFENCE_CONFIRMED, CLOSED
    resolution_notes TEXT,
    supervisor_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notices_manufacturer_id ON improvement_notices(manufacturer_id);
CREATE INDEX IF NOT EXISTS idx_notices_status ON improvement_notices(status);

-- ----------------------------------------------------------------------------
-- 6. EVIDENCE HASHES TABLE (Immutable Chain-of-Custody Hashing)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS evidence_hashes (
    id SERIAL PRIMARY KEY,
    scan_id INTEGER REFERENCES scans(id) ON DELETE CASCADE,
    photo_filename VARCHAR(255) NOT NULL,
    minio_bucket VARCHAR(100) NOT NULL DEFAULT 'legalmetry-evidence',
    minio_key VARCHAR(255) NOT NULL,
    sha256_hash VARCHAR(64) NOT NULL,
    uploaded_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_evidence_scan_id ON evidence_hashes(scan_id);
CREATE INDEX IF NOT EXISTS idx_evidence_sha256 ON evidence_hashes(sha256_hash);

-- Seed initial inspector user
INSERT INTO users (username, email, password_hash, role, region_scope, badge_number)
VALUES ('inspector_demo', 'inspector@legalmetry.gov.in', '$2b$12$e7QG6O6bJ1tWbA1l9WcE1OHX2tXzM7N1U6sC4k9u8B3G0D9A7L6K2', 'inspector', 'WEST_ZONE', 'LM-INSP-0842')
ON CONFLICT (username) DO NOTHING;