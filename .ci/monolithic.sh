#!/usr/bin/env bash

set -o errexit

bash .ci/cleanup.sh

source .ci/set_env.sh
source .ci/functions.sh

export DOCKER_RUN_CONTAINER="quay.io/bgruening/galaxy"
INSTALL_REPO_ARG=""

cd "$WORKING_DIR"
docker build -t quay.io/bgruening/galaxy galaxy/

container_size_check   quay.io/bgruening/galaxy  1550

mkdir local_folder
docker run -d -p 8080:80 -p 8021:21 -p 8022:22 \
    --name galaxy \
    --privileged=true \
    -v `pwd`/local_folder:/export/ \
    -e GALAXY_CONFIG_ALLOW_USER_DATASET_PURGE=True \
    -e GALAXY_CONFIG_ALLOW_LIBRARY_PATH_PASTE=True \
    -e GALAXY_CONFIG_ENABLE_USER_DELETION=True \
    -e GALAXY_CONFIG_ENABLE_BETA_WORKFLOW_MODULES=True \
    -v /tmp/:/tmp/ \
    quay.io/bgruening/galaxy

sleep 30
docker logs galaxy

# Define start functions
docker_exec() {
  cd $WORKING_DIR
  docker exec -t -i galaxy "$@"
}
docker_exec_run() {
  cd $WORKING_DIR
  docker run quay.io/bgruening/galaxy "$@"
}
docker_run() {
  cd $WORKING_DIR
  docker run "$@"
}

docker ps

echo '#### Test submitting jobs to an external slurm cluster ####'
pushd $WORKING_DIR/test/slurm/
bash test.sh
popd
#cd $WORKING_DIR

# Test submitting jobs to an external gridengine cluster
# This test is not testing compose, thus disabled
# TODO 19.05, need to enable this again!
echo "skip SGE test, fix me"
# cd $TRAVIS_BUILD_DIR/test/gridengine/ && bash test.sh && cd $WORKING_DIR

echo '#### Start .ci/testing.sh ####'
source .ci/testing.sh

exit(1)

echo '### Run a ton of BioBlend test against our servers ####'
pushd $WORKING_DIR/test/bioblend/
source ./test.sh 'monolithic'
popd ##cd $WORKING_DIR/


echo '#### Test tool installation ####'
docker_exec_run install-tools "$SAMPLE_TOOLS"

bash .ci/cleanup.sh
