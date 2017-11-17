#!/bin/bash
set -x -e

ANSIBLE_REPO=galaxyproject/ansible-galaxy-extras
ANSIBLE_RELEASE=1d90fdc073d8a94278366290d20f17caae059fbb

GALAXY_RELEASE=release_17.09
GALAXY_REPO=galaxyproject/galaxy

DOCKER_ADDITIONAL_BUILD_ARGS="--no-cache"

docker pull postgres

docker build $DOCKER_ADDITIONAL_BUILD_ARGS --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/bgruening/galaxy-base ./galaxy-base/
docker build $DOCKER_ADDITIONAL_BUILD_ARGS --build-arg GALAXY_REPO=$GALAXY_REPO --build-arg GALAXY_RELEASE=$GALAXY_RELEASE -t quay.io/bgruening/galaxy-init ./galaxy-init/

# Build the Galaxy web-application container
docker build $DOCKER_ADDITIONAL_BUILD_ARGS -t quay.io/bgruening/galaxy-web ./galaxy-web/

docker build $DOCKER_ADDITIONAL_BUILD_ARGS --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/galaxy/proftpd ./galaxy-proftpd

# Build the postgres container
docker build -t quay.io/galaxy/postgres ./galaxy-postgres

# The SLURM cluster
docker build -t quay.io/galaxy/slurm ./galaxy-slurm

# we build a common HTCondor and derive from that laster
docker build -t quay.io/bgruening/galaxy-htcondor-base ./galaxy-htcondor-base
docker build -t quay.io/bgruening/galaxy-htcondor ./galaxy-htcondor
docker build -t quay.io/bgruening/galaxy-htcondor-executor ./galaxy-htcondor-executor

