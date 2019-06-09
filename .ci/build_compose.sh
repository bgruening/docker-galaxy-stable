#!/usr/bin/env bash

set -o errexit

pip install docker-compose galaxy-parsec --user

export DOCKER_RUN_CONTAINER="galaxy-web"
INSTALL_REPO_ARG="--galaxy-url http://localhost:80"
SAMPLE_TOOLS=/export/config/sample_tool_list.yaml

pushd $COMPOSE_DIR

# For build script
export CONTAINER_REGISTRY=quay.io/
export CONTAINER_USER=bgruening
./build-orchestration-images.sh --no-push --condor --grafana --slurm --k8s

cat ./tags-for-compose-to-source.sh
source ./tags-for-compose-to-source.sh

container_size_check   quay.io/bgruening/galaxy-base:$TAG               350 
container_size_check   quay.io/bgruening/galaxy-web:$TAG                650
container_size_check   quay.io/bgruening/galaxy-htcondor-base:$TAG      280

export COMPOSE_PROJECT_NAME=galaxy_compose
docker-compose up -d

until docker-compose exec galaxy-web ps -fC uwsgi
do
  echo "sleeping for 20 seconds"
  sleep 20
  docker-compose logs --tail 10
done

# back to the root of the repo
popd

