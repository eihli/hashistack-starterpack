#!/usr/bin/env sh

# /data/db inside the docker instance,
# which will be the host_volume of mongodb-data at /opt/mongodb/data
# on the Nomad client
MONGO_DATA=${MONGO_DATA:-"/data/db/"}
MONGO_USERNAME=${MONGO_USERNAME:-"dev"}
MONGO_PASSWORD=${MONGO_PASSWORD:-"dev"}

sudo docker rm mongodb

sudo docker run \
    --name mongodb \
    -e MONGO_INITDB_ROOT_USERNAME=$MONGO_USERNAME \
    -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASSWORD \
    -e MONGO_DATA=$MONGO_DATA \
    -v $MONGO_DATA:/data/db \
    -p 127.0.0.1:5432:5432 \
    -d \
    mongo

sleep 1

sudo docker stop mongodb

touch /opt/mongodb/data/initialized
