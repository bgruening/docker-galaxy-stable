ARG DOCKER_REGISTRY=quay.io
ARG DOCKER_REGISTRY_USERNAME=bgruening
ARG IMAGE_TAG=latest

FROM buildpack-deps:20.04 as galaxy_dependencies

ARG GALAXY_RELEASE=release_20.09
ARG GALAXY_REPO=https://github.com/galaxyproject/galaxy

ENV GALAXY_ROOT=/galaxy

# Download Galaxy source, but only keep necessary dependencies
RUN mkdir "${GALAXY_ROOT}" \
    && curl -L -s $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT \
    && cd $GALAXY_ROOT \
    && ls . | grep -v "lib" | xargs rm -rf \
    && cd $GALAXY_ROOT/lib \
    && ls . | grep -v "galaxy\|galaxy_ext" | xargs rm -rf \
    && cd $GALAXY_ROOT/lib/galaxy \
    && ls . | grep -v "__init__.py\|datatypes\|exceptions\|files\|metadata\|model\|util\|security" | xargs rm -rf


FROM $DOCKER_REGISTRY/$DOCKER_REGISTRY_USERNAME/galaxy-container-base:$IMAGE_TAG as final

ENV GALAXY_USER=galaxy \
    GALAXY_GROUP=galaxy \
    GALAXY_UID=1450 \
    GALAXY_GID=1450 \
    GALAXY_HOME=/home/galaxy \
    GALAXY_ROOT=/galaxy

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && mkdir $GALAXY_HOME \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME

# Install Slurm
ENV SLURM_USER=galaxy \
    SLURM_UID=1450 \
    SLURM_GID=1450 \
    MUNGER_USER=munge \
    MUNGE_UID=1200 \
    MUNGE_GID=1200

RUN groupadd -r $MUNGER_USER -g $MUNGE_GID \
    && useradd -u $MUNGE_UID -r -g $MUNGER_USER $MUNGER_USER \
    && apt update \
    && apt install --no-install-recommends gosu munge python3 python3-dev slurm-wlm -y \
    && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/* && find / -name '*.pyc' -delete

# Copy Galaxy dependencies
COPY --chown=$GALAXY_USER:$GALAXY_USER --from=galaxy_dependencies $GALAXY_ROOT $GALAXY_ROOT
# Make Python3 standard
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 9 

COPY start.sh /usr/bin/start.sh

ENTRYPOINT [ "/usr/bin/start.sh" ]
