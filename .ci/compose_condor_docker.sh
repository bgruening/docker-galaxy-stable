#!/usr/bin/env bash

set -o errexit

echo '#### Start compose condor Docker testing ####'

bash .ci/cleanup.sh

source .ci/set_env.sh
source .ci/functions.sh

# The compose file recognises ENV vars to change the defaul behavior
pushd ${COMPOSE_DIR}
ln -sf .env_htcondor_docker .env

# Galaxy needs to a full path for the the jobs, in- and outputs.
# Do we want to run each job in it's own container and this container uses the host
# container engine (not Docker in Docker) then the path to all files inside and outside
# of the container needs to be the same.
sudo mkdir /export
sudo chmod 777 /export
sudo chown 1450:1450 /export

# start building this repo
#git submodule update --init --recursive
#sudo chown 1450 /tmp && sudo chmod a=rwx /tmp

popd
source .ci/build_compose.sh
pushd ${COMPOSE_DIR}

source ./tags-for-compose-to-source.sh

echo "Stopping SLURM container"
docker-compose stop galaxy-slurm
sleep 30

docker-compose logs --tail 50
docker ps

sleep 10
docker_exec_run shed-tools install -g "http://localhost:80" -a admin -t "$SAMPLE_TOOLS"

popd

echo '#### Start .ci/testing.sh ####'
source .ci/testing.sh

echo '#### Run a ton of BioBlend test against our servers ####'
pushd $WORKING_DIR/test/bioblend/
source ./test.sh 'compose'
popd

pushd ${COMPOSE_DIR}
docker-compose down
popd

