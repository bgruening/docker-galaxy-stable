#!/bin/bash
set -x

docker build -t quay.io/bgruening/galaxy ../galaxy/
docker tag quay.io/bgruening/galaxy quay.io/bgruening/galaxy:compose
docker build -t quay.io/galaxy/proftpd ./proftpd
docker tag quay.io/galaxy/proftpd quay.io/galaxy/proftpd:compose
docker build -t quay.io/galaxy/postgres ./postgres-galaxy
docker tag quay.io/galaxy/postgres quay.io/galaxy/postgres:compose
docker build -t quay.io/galaxy/slurm ./slurm-galaxy
docker tag quay.io/galaxy/slurm quay.io/galaxy/slurm:compose
