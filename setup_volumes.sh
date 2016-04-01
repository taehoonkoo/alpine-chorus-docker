#!/usr/bin/env bash

id=$(docker create alpinedata/chorus)
mkdir -p ./data/chorus
docker cp $id:/chorus/config ./data/chorus/config
docker rm -v $id

id=$(docker create alpinedata/alpine:squashed)
mkdir -p ./data/alpine
docker cp $id:/home/alpine/ALPINE_DATA_REPOSITORY ./data/alpine/ALPINE_DATA_REPOSITORY
docker rm -v $id