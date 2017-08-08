#!/bin/bash
set -x -e

ANSIBLE_REPO=galaxyproject/ansible-galaxy-extras
<<<<<<< HEAD
ANSIBLE_RELEASE=master
=======
ANSIBLE_RELEASE=ae53d17aee347ae551e387c549b1963eb1a5dbae
>>>>>>> b72ff9ed5eff2e2190de0fb11cb33f08dac89317

GALAXY_RELEASE=dev
GALAXY_REPO=galaxyproject/galaxy

docker build --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/bgruening/galaxy-base ./galaxy-base/
docker build --build-arg GALAXY_REPO=$GALAXY_REPO --build-arg GALAXY_RELEASE=$GALAXY_RELEASE -t quay.io/bgruening/galaxy-init ./galaxy-init/

# Build the Galaxy web-application container
docker build -t quay.io/bgruening/galaxy-web ./galaxy-web/

docker build --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t quay.io/galaxy/proftpd ./galaxy-proftpd

# Build the postgres container
docker build -t quay.io/galaxy/postgres ./galaxy-postgres

# The SLURM cluster
docker build -t quay.io/galaxy/slurm ./galaxy-slurm

# we build a common HTCondor and derive from that laster
docker build -t quay.io/bgruening/galaxy-htcondor-base ./galaxy-htcondor-base
docker build -t quay.io/bgruening/galaxy-htcondor ./galaxy-htcondor
docker build -t quay.io/bgruening/galaxy-htcondor-executor ./galaxy-htcondor-executor

