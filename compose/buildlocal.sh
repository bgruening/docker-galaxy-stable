#!/bin/bash
set -x

ANSIBLE_REPO=galaxyproject/ansible-galaxy-extras
ANSIBLE_RELEASE=53880c97d9650e0006216a100090ef916af2690d

GALAXY_RELEASE=release_17.01
GALAXY_REPO=galaxyproject/galaxy

#docker build -t quay.io/bgruening/galaxy ../galaxy/
#docker tag quay.io/bgruening/galaxy quay.io/bgruening/galaxy:compose
docker build --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/bgruening/galaxy-base ./galaxy-base/
docker tag quay.io/bgruening/galaxy-base quay.io/bgruening/galaxy-base:compose
docker build --build-arg GALAXY_REPO=$GALAXY_REPO --build-arg GALAXY_RELEASE=$GALAXY_RELEASE -t quay.io/bgruening/galaxy-init ./galaxy-init/
docker tag quay.io/bgruening/galaxy-init quay.io/bgruening/galaxy-init:compose
docker build -t quay.io/bgruening/galaxy-web ./galaxy-web/
docker tag quay.io/bgruening/galaxy-web quay.io/bgruening/galaxy-web:compose
docker build --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/galaxy/proftpd ./galaxy-proftpd
docker tag quay.io/galaxy/proftpd quay.io/galaxy/proftpd:compose
docker build -t quay.io/galaxy/postgres ./galaxy-postgres
docker tag quay.io/galaxy/postgres quay.io/galaxy/postgres:compose
docker build -t quay.io/galaxy/slurm ./galaxy-slurm
docker tag quay.io/galaxy/slurm quay.io/galaxy/slurm:compose

docker tag quay.io/bgruening/galaxy-web quay.io/bgruening/galaxy
