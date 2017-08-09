#!/bin/bash
set -x -e

: ${ANSIBLE_REPO:="galaxyproject/ansible-galaxy-extras"}
: ${ANSIBLE_RELEASE:="master"}

: ${GALAXY_RELEASE:="dev"}
: ${GALAXY_REPO:="galaxyproject/galaxy"}

: ${TAG_SUFFIX:=""}


docker build --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/bgruening/galaxy-base$TAG_SUFFIX ./galaxy-base/
docker build --build-arg GALAXY_REPO=$GALAXY_REPO --build-arg GALAXY_RELEASE=$GALAXY_RELEASE -t quay.io/bgruening/galaxy-init$TAG_SUFFIX ./galaxy-init/

# Build the Galaxy web-application container
docker build -t quay.io/bgruening/galaxy-web$TAG_SUFFIX ./galaxy-web/

docker build --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/bgruening/galaxy-proftpd$TAG_SUFFIX ./galaxy-proftpd

# Build the postgres container
docker build -t quay.io/bgruening/galaxy-postgres$TAG_SUFFIX ./galaxy-postgres

# The SLURM cluster
docker build -t quay.io/bgruening/galaxy-slurm$TAG_SUFFIX ./galaxy-slurm

# we build a common HTCondor and derive from that laster
docker build -t quay.io/bgruening/galaxy-htcondor-base$TAG_SUFFIX ./galaxy-htcondor-base
docker build -t quay.io/bgruening/galaxy-htcondor$TAG_SUFFIX ./galaxy-htcondor
docker build -t quay.io/bgruening/galaxy-htcondor-executor$TAG_SUFFIX ./galaxy-htcondor-executor

