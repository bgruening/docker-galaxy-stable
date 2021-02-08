ARG DOCKER_REGISTRY=quay.io
ARG DOCKER_REGISTRY_USERNAME=bgruening
ARG IMAGE_TAG=latest

FROM buildpack-deps:20.04 as build_pulsar

ARG PULSAR_RELEASE=0.14.0
ARG PULSAR_REPO=https://github.com/galaxyproject/pulsar

ENV PULSAR_ROOT=/pulsar
ENV PULSAR_VIRTUALENV=$PULSAR_ROOT/.venv

RUN apt update \
    && apt install --no-install-recommends curl python3 python3-dev python3-pip python3-setuptools python3-venv -y

RUN mkdir /tmp/pulsar \
    && curl -L -s $PULSAR_REPO/archive/$PULSAR_RELEASE.tar.gz | tar xzf - --strip-components=1 -C /tmp/pulsar \
    && mkdir $PULSAR_ROOT \
    && pip3 install wheel \
    && python3 -m venv $PULSAR_VIRTUALENV \
    && . $PULSAR_VIRTUALENV/bin/activate \
    && pip3 install drmaa kombu pastescript pastedeploy pycurl uwsgi \
    && cd /tmp/pulsar \
    && python3 /tmp/pulsar/setup.py install


# --- Final image ---
FROM $DOCKER_REGISTRY/$DOCKER_REGISTRY_USERNAME/galaxy-cluster-base:$IMAGE_TAG as final
COPY files/common_cleanup.sh /usr/bin/common_cleanup.sh

ENV PULSAR_ROOT=/pulsar
ENV PULSAR_VIRTUALENV=$PULSAR_ROOT/.venv \
    PULSAR_CONFIG_DIR=$PULSAR_ROOT/config \
    PULSAR_TOOL_DEPENDENCY_DIR=$PULSAR_ROOT/dependencies

RUN apt update \
    && apt install --no-install-recommends ca-certificates curl libxml2-dev python3 -y \
    && /usr/bin/common_cleanup.sh

COPY --from=build_pulsar /pulsar /pulsar

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
