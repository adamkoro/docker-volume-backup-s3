FROM harbor.adamkoro.com/bci/bci-base:15.4

WORKDIR /backup

ENV BACKUP_DIR=/backup \
S3_BUCKET= \
S3_ENDPOINT= \
S3_ACCESS_KEY= \
S3_SECRET_KEY= \
S3_REGION= \
S3_SSL=true \
BACKUP_NAME=backup

RUN zypper ref && zypper -n in tar wget gzip
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc && install -o root -g root -m 755 mc /usr/local/bin/mc && rm mc

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]