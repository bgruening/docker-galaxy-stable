FROM alpine:3.11 as build

ENV BIOBLEND_VERSION=0.13.0

ADD "https://github.com/galaxyproject/bioblend/archive/v$BIOBLEND_VERSION.zip" /src/bioblend.zip
RUN apk update && apk add curl python3-dev unzip \
    && pip3 install pep8 tox \
    && cd /src \
    && unzip bioblend.zip && rm bioblend.zip \
    && mv "bioblend-$BIOBLEND_VERSION" bioblend \
    && cd bioblend \
    && python3 setup.py install

WORKDIR /src/bioblend

RUN tox -e py38 --notest

COPY ./run.sh /src/bioblend/run.sh

ENTRYPOINT ./run.sh
