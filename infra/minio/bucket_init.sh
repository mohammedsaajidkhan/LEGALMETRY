#!/bin/sh
# MinIO Bucket Initialization Script for LEGALMETRY
# Creates required storage buckets with retry until MinIO is healthy

set -e

echo "Waiting for MinIO server to be available at http://minio:9000..."
until /usr/bin/mc alias set legalmetry http://minio:9000 "${MINIO_ROOT_USER:-minioadmin}" "${MINIO_ROOT_PASSWORD:-minioadmin}"; do
    echo "MinIO server not ready yet... retrying in 2 seconds"
    sleep 2
done

echo "Creating standard buckets..."
/usr/bin/mc mb --ignore-existing legalmetry/legalmetry-evidence
/usr/bin/mc mb --ignore-existing legalmetry/legalmetry-reports

echo "Configuring public read policy for report exports..."
/usr/bin/mc anonymous set download legalmetry/legalmetry-reports || true

echo "MinIO bucket initialization completed successfully."