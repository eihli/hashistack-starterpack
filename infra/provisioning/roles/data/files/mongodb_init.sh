#!/usr/bin/env sh
set -euo pipefail

MONGO_DATA=${MONGO_DATA:-"/mnt/data/"}
POSTGRES_USER=${POSTGRES_USER:-"dev"}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"dev"}

docker run \
    --name mongodb \
    -e MONGO_INITDB_ROOT_USERNAME=dev
    -e MONGO_INITDB_ROOT_PASSWORD=dev
    -v $MONGO_DATA:/data/db \
    -p 127.0.0.1:5432:5432 \
    darklimericks-db
