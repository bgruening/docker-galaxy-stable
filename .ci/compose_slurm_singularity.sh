#!/usr/bin/env bash

set -o errexit

source .ci/set_env.sh
source .ci/functions.sh

# The compose file recognises ENV vars to change the defaul behavior
cd ${COMPOSE_DIR}
ln -sf .env_slurm_singularity .env

# start building this repo
#git submodule update --init --recursive
#sudo chown 1450 /tmp && sudo chmod a=rwx /tmp

bash .ci/build_compose.sh

# turn down the htcondor services
echo "Stopping HT-Condor containers"
docker-compose stop galaxy-htcondor galaxy-htcondor-executor galaxy-htcondor-executor-big
sleep 30


# docker-compose is already started and has pre-populated the /export dir
# we now turn it down again and copy in an example tool with tool_conf.xml and
# a test singularity image. If we copy this from the beginning, the magic Docker Galax startup
# script will not work as it detects something in /export/
echo "Downloading Singularity test files and images."
docker-compose exec galaxy-web    mkdir -p /export/database/container_images/singularity/mulled/
docker-compose exec galaxy-web    curl -L -o /export/database/container_images/singularity/mulled/samtools:1.4.1--0 https://github.com/bgruening/singularity-galaxy-tests/raw/master/samtools:1.4.1--0
docker-compose exec galaxy-web    curl -L -o /export/cat_tool_conf.xml https://github.com/bgruening/singularity-galaxy-tests/raw/master/cat_tool_conf.xml
docker-compose exec galaxy-web    curl -L -o /export/cat.xml https://github.com/bgruening/singularity-galaxy-tests/raw/master/cat.xml
docker-compose exec galaxy-web    chown 1450:1450 /export/cat* /export/database/container_images/ -R
docker-compose down
sleep 20
rm .env
ln -sf .env_slurm_singularity2 .env

docker-compose up -d

until docker-compose exec galaxy-web ps -fC uwsgi
do
  echo "Starting up Singularity test container: sleeping for 40 seconds"
  sleep 40
  docker-compose logs
done
docker-compose logs galaxy-web
sleep 30
docker-compose logs galaxy-web
sleep 30
docker-compose logs galaxy-web
echo "waiting until Galaxy is up"
docker ps
pip show ephemeris
which galaxy-wait
#galaxy-wait -g $BIOBLEND_GALAXY_URL --timeout 60 -v
#docker-compose logs galaxy-web
#galaxy-wait -g $BIOBLEND_GALAXY_URL --timeout 60 -v
docker-compose logs galaxy-web
sleep 500
docker-compose logs
echo "parsec init"
parsec init --api_key admin --url $BIOBLEND_GALAXY_URL
HISTORY_ID=$(parsec histories create_history | jq .id -r)
DATASET_ID=$(parsec tools paste_content 'asdf' $HISTORY_ID | jq '.outputs[0].id' -r)
OUTPUT_ID=$(parsec tools run_tool $HISTORY_ID cat '{"input1": {"src": "hda", "id": "'$DATASET_ID'"}}' | jq '.outputs | .[0].id' -r)
sleep 10
echo "run parsec jobs show_job"
parsec jobs show_job --full_details $OUTPUT_ID
# TODO: find a way to get a log trace that this tool actually was running with singularity
#parsec jobs show_job --full_details $OUTPUT_ID | jq .stderr | grep singularity



docker-compose logs --tail 50
docker ps

sleep 10
docker_exec_run shed-tools install -g "http://localhost:80" -a admin -t "$SAMPLE_TOOLS"

