#!/bin/sh
CURRENT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
S3_ALIAS_NAME="docker-backup"

echo "Starting backup"
echo "Current date: ${CURRENT_DATE}"
echo "Environment variables checks started"
# Check envs are not empty
if [ -z "$BACKUP_DIR" ]; then
    echo "BACKUP_DIR is not set"
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo "S3_BUCKET is not set"
    exit 1
fi

if [ -z "$S3_ENDPOINT" ]; then
    echo "S3_ENDPOINT is not set"
    exit 1
fi

if [ -z "$S3_ACCESS_KEY" ]; then
    echo "S3_ACCESS_KEY is not set"
    exit 1
fi

if [ -z "$S3_SECRET_KEY" ]; then
    echo "S3_SECRET_KEY is not set"
    exit 1
fi

if [ -z "$S3_REGION" ]; then
    echo "S3_REGION is not set"
    exit 1
fi

if [ -z "$S3_SSL" ]; then
    echo "S3_SSL is not set"
    exit 1
fi

if [ -z "$BACKUP_NAME" ]; then
    echo "BACKUP_NAME is not set"
    exit 1
fi

# Check if backup dir exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory does not exist"
    exit 1
fi
echo "Environment variables checks completed"

# Check if backup dir is empty
if [ ! "$(ls -A "${BACKUP_DIR}")" ]; then
    echo "Backup directory is empty"
    exit 1
fi

# Check if minio-client is installed
if ! command -v mc > /dev/null 2>&1
then
    echo "Minio-client could not be found"
    exit 1
fi

# Create alias for s3 and check for ssl
echo "Creating alias for S3"
if [ "${S3_SSL}" = "true" ]; then
    S3_ENDPOINT="https://${S3_ENDPOINT}"
else
    S3_ENDPOINT="http://${S3_ENDPOINT}"
fi
if ! mc alias set "${S3_ALIAS_NAME}" "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}"; then
    echo "Could not create alias for S3"
    exit 1
fi
echo "Alias created successfully"

# Ping s3
echo "Pinging S3"
if ! mc ping -q --count 3 "${S3_ALIAS_NAME}"; then
    echo "Could not connect to S3"
    exit 1
fi
echo "S3 pinged successfully"

# Create tar.gz file
echo "Creating tar.gz file"
if ! tar -czf "/tmp/${BACKUP_NAME}_${CURRENT_DATE}.tar.gz" --exclude="${BACKUP_NAME}_${CURRENT_DATE}.tar.gz" ./; then
    echo "Could not create tar.gz file"
    exit 1
fi
echo "Tar.gz file created successfully"

# Upload backup file to s3
echo "Uploading backup file to S3"
if ! mc cp "/tmp/${BACKUP_NAME}_${CURRENT_DATE}.tar.gz" "${S3_ALIAS_NAME}/${S3_BUCKET}"; then
    echo "Could not upload backup file to S3"
    exit 1
fi
echo "Backup completed successfully"