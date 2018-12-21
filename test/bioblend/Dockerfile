FROM quay.io/bgruening/galaxy

USER galaxy
WORKDIR /home/galaxy

RUN wget https://github.com/galaxyproject/bioblend/archive/master.tar.gz && tar xfz master.tar.gz && \
    cd bioblend-master && \
    export PATH=/tool_deps/_conda/bin/:$PATH && . activate galaxy_env && \
    pip install --upgrade "tox>=1.8.0" "pep8<=1.6.2" && \
    python setup.py install && \
    sed -i.bak "s/commands.*$/commands =/" tox.ini && \
    sed -i.bak2 "s/GALAXY_VERSION/GALAXY_VERSION BIOBLEND_TEST_JOB_TIMEOUT/" tox.ini

ENV TOX_ENV=py27 \
    BIOBLEND_GALAXY_API_KEY=admin \
    BIOBLEND_GALAXY_URL=http://galaxy \
    BIOBLEND_TEST_JOB_TIMEOUT="240"

CMD /bin/bash -c "export PATH=/tool_deps/_conda/bin/:$PATH && cd /home/galaxy/bioblend-master && tox -e $TOX_ENV -- -k 'not test_download_dataset and not test_upload_from_galaxy_filesystem and not test_get_datasets and not test_datasets_from_fs and not test_tool_dependency_install and not test_download_history and not test_export_and_download'"

# library tests, needs share /tmp filesystem
# * test_upload_from_galaxy_filesystem
# * test_get_datasets
# * test_datasets_from_fs
