#!/bin/sh
CURRENT_DATE=$(date +%Y-%m-%d_%H-%M-%S)

infoMessage()
{
    echo "INFO: ${1}"
}

erroMessage()
{
    echo "ERROR: ${1}"
    exit 1
}

checkVariable(){
    if [ -z "${1}" ]; then
        erroMessage "${1} is not set"
    fi
}

infoMessage "Starting backup"
infoMessage "Current date: ${CURRENT_DATE}"
infoMessage "Environment variables checks started"

# Check envs are not empty
checkVariable "$S3_BUCKET"
checkVariable "$S3_ENDPOINT"
checkVariable "$S3_ACCESS_KEY"
checkVariable "$S3_ACCESS_KEY"
checkVariable "$S3_REGION"
checkVariable "$S3_SSL"
checkVariable "$BACKUP_NAME"
checkVariable "$BACKUP_DIR"

# Check if backup dir exists
if [ ! -d "$BACKUP_DIR" ]; then
    erroMessage "Backup directory does not exist"
fi
infoMessage "Environment variables checks completed"

# Check if backup dir is empty
if [ ! "$(ls -A "${BACKUP_DIR}")" ]; then
    erroMessage "Backup directory is empty"
fi

# Check if s3cmd is installed
if ! command -v s3cmd > /dev/null 2>&1; then
    erroMessage "s3cmd could not be found"
fi

# Create the .s3cfg file
cat > ~/.s3cfg << EOF
[default]
access_key = ${S3_ACCESS_KEY}
secret_key = ${S3_SECRET_KEY}
bucket_location = ${S3_REGION}
use_https = ${S3_SSL}
host_base = ${S3_ENDPOINT}
host_bucket = ${S3_ENDPOINT}
EOF

# Check if bucket exists
if [ "${S3_SSL}" = true ]; then
    DEFAULT_URL_PREFIX=https
else
    DEFAULT_URL_PREFIX=http
fi

# Create the bucket if it does not exist
if ! s3cmd la --host="${DEFAULT_URL_PREFIX}://${S3_ENDPOINT#*.}" | grep "${S3_BUCKET}" > /dev/null; then
    if ! s3cmd mb s3://"${S3_BUCKET}" > /dev/null; then
        erroMessage "Could not create bucket"
    fi
    infoMessage "Bucket created successfully"
else
    infoMessage "Bucket already exists"
fi

# Create tar.gz file
infoMessage "Creating backup file"
if ! tar -czf "/tmp/${BACKUP_NAME}_${CURRENT_DATE}.tar.gz" .; then
    erroMessage "Could not create tar.gz file"
fi
infoMessage "Backup file created successfully"

# Upload backup file to s3
infoMessage "Uploading backup file to S3"
if ! s3cmd put "/tmp/${BACKUP_NAME}_${CURRENT_DATE}.tar.gz" "s3://${S3_BUCKET}" > /dev/null; then
    erroMessage "Could not upload backup file to S3"
fi
infoMessage "Backup completed successfully"
