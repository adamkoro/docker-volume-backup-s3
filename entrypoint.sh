#!/bin/bash
CURRENT_DATE=$(date +%Y-%m-%d_%H-%M-%S)

infoMessage()
{
    echo "$(date +"%Y-%m-%dT%H:%M:%S%:z") - [INFO] ${*}"
}

errorMessage()
{
    echo "$(date +"%Y-%m-%dT%H:%M:%S%:z") - [ERROR] ${*}" >&2
    exit 1
}

checkVariable(){
    if [ -z "${1}" ]; then
        errorMessage "${2} variable is not set"
    fi
}

infoMessage "Starting backup"
infoMessage "Environment variables checks started"

# Check envs are not empty
checkVariable "${S3_BUCKET}" "S3_BUCKET"
checkVariable "${S3_ENDPOINT}" "S3_ENDPOINT"
checkVariable "${S3_ACCESS_KEY}" "S3_ACCESS_KEY"
checkVariable "${S3_SECRET_KEY}" "S3_SECRET_KEY"
checkVariable "${S3_REGION}" "S3_REGION"
checkVariable "${S3_SSL}" "S3_SSL"
checkVariable "${BACKUP_NAME}" "BACKUP_NAME"
checkVariable "${BACKUP_DIR}" "BACKUP_DIR"
checkVariable "${NUMBER_OF_BACKUPS}" "NUMBER_OF_BACKUPS"
# Replace all "_" to "-"
BACKUP_NAME="${BACKUP_NAME//_/-}"

# Check if backup dir exists
if [ ! -d "$BACKUP_DIR" ]; then
    errorMessage "Backup directory does not exist"
fi
infoMessage "Environment variables checks completed"

# Check if backup dir is empty
if [ ! "$(ls -A "${BACKUP_DIR}")" ]; then
    errorMessage "Backup directory is empty"
fi

# Check if s3cmd is installed
if ! command -v s3cmd > /dev/null 2>&1; then
    errorMessage "s3cmd could not be found"
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
        errorMessage "Could not create bucket"
    fi
    infoMessage "Bucket created successfully"
else
    infoMessage "Bucket already exists"
fi

# Create temp dir
infoMessage "Creating temp dir"
TMP_DIR=$(mktemp -d)

# Copy to temp dir
infoMessage "Coping files to temp dir"
if ! cp -a ./* ${TMP_DIR}; then
    errorMessage "Could not copy to temp dir"
fi
infoMessage "Copy to temp dir was successfully"

cd ${TMP_DIR}

# Create tar.gz file
infoMessage "Creating backup file"
if ! tar -czf "/tmp/${BACKUP_NAME}_${CURRENT_DATE}.tar.gz" .; then
    errorMessage "Could not create tar.gz file"
fi
infoMessage "Backup file created successfully"

# Upload backup file to s3
infoMessage "Uploading backup file to S3"
if ! s3cmd put "/tmp/${BACKUP_NAME}_${CURRENT_DATE}.tar.gz" s3://"${S3_BUCKET}" > /dev/null; then
    errorMessage "Could not upload backup file to S3"
fi
infoMessage "Backup uploaded successfully"

# Delete old backups 
infoMessage "Deleting old backups"
FILE_LIST=()
while IFS= read -r line; do
    FILE_LIST+=("$line")
done < <(s3cmd ls --host="${DEFAULT_URL_PREFIX}://${S3_ENDPOINT#*.}" s3://"${S3_ENDPOINT%%.*}"/"${S3_BUCKET}/" | awk 'NR>1 && $2 !~ /DIR/ && $4 ~ /'"${BACKUP_NAME}"'_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\.tar\.gz$/ {print $NF}')
NUMBER_OF_CURRENT_BACKUPS=${#FILE_LIST[@]}
if [[ "${NUMBER_OF_CURRENT_BACKUPS}" -gt "${NUMBER_OF_BACKUPS}" ]]; then
    OLD_FILES_TO_DELETE=$((NUMBER_OF_CURRENT_BACKUPS-NUMBER_OF_BACKUPS))
    for ((i=0; i<"${OLD_FILES_TO_DELETE}"; i++)); do
        s3cmd del --host="${DEFAULT_URL_PREFIX}://${S3_ENDPOINT#*.}" "${FILE_LIST[$i]}"
    done
    infoMessage "Deleted $OLD_FILES_TO_DELETE old backups"
else
    infoMessage "Not deleting any of the backups"
fi

infoMessage "Deleting local create file"
if [ -f "/tmp/${BACKUP_NAME}_${CURRENT_DATE}.tar.gz" ]; then
    rm -f "/tmp/${BACKUP_NAME}_${CURRENT_DATE}.tar.gz"
    infoMessage "Successfully deleted"
else
    errorMessage "Local file does not exits"
fi

rm -rf ${TMP_DIR}

infoMessage "Backup completed"