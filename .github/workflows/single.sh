#!/bin/bash
set -ex

export GALAXY_HOME=/home/galaxy
export GALAXY_USER=admin@galaxy.org
export GALAXY_USER_EMAIL=admin@galaxy.org
export GALAXY_USER_PASSWD=password
export BIOBLEND_GALAXY_API_KEY=fakekey
export BIOBLEND_GALAXY_URL=http://localhost:8080

sudo apt-get update -qq
#sudo apt-get install docker-ce --no-install-recommends -y -o Dpkg::Options::="--force-confmiss" -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew"
sudo apt-get install sshpass --no-install-recommends -y

pip3 install ephemeris

docker --version
docker info

# start building this repo
git submodule update --init --recursive
sudo chown 1450 /tmp && sudo chmod a=rwx /tmp

## define a container size check function, first parameter is the container name, second the max allowed size in MB
container_size_check () {

    # check that the image size is not growing too much between releases
    # the 19.05 monolithic image was around 1.500 MB
    size="${docker image inspect $1 --format='{{.Size}}'}"
    size_in_mb=$(($size/(1024*1024)))
    if [[ $size_in_mb -ge $2 ]]
    then
        echo "The new compiled image ($1) is larger than allowed. $size_in_mb vs. $2"
        sleep 2
        #exit
    fi
}

export WORKING_DIR=${GITHUB_WORKSPACE:-$PWD}

export DOCKER_RUN_CONTAINER="quay.io/bgruening/galaxy"
SAMPLE_TOOLS=$GALAXY_HOME/ephemeris/sample_tool_list.yaml
cd "$WORKING_DIR"
docker build -t quay.io/bgruening/galaxy galaxy/
#container_size_check   quay.io/bgruening/galaxy  1500

mkdir local_folder
docker run -d -p 8080:80 -p 8021:21 -p 8022:22 \
    --name galaxy \
    --privileged=true \
    -v "$(pwd)/local_folder:/export/" \
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
      cd "$WORKING_DIR"
      docker exec galaxy "$@"
}
docker_exec_run() {
   cd "$WORKING_DIR"
   docker run quay.io/bgruening/galaxy "$@"
}
docker_run() {
   cd "$WORKING_DIR"
   docker run "$@"
}

docker ps

# Test submitting jobs to an external slurm cluster
cd "${WORKING_DIR}/test/slurm/" && bash test.sh && cd "$WORKING_DIR"

# Test submitting jobs to an external gridengine cluster
# TODO 19.05, need to enable this again!
# - cd $WORKING_DIR/test/gridengine/ && bash test.sh && cd $WORKING_DIR

echo 'Waiting for Galaxy to come up.'
galaxy-wait -g $BIOBLEND_GALAXY_URL --timeout 300

curl -v --fail $BIOBLEND_GALAXY_URL/api/version

# Test self-signed HTTPS
docker_run -d --name httpstest -p 443:443 -e "USE_HTTPS=True" $DOCKER_RUN_CONTAINER
# TODO 19.05
# - sleep 90s && curl -v -k --fail https://127.0.0.1:443/api/version
#- echo | openssl s_client -connect 127.0.0.1:443 2>/dev/null | openssl x509 -issuer -noout| grep selfsigned

docker logs httpstest && docker stop httpstest && docker rm httpstest

# Test FTP Server upload
date > time.txt
# FIXME passive mode does not work, it would require the container to run with --net=host
#curl -v --fail -T time.txt ftp://localhost:8021 --user $GALAXY_USER:$GALAXY_USER_PASSWD || true
# Test FTP Server get
#curl -v --fail ftp://localhost:8021 --user $GALAXY_USER:$GALAXY_USER_PASSWD

# Test CVMFS
docker_exec bash -c "service autofs start"
docker_exec bash -c "cvmfs_config chksetup"
docker_exec bash -c "ls /cvmfs/data.galaxyproject.org/byhand"

# Test SFTP Server
sshpass -p $GALAXY_USER_PASSWD sftp -v -P 8022 -o User=$GALAXY_USER -o "StrictHostKeyChecking no" -O "HostKeyAlgorithms=+ssh-rsa" localhost <<< $'put time.txt'

# Run a ton of BioBlend test against our servers.
cd "$WORKING_DIR/test/bioblend/" && . ./test.sh && cd "$WORKING_DIR/"

# not working anymore in 18.01
# executing: /galaxy_venv/bin/uwsgi --yaml /etc/galaxy/galaxy.yml --master --daemonize2 galaxy.log --pidfile2 galaxy.pid  --log-file=galaxy_install.log --pid-file=galaxy_install.pid
# [uWSGI] getting YAML configuration from /etc/galaxy/galaxy.yml
# /galaxy_venv/bin/python: unrecognized option '--log-file=galaxy_install.log'
# getopt_long() error
# cat: galaxy_install.pid: No such file or directory
# tail: cannot open ‘galaxy_install.log’ for reading: No such file or directory
#- |
#  if [ "${COMPOSE_SLURM}" ] || [ "${KUBE}" ] || [ "${COMPOSE_CONDOR_DOCKER}" ] || [ "${COMPOSE_SLURM_SINGULARITY}" ]
#  then
#    # Test without install-repository wrapper
#      sleep 10
#      docker_exec_run bash -c 'cd $GALAXY_ROOT && python ./scripts/api/install_tool_shed_repositories.py --api admin -l http://localhost:80 --url https://toolshed.g2.bx.psu.edu -o devteam --name cut_columns --panel-section-name BEDTools'
#  fi


# Test the 'new' tool installation script
docker_exec install-tools "$SAMPLE_TOOLS"
# Test the Conda installation
docker_exec_run bash -c 'export PATH=$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR/_conda/bin/:$PATH && conda --version && conda install samtools -c bioconda --yes'


docker stop galaxy
docker rm -f galaxy
docker rmi -f $DOCKER_RUN_CONTAINER
