FROM quay.io/bgruening/galaxy

USER galaxy
WORKDIR /home/galaxy

RUN . /galaxy_venv/bin/activate && \
    wget https://github.com/galaxyproject/bioblend/archive/v0.8.0.tar.gz && tar xfz v0.8.0.tar.gz && mv bioblend-0.8.0 bioblend && \
    cd bioblend && \
    pip install --upgrade "tox>=1.8.0" "pep8<=1.6.2" && \
    python setup.py install && \
    sed -i.bak "s/commands.*$/commands =/" tox.ini

ENV TOX_ENV=py27 \
    BIOBLEND_GALAXY_API_KEY=admin \
    BIOBLEND_GALAXY_URL=http://galaxy

CMD /bin/bash -c ". /galaxy_venv/bin/activate && cd /home/galaxy/bioblend && tox -e $TOX_ENV -- -e 'test_download_dataset|test_upload_file'"

# library tests, needs share /tmp filesystem
# * test_upload_from_galaxy_filesystem
# * test_get_datasets
# * test_datasets_from_fs
