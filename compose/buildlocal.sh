#!/bin/bash
set -x

ANSIBLE_REPO=galaxyproject/ansible-galaxy-extras
ANSIBLE_RELEASE=ef50faa6b820353571a8ce7bf85258ec74584ebc

GALAXY_RELEASE=release_17.05
GALAXY_REPO=galaxyproject/galaxy

docker build --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/bgruening/galaxy-base ./galaxy-base/
docker build --build-arg GALAXY_REPO=$GALAXY_REPO --build-arg GALAXY_RELEASE=$GALAXY_RELEASE -t quay.io/bgruening/galaxy-init ./galaxy-init/
docker build -t quay.io/bgruening/galaxy-web ./galaxy-web/
docker build --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/galaxy/proftpd ./galaxy-proftpd
docker build -t quay.io/galaxy/postgres ./galaxy-postgres
docker build -t quay.io/galaxy/slurm ./galaxy-slurm

# we build a common HTCondor and derive from that laster
docker build -t quay.io/bgruening/galaxy-htcondor-base ./galaxy-htcondor-base
docker build -t quay.io/bgruening/galaxy-htcondor ./galaxy-htcondor
docker build -t quay.io/bgruening/galaxy-htcondor-executor ./galaxy-htcondor-executor

# Build the final web-application container
docker tag quay.io/bgruening/galaxy-web quay.io/bgruening/galaxy
