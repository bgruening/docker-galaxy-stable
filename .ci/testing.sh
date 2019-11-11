#!/usr/bin/env bash

set -o errexit

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
date > time.txt && curl -v --fail -T time.txt ftp://localhost:8021 --user $GALAXY_USER:$GALAXY_USER_PASSWD || true

# Test FTP Server get
curl -v --fail ftp://localhost:8021 --user $GALAXY_USER:$GALAXY_USER_PASSWD

# Test CVMFS
docker_exec bash -c "service autofs start"
docker_exec bash -c "cvmfs_config chksetup"
docker_exec bash -c "ls /cvmfs/data.galaxyproject.org/byhand"

# Test SFTP Server
sshpass -p $GALAXY_USER_PASSWD sftp -v -P 8022 -o User=$GALAXY_USER -o "StrictHostKeyChecking no" localhost <<< $'put time.txt'

# Test the Conda installation
docker_exec_run bash -c 'export PATH=$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR/_conda/bin/:$PATH && conda --version && conda install samtools -c bioconda --yes'

