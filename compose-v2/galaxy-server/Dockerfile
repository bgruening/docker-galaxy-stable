FROM buildpack-deps:18.04 as build_base

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
COPY ./files/common_cleanup.sh /usr/bin/common_cleanup.sh
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
    && /usr/bin/common_cleanup.sh

FROM build_base as build_galaxy
COPY ./files/common_cleanup.sh /usr/bin/common_cleanup.sh
# Install Galaxy
RUN apt update && apt install --no-install-recommends python-dev python-pip -y && rm -rf /var/lib/apt/lists/* \
    && mkdir "${GALAXY_ROOT}" \
    && curl -L -s $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT \
    && cd $GALAXY_ROOT \
    && ./scripts/common_startup.sh \
    && . $GALAXY_ROOT/.venv/bin/activate && pip install psycopg2 \
    # Fix as cheetah was missing C library first
    && pip uninstall cheetah -y \
    && pip install cheetah drmaa \
    && deactivate \
    && rm -rf .ci .circleci .coveragerc .gitignore .travis.yml CITATION CODE_OF_CONDUCT.md CONTRIBUTING.md CONTRIBUTORS.md \
              LICENSE.txt Makefile README.rst SECURITY_POLICY.md pytest.ini tox.ini \
              client contrib doc test test-data .venv/lib/node_modules .venv/src/node-v10.13.0-linux-x64 \
              .venv/include/node .venv/bin/node .venv/bin/nodeenv \
    && /usr/bin/common_cleanup.sh

FROM build_base as build_singularity
COPY ./files/common_cleanup.sh /usr/bin/common_cleanup.sh
# Install Go (only needed for building singularity)
ENV GO_VERSION=1.13
RUN apt update && apt install --no-install-recommends cryptsetup-bin uuid-dev -y \
    && wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzvf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz \
    && /usr/bin/common_cleanup.sh

ENV PATH=/usr/local/go/bin:${PATH}
ENV SINGULARITY_VERSION=3.5.3
RUN wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-${SINGULARITY_VERSION}.tar.gz \
    && tar -xzf singularity-${SINGULARITY_VERSION}.tar.gz \
    && cd singularity \
    && ./mconfig \
    && make -C builddir \
    && /usr/bin/common_cleanup.sh

# --- Final image ---
FROM ubuntu:18.04 as final

COPY ./files/common_cleanup.sh /usr/bin/common_cleanup.sh
COPY ./files/create_galaxy_user.py /usr/local/bin/create_galaxy_user.py

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

# Set permissions
RUN groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && /usr/bin/common_cleanup.sh

# Install remaining dependencies
RUN apt update && apt install --no-install-recommends ca-certificates gcc gnupg2 libgomp1 liblzma-dev libbz2-dev libpq-dev \
                                                      mercurial make netcat python-dev python-setuptools python-pip \
                                                      squashfs-tools zlib1g-dev -y \
    && pip install Cython wheel \
    && pip install pysam \
    && /usr/bin/common_cleanup.sh

# Install HTCondor
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install --no-install-recommends htcondor -y \
    && rm /etc/condor/condor_config.local \
    && find / -name '*.pyc' -delete | true \
    && /usr/bin/common_cleanup.sh

# Install Slurm client
ENV MUNGER_USER=munge \
    MUNGE_UID=1200 \
    MUNGE_GID=1200
RUN groupadd -r $MUNGER_USER -g $MUNGE_GID \
    && useradd -u $MUNGE_UID -r -g $MUNGER_USER $MUNGER_USER \
    && echo "deb http://ppa.launchpad.net/natefoo/slurm-drmaa/ubuntu bionic main" >> /etc/apt/sources.list \
    && echo "deb-src http://ppa.launchpad.net/natefoo/slurm-drmaa/ubuntu bionic main" >> /etc/apt/sources.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8DE68488997C5C6BA19021136F2CC56412788738 \
    && apt update \
    && apt install --no-install-recommends slurm-client slurmd slurmctld slurm-drmaa1 -y \
    && apt --no-install-recommends install munge libmunge-dev -y \
    && ln -s /usr/lib/slurm-drmaa/lib/libdrmaa.so.1 /usr/lib/slurm-drmaa/lib/libdrmaa.so \
    && /usr/bin/common_cleanup.sh

# Install CVMFS
RUN apt update \
    && apt install wget lsb-release -y \
    && wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb \
    && dpkg -i cvmfs-release-latest_all.deb \
    && rm -f cvmfs-release-latest_all.deb \
    && apt update \
    && apt install --no-install-recommends cvmfs -y \
    && mkdir /srv/cvmfs \
    && /usr/bin/common_cleanup.sh
COPY files/cvmfs /etc/cvmfs

# Install Docker
RUN apt update \
    && apt install --no-install-recommends docker.io -y \
    && usermod -aG docker $GALAXY_USER \
    && /usr/bin/common_cleanup.sh

COPY --chown=$GALAXY_USER:$GALAXY_USER --from=build_galaxy ${GALAXY_ROOT} ${GALAXY_ROOT}
COPY --chown=$GALAXY_USER:$GALAXY_USER --from=build_miniconda ${GALAXY_CONFIG_TOOL_DEPENDENCY_DIR} ${GALAXY_CONFIG_TOOL_DEPENDENCY_DIR}
COPY --chown=$GALAXY_USER:$GALAXY_USER --from=build_miniconda ${GALAXY_HOME} ${GALAXY_HOME}
COPY --chown=$GALAXY_USER:$GALAXY_USER --from=build_miniconda /etc/profile.d/conda.sh /etc/profile.d/conda.sh

# Install Singularity
COPY --from=build_singularity /singularity /singularity
RUN make -C /singularity/builddir install \
    && rm -rf /singularity \
    && sed -e '/bind path = \/etc\/localtime/s/^/#/g' -i /usr/local/etc/singularity/singularity.conf \
    && /usr/bin/common_cleanup.sh

COPY ./files/start.sh /usr/bin/start.sh

EXPOSE 80

ENTRYPOINT "/usr/bin/start.sh"
