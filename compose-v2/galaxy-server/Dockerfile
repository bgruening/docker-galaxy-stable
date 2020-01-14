FROM buildpack-deps:19.10 as build

ENV EXPORT_DIR=/export \
    GALAXY_ROOT=/galaxy

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
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm

# Install Galaxy dependencies and delete unneeded afterwards
RUN apt update && apt install python-dev python-pip -y \
    && cd $GALAXY_ROOT && ./scripts/common_startup.sh \
    && . $GALAXY_ROOT/.venv/bin/activate && pip install psycopg2 \
    && deactivate \
    && find $GALAXY_ROOT -name '*.pyc' -delete | true

FROM ubuntu:19.10

COPY --from=build /galaxy /galaxy
COPY --from=build /tool_deps /tool_deps 
COPY --from=build /home/galaxy /home/galaxy

ENV EXPORT_DIR=/export \
    GALAXY_ROOT=/galaxy

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

RUN apt update && apt install --no-install-recommends python python-virtualenv netcat libpq-dev mercurial libgomp1 -y \
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

# Quick test for chetaah c library
RUN apt install --no-install-recommends gcc python-pip -y \
    && pip uninstall cheetah -y \
    && pip install cheetah

EXPOSE 80

ENTRYPOINT "/usr/bin/start.sh"