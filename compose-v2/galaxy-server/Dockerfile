FROM buildpack-deps:19.10 as build

ENV EXPORT_DIR=/export \
    GALAXY_ROOT=/galaxy \
    HTCONDOR_ROOT=/opt/htcondor

ENV GALAXY_RELEASE=${GALAXY_RELEASE:-release_19.05} \
    GALAXY_REPO=${GALAXY_REPO:-https://github.com/galaxyproject/galaxy} \
    GALAXY_STATIC_DIR=$GALAXY_ROOT/static \
    GALAXY_EXPORT=$EXPORT_DIR/galaxy \
    GALAXY_CONFIG_DIR=$GALAXY_ROOT/config \
    GALAXY_CONFIG_TOOL_DEPENDENCY_DIR=/tool_deps \
    GALAXY_CONFIG_TOOL_PATH=$GALAXY_ROOT/tools \
    GALAXY_VIRTUAL_ENV=$GALAXY_ROOT/.venv \
    GALAXY_DATABASE_PATH=$GALAXY_ROOT/database

ENV GALAXY_USER=galaxy \
    GALAXY_GROUP=galaxy \
    GALAXY_UID=1450 \
    GALAXY_GID=1450 \
    GALAXY_HOME=/home/galaxy

ENV GALAXY_CONDA_PREFIX=$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR/_conda \
    MINICONDA_VERSION=4.7.10

# TODO: CLEAN UP!!!!
# Install all needed dependencies

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && mkdir $GALAXY_HOME \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME

# Install Miniconda
RUN curl -s -L "https://repo.anaconda.com/miniconda/Miniconda2-${MINICONDA_VERSION}-Linux-x86_64.sh" > ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p $GALAXY_CONDA_PREFIX \
    && rm ~/miniconda.sh \
    && ln -s $GALAXY_CONDA_PREFIX/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". $GALAXY_CONDA_PREFIX/etc/profile.d/conda.sh" >> $GALAXY_HOME/.bashrc \
    && echo "conda activate base" >> $GALAXY_HOME/.bashrc \
    && export PATH=$GALAXY_CONDA_PREFIX/bin/:$PATH \
    && conda config --add channels defaults \
    && conda config --add channels bioconda \
    && conda config --add channels conda-forge \
    && conda install virtualenv pip ephemeris \
    && chown $GALAXY_GROUP:$GALAXY_USER -R $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR /etc/profile.d/conda.sh \
    && conda clean --packages -t -i \
    # cleanup dance
    && find $GALAXY_ROOT -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find $GALAXY_CONDA_PREFIX/ -name '*.pyc' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm

# Install Galaxy
RUN mkdir "${GALAXY_ROOT}" \
    && curl -L -s $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT \
    && chown -R $GALAXY_GROUP:$GALAXY_USER $GALAXY_ROOT \
    # cleanup dance
    && find $GALAXY_ROOT -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find $GALAXY_CONDA_PREFIX/ -name '*.pyc' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* /home/galaxy/.cache/ /home/galaxy/.npm

# Install Galaxy dependencies and delete unneeded afterwards
#COPY ./files/requirements.txt $GALAXY_ROOT/lib/galaxy/dependencies/pipfiles/default/pinned-requirements.txt
RUN apt update && apt install python-dev python-pip gcc -y \
    && cd $GALAXY_ROOT && ./scripts/common_startup.sh \
    && . $GALAXY_ROOT/.venv/bin/activate && pip install psycopg2 \
    # Fix as cheetah was missing C library first
    && pip uninstall cheetah -y \
    && pip install cheetah \
    && deactivate \
    && find $GALAXY_ROOT -name '*.pyc' -delete | true 

# Cleanup of unneeded files. TODO: Include in other statements
RUN cd $GALAXY_ROOT && rm -rf client doc test test-data .venv/lib/node_modules

# # Install HTCondor 
# RUN cd /tmp && wget http://parrot.cs.wisc.edu//symlink/20200102142623/8/8.8/8.8.7/e04b89a266a2bf2576c19d960ab1a002/condor-8.8.7-x86_64_Ubuntu18-stripped.tar.gz -O htcondor.tar.gz \
#     && tar -zxvf htcondor.tar.gz \
#     && mkdir "$HTCONDOR_ROOT" \
#     && chown "$GALAXY_USER:$GALAXY_GROUP" "$HTCONDOR_ROOT" \
#     && cd condor-8.8.7-x86_64_Ubuntu18-stripped \
#     && HOSTNAME=galaxy-server.local ./condor_install --install=. --owner="$GALAXY_USER" --install-dir="$HTCONDOR_ROOT" --local-dir=/opt/htcondor/var --type=submit

FROM ubuntu:19.10

#COPY --from=build /opt/htcondor /opt/htcondor
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install htcondor -y \
    && rm /etc/condor/condor_config.local

ENV EXPORT_DIR=/export \
    GALAXY_ROOT=/galaxy \
    HTCONDOR_ROOT=/opt/htcondor

ENV GALAXY_RELEASE=${GALAXY_RELEASE:-release_19.05} \
    GALAXY_REPO=${GALAXY_REPO:-https://github.com/galaxyproject/galaxy} \
    GALAXY_STATIC_DIR=$GALAXY_ROOT/static \
    GALAXY_EXPORT=$EXPORT_DIR/galaxy \
    GALAXY_CONFIG_DIR=$GALAXY_ROOT/config \
    GALAXY_CONFIG_TOOL_DEPENDENCY_DIR=/tool_deps \
    GALAXY_CONFIG_TOOL_PATH=$GALAXY_ROOT/tools \
    GALAXY_VIRTUAL_ENV=$GALAXY_ROOT/.venv \
    GALAXY_DATABASE_PATH=$GALAXY_ROOT/database

ENV GALAXY_USER=galaxy \
    GALAXY_GROUP=galaxy \
    GALAXY_UID=1450 \
    GALAXY_GID=1450 \
    GALAXY_HOME=/home/galaxy

ENV GALAXY_CONFIG_FILE=$GALAXY_CONFIG_DIR/galaxy.yml

COPY --from=build ${GALAXY_ROOT} ${GALAXY_ROOT}
COPY --from=build ${GALAXY_CONFIG_TOOL_DEPENDENCY_DIR} ${GALAXY_CONFIG_TOOL_DEPENDENCY_DIR}
COPY --from=build ${GALAXY_HOME} ${GALAXY_HOME}

RUN apt update && apt install --no-install-recommends netcat libpq-dev mercurial libgomp1 -y \
    && groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $GALAXY_ROOT $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR

COPY ./files/job_conf.xml /galaxy/config/job_conf.xml
COPY ./files/galaxy.yml /galaxy/config/galaxy.yml
COPY ./files/start.sh /usr/bin/start.sh

# Some helpful scripts
COPY ./files/create_galaxy_user.py /usr/local/bin/create_galaxy_user.py

# Last cleanup before shipping
RUN find / -name '*.pyc' -delete | true

EXPOSE 80

ENTRYPOINT "/usr/bin/start.sh"