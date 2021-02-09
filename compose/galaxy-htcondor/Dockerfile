ARG DOCKER_REGISTRY=quay.io
ARG DOCKER_REGISTRY_USERNAME=bgruening
ARG IMAGE_TAG=latest

FROM buildpack-deps:20.04 as galaxy_dependencies

ARG GALAXY_RELEASE=release_20.09
ARG GALAXY_REPO=https://github.com/galaxyproject/galaxy

ENV GALAXY_ROOT=/galaxy
ENV GALAXY_LIBRARY=$GALAXY_ROOT/lib

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

ENV DEBIAN_FRONTEND noninteractive

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

ENV EXPORT_DIR=/export \
    # Setting a standard encoding. This can get important for things like the unix sort tool.
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

ENV CONDOR_CPUS=1 \
    CONDOR_MEMORY=1024

# Condor master
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
    && echo 'Acquire::http::Timeout "20";' > /etc/apt/apt.conf.d/98AcquireTimeout \
    && echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/99AcquireRetries \
    && apt-get update -qq && apt-get install -y --no-install-recommends locales \
    && locale-gen en_US.UTF-8 && dpkg-reconfigure locales \
    && apt-get install -y --no-install-recommends \
        supervisor \
        htcondor \
        wget \
    && touch /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog \
    && mkdir -p /var/run/condor/ /var/lock/condor/ \
    && chown -R condor: /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog /var/run/condor/ /var/lock/condor/

ADD supervisord.conf /etc/supervisord.conf

# Copy Galaxy dependencies
COPY --chown=$GALAXY_USER:$GALAXY_USER --from=galaxy_dependencies $GALAXY_ROOT $GALAXY_ROOT

COPY start.sh /usr/bin/start.sh
RUN apt update && apt install python3 -y

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 9 

ENTRYPOINT /usr/bin/start.sh
