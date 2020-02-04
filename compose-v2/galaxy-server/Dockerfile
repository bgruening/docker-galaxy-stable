FROM buildpack-deps:19.10 as build_base

ARG GALAXY_RELEASE=release_19.09
ARG GALAXY_REPO=https://github.com/galaxyproject/galaxy

ENV EXPORT_DIR=/export \
    GALAXY_ROOT=/galaxy \
    HTCONDOR_ROOT=/opt/htcondor

ENV GALAXY_STATIC_DIR=$GALAXY_ROOT/static \
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

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && mkdir $GALAXY_HOME \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME

FROM build_base as build_miniconda
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
    && conda clean --packages -t -i \
    && find / -name '*.pyc' -delete | true

FROM build_base as build_galaxy
# Install Galaxy
RUN apt update && apt install --no-install-recommends python-dev python-pip -y && rm -rf /var/lib/apt/lists/* \
    && mkdir "${GALAXY_ROOT}" \
    && curl -L -s $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT \
    && cd $GALAXY_ROOT \
    && ./scripts/common_startup.sh \
    && . $GALAXY_ROOT/.venv/bin/activate && pip install psycopg2 \
    # Fix as cheetah was missing C library first
    && pip uninstall cheetah -y \
    && pip install cheetah \
    && deactivate \
    && find / -name '*.pyc' -delete | true \
    && rm -rf client contrib doc test test-data .venv/lib/node_modules .venv/src/node-v10.13.0-linux-x64 \
              .venv/include/node .venv/bin/node .venv/bin/nodeenv

FROM ubuntu:19.10 as final

# Install HTCondor
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install --no-install-recommends htcondor -y \
    && rm /etc/condor/condor_config.local

# Install CVMFS
RUN apt update \
    && apt install wget lsb-release -y \
    && wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb \
    && dpkg -i cvmfs-release-latest_all.deb \
    && rm -f cvmfs-release-latest_all.deb \
    && apt update \
    && apt install --no-install-recommends cvmfs -y \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /srv/cvmfs
COPY files/cvmfs/default.local /etc/cvmfs/default.local
COPY files/cvmfs/galaxyproject.org.conf /etc/cvmfs/domain.d/galaxyproject.org.conf
COPY files/cvmfs/data.galaxyproject.org.pub /etc/cvmfs/keys/data.galaxyproject.org.pub

# Install remaining dependencies
RUN apt update && apt install --no-install-recommends ca-certificates netcat libpq-dev mercurial libgomp1  -y \
    && rm -rf /var/lib/apt/lists/*

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

COPY --from=build_galaxy ${GALAXY_ROOT} ${GALAXY_ROOT}
COPY --from=build_miniconda ${GALAXY_CONFIG_TOOL_DEPENDENCY_DIR} ${GALAXY_CONFIG_TOOL_DEPENDENCY_DIR}
COPY --from=build_miniconda ${GALAXY_HOME} ${GALAXY_HOME}
COPY --from=build_miniconda /etc/profile.d/conda.sh /etc/profile.d/conda.sh

# Set permissions
RUN groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $GALAXY_ROOT $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR /etc/profile.d/conda.sh

COPY ./files/job_conf.xml ${GALAXY_CONFIG_DIR}/job_conf.xml
COPY ./files/galaxy.yml /${GALAXY_CONFIG_DIR}/galaxy.yml
COPY ./files/start.sh /usr/bin/start.sh

# Some helpful scripts
COPY ./files/create_galaxy_user.py /usr/local/bin/create_galaxy_user.py

EXPOSE 80

ENTRYPOINT "/usr/bin/start.sh"
