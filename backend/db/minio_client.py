# ============================================================================
# LEGALMETRY MinIO Object Storage Client (Person 1 - Data/Infra)
# S3-Compatible Storage for Evidence Photos and Generated PDF Reports
# ============================================================================

import os
import io
import hashlib
import logging
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

try:
    from minio import Minio
    from minio.error import S3Error
    HAS_MINIO = True
except ImportError:
    Minio = None
    S3Error = Exception
    HAS_MINIO = False
    logger.warning("MinIO SDK not installed. Falling back to local storage simulation mode.")

MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "localhost:9000")
MINIO_ROOT_USER = os.getenv("MINIO_ROOT_USER", "minioadmin")
MINIO_ROOT_PASSWORD = os.getenv("MINIO_ROOT_PASSWORD", "minioadmin")
MINIO_SECURE = os.getenv("MINIO_SECURE", "false").lower() == "true"

BUCKET_EVIDENCE = os.getenv("MINIO_BUCKET_EVIDENCE", "legalmetry-evidence")
BUCKET_REPORTS = os.getenv("MINIO_BUCKET_REPORTS", "legalmetry-reports")

class MinioStorageService:
    def __init__(self):
        self.client = None
        if HAS_MINIO:
            try:
                self.client = Minio(
                    MINIO_ENDPOINT,
                    access_key=MINIO_ROOT_USER,
                    secret_key=MINIO_ROOT_PASSWORD,
                    secure=MINIO_SECURE
                )
                logger.info(f"Initialized MinIO client targeting {MINIO_ENDPOINT}")
            except Exception as e:
                logger.warning(f"MinIO client init warning: {e}")

    def ensure_buckets(self):
        """Creates required buckets if they do not already exist."""
        if not self.client:
            return
        for bucket in [BUCKET_EVIDENCE, BUCKET_REPORTS]:
            try:
                if not self.client.bucket_exists(bucket):
                    self.client.make_bucket(bucket)
                    logger.info(f"Created MinIO bucket: {bucket}")
            except S3Error as err:
                logger.error(f"Failed to check/create bucket {bucket}: {err}")

    def compute_sha256(self, data: bytes) -> str:
        """Calculates immutable SHA-256 tamper-proof hash for byte payload."""
        return hashlib.sha256(data).hexdigest()

    def upload_evidence(
        self,
        file_bytes: bytes,
        object_name: str,
        content_type: str = "image/jpeg"
    ) -> Tuple[bool, str, str]:
        """
        Uploads violation photo evidence to MinIO.
        Returns (success, object_name, sha256_hash).
        """
        sha256_hash = self.compute_sha256(file_bytes)
        if not self.client:
            logger.info(f"MinIO client in mock mode; stored virtual object {object_name} [SHA: {sha256_hash[:8]}...]")
            return True, object_name, sha256_hash

        try:
            self.ensure_buckets()
            file_stream = io.BytesIO(file_bytes)
            self.client.put_object(
                bucket_name=BUCKET_EVIDENCE,
                object_name=object_name,
                data=file_stream,
                length=len(file_bytes),
                content_type=content_type
            )
            logger.info(f"Uploaded evidence photo {object_name} [SHA-256: {sha256_hash}]")
            return True, object_name, sha256_hash
        except S3Error as e:
            logger.error(f"Failed to upload evidence to MinIO: {e}")
            return False, "", sha256_hash

    def get_presigned_download_url(
        self,
        bucket_name: str,
        object_name: str,
        expires_seconds: int = 3600
    ) -> Optional[str]:
        """Generates temporary pre-signed URL for evidence retrieval."""
        if not self.client:
            return f"http://{MINIO_ENDPOINT}/{bucket_name}/{object_name}"
        try:
            return self.client.presigned_get_object(
                bucket_name=bucket_name,
                object_name=object_name,
                expires=expires_seconds
            )
        except S3Error as e:
            logger.error(f"Error generating presigned URL: {e}")
            return None

    def health_check(self) -> dict:
        """MinIO connectivity health probe."""
        if not self.client:
            return {"status": "mock_mode", "endpoint": MINIO_ENDPOINT, "note": "MinIO SDK or server pending"}
        try:
            buckets = [b.name for b in self.client.list_buckets()]
            return {"status": "healthy", "endpoint": MINIO_ENDPOINT, "buckets": buckets}
        except Exception as e:
            return {"status": "unhealthy", "error": str(e)}

# Singleton instance
minio_service = MinioStorageService()