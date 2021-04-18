FROM selenium/standalone-chrome:3.141.59

ARG GALAXY_RELEASE=release_20.09
ARG GALAXY_REPO=https://github.com/galaxyproject/galaxy

ENV GALAXY_ROOT=/galaxy
ENV GALAXY_PYTHON=/usr/bin/python3

USER root
RUN apt update && apt install --no-install-recommends python3-dev python3-pip -y && rm -rf /var/lib/apt/lists/* \
    && mkdir "${GALAXY_ROOT}" \
    && chown seluser "${GALAXY_ROOT}"

USER seluser
RUN mkdir -p $GALAXY_ROOT && \
    curl -L -s $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT \
    && cd "${GALAXY_ROOT}" \
    && ./scripts/common_startup.sh --skip-client-build --dev-wheels

COPY run.sh /usr/bin/run.sh

CMD "/usr/bin/run.sh"
