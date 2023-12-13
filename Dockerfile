FROM registry.suse.com/bci/bci-base:15.5

WORKDIR /backup

ENV BACKUP_DIR=/backup \
S3_BUCKET= \
S3_ENDPOINT= \
S3_ACCESS_KEY= \
S3_SECRET_KEY= \
S3_REGION= \
S3_SSL=true \
BACKUP_NAME=backup

RUN zypper ref && zypper -n in tar gzip python3-pip
RUN pip install s3cmd

COPY --chmod=0555 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]