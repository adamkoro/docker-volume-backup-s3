#  docker-volume-backup-s3
[![Build Status](https://drone.adamkoro.com/api/badges/adamkoro/docker-volume-backup-s3/status.svg)](https://drone.adamkoro.com/adamkoro/docker-volume-backup-s3)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/adamkoro/docker-volume-backup)
![Docker Pulls](https://img.shields.io/docker/pulls/adamkoro/docker-volume-backup)
![Docker Image Version (latest by date)](https://img.shields.io/docker/v/adamkoro/docker-volume-backup)
![Docker Stars](https://img.shields.io/docker/stars/adamkoro/docker-volume-backup)
![GitHub](https://img.shields.io/github/license/adamkoro/docker-volume-backup-s3)

Simple docker volume backup to S3.

Create tar.gz file from docker volume and upload it to S3.

This image is only for backup. It doesn't have any restore functionality.

## Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| `S3_BUCKET` | S3 bucket name | `backup` |
| `S3_ENDPOINT` | S3 endpoint | `empty` |
| `S3_ACCESS_KEY` | S3 access key | `empty` |
| `S3_SECRET_KEY` | S3 secret key | `empty` |
| `S3_REGION` | S3 region | `empty` |
| `S3_SSL` | S3 ssl usage | `true` |
| `BACKUP_NAME` | Name of the tar.gz file | `backup` |
| `NUMBER_OF_BACKUPS` | Number of the files in keep | `2` |

## Usage

**IMPORTANT**: You need to mount volume with backup files to `/backup` directory. Make sure mounted `read-only` mode.

Backup file name: `BACKUP_NAME_YYYY-MM-DD-HH-MM-SS.tar.gz` that's why you have to set `BACKUP_NAME` environment variable.

### Docker

```bash
docker run --rm -it -v /backup/:/backup -e S3_BUCKET=backup -e S3_ENDPOINT=minio.server.local -e S3_ACCESS_KEY=test -e S3_SECRET_KEY=test -e S3_REGION=home -e S3_SSL=true -e BACKUP_NAME=test-backup docker.io/adamkoro/docker-volume-backup:latest
```

### Docker Compose

```yaml
version: '3.7'
services:
  backup:
    image: docker.io/adamkoro/docker-volume-backup:latest
    volumes:
      - docker-tmp-backup/:/backup:ro
    environment:
      - S3_BUCKET=backup
      - S3_ENDPOINT=minio.server.local
      - S3_ACCESS_KEY=test
      - S3_SECRET_KEY=test
      - S3_REGION=home
      - S3_SSL=true
      - BACKUP_NAME=backup
volumes:
    docker-tmp-backup:
```

