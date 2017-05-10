#!/bin/bash
if [ "${COMPOSE_SLURM}" ] || [ "${KUBE}" ] || [ "${COMPOSE_CONDOR_DOCKER}" ]
then
    docker_exec bash -c 'cd /home/galaxy ;
    . /galaxy_venv/bin/activate ;
    wget https://github.com/galaxyproject/bioblend/archive/master.tar.gz && tar xfz master.tar.gz ;
    cd bioblend-master ;
    pip install --upgrade "tox>=1.8.0" "pep8<=1.6.2" ;
    python setup.py install ;
    sed -i.bak "s/commands.*$/commands =/" tox.ini ;
    export TOX_ENV=py27 ;
    export BIOBLEND_GALAXY_API_KEY=admin ;
    export BIOBLEND_GALAXY_URL=http://galaxy ;
    cd /home/galaxy/bioblend-master ;
    tox -e $TOX_ENV -- -e "test_download_dataset|test_upload_from_galaxy_filesystem|test_get_datasets|test_datasets_from_fs|test_existing_history|test_new_history|test_params|test_download_history"'
else
    docker build -t bioblend_test .
    docker run -it --link galaxy -v /tmp/:/tmp/ bioblend_test
fi
