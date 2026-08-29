# ============================================================================
# LEGALMETRY PostgreSQL Connection & Session Management (Person 1 - Data/Infra)
# ============================================================================

import os
import logging
from typing import Generator
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from sqlalchemy.pool import QueuePool

logger = logging.getLogger(__name__)

# Configurable database URL with default local fallback
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://postgres:postgres@localhost:5432/legalmetry"
)

# SQLite in-memory fallback for lightweight testing if PostgreSQL is unreachable
SQLITE_FALLBACK_URL = "sqlite:///./legalmetry_dev.db"

def get_engine():
    try:
        engine = create_engine(
            DATABASE_URL,
            poolclass=QueuePool,
            pool_size=10,
            max_overflow=20,
            pool_pre_ping=True,
            pool_recycle=1800,
        )
        # Test connection
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("Successfully connected to PostgreSQL database.")
        return engine
    except Exception as e:
        logger.warning(
            f"PostgreSQL connection failed at {DATABASE_URL}: {e}. Falling back to SQLite for local development."
        )
        return create_engine(
            SQLITE_FALLBACK_URL,
            connect_args={"check_same_thread": False}
        )

engine = get_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency that yields a database session.
    Automatically closes session after request lifecycle.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def check_db_connection() -> dict:
    """
    Health check utility for database connectivity.
    """
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "healthy", "database": engine.url.drivername}
    except Exception as exc:
        return {"status": "unhealthy", "error": str(exc)}