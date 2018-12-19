#!/bin/bash
if [ "${COMPOSE_SLURM}" ] || [ "${KUBE}" ] || [ "${COMPOSE_CONDOR_DOCKER}" ] || [ "${COMPOSE_SLURM_SINGULARITY}" ]
then
    docker_exec bash -c 'cd /home/galaxy ;
    . /galaxy_venv/bin/activate ;
    wget https://github.com/galaxyproject/bioblend/archive/master.tar.gz && tar xfz master.tar.gz ;
    cd bioblend-master ;
    pip install --upgrade "tox>=1.8.0" "pep8<=1.6.2" ;
    python setup.py install ;
    sed -i.bak "s/commands.*$/commands =/" tox.ini ;
    sed -i.bak2 "s/GALAXY_VERSION/GALAXY_VERSION BIOBLEND_TEST_JOB_TIMEOUT/" tox.ini ;
    export TOX_ENV=py27 ;
    export BIOBLEND_GALAXY_API_KEY=admin ;
    export BIOBLEND_GALAXY_URL=http://galaxy ;
    export BIOBLEND_TEST_JOB_TIMEOUT="240";
    cd /home/galaxy/bioblend-master ;
    tox -e $TOX_ENV -- -k "not test_download_dataset and not test_upload_from_galaxy_filesystem and not test_get_datasets and not test_datasets_from_fs and not test_existing_history and not test_new_history and not test_params and not test_tool_dependency_install and not test_download_history and not test_export_and_download"'

else
    docker build -t bioblend_test .
    docker run -it --link galaxy -v /tmp/:/tmp/ bioblend_test
fi
