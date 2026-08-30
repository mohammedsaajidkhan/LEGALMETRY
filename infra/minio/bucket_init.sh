#!/bin/sh
# ==============================================================================
# LEGALMETRY — MinIO Object Storage Bucket Initializer (Person 1 - Infra)
# Initializes evidence and reports storage buckets with download policies
# ==============================================================================

set -e

echo "Waiting for MinIO server to be healthy..."
until (/usr/bin/mc alias set legalmetry http://minio:9000 minioadmin minioadmin123); do
    echo "MinIO not ready yet, retrying in 2 seconds..."
    sleep 2
done

echo "Creating standard LEGALMETRY storage buckets..."
/usr/bin/mc mb --ignore-existing legalmetry/legalmetry-evidence
/usr/bin/mc mb --ignore-existing legalmetry/legalmetry-reports

echo "Configuring public read access for official inspection reports..."
/usr/bin/mc anonymous set download legalmetry/legalmetry-reports

echo "MinIO buckets initialized successfully."
exit 0