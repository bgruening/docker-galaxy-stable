#!/usr/bin/env bash

set -o errexit

echo '#### Start compose Slurm testing ####'

bash .ci/cleanup.sh

source .ci/set_env.sh
source .ci/functions.sh

# The compose file recognises ENV vars to change the defaul behavior
pushd ${COMPOSE_DIR}
ln -sf .env_slurm .env
popd

# start building this repo
#git submodule update --init --recursive
#sudo chown 1450 /tmp && sudo chmod a=rwx /tmp

source .ci/build_compose.sh

echo "Stopping HT-Condor containers"
docker-compose stop galaxy-htcondor galaxy-htcondor-executor galaxy-htcondor-executor-big
sleep 30

docker-compose logs --tail 50
docker ps


sleep 10
docker_exec_run shed-tools install -g "http://localhost:80" -a admin -t "$SAMPLE_TOOLS"

