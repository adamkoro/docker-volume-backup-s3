FROM registry.suse.com/bci/bci-base:15.6

WORKDIR /backup

RUN zypper ref && zypper -n in tar gzip awk python3-pip python3
RUN pip install s3cmd

ENV BACKUP_DIR=/backup \
NUMBER_OF_BACKUPS=2 \
S3_BUCKET= \
S3_ENDPOINT= \
S3_ACCESS_KEY= \
S3_SECRET_KEY= \
S3_REGION= \
S3_SSL=true \
BACKUP_NAME=backup

COPY --chmod=0555 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]