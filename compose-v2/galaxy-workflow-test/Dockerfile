FROM alpine:3.11

ENV TEST_REPO=${TEST_REPO:-https://github.com/usegalaxy-eu/workflow-testing} \
    TEST_RELEASE=${TEST_RELEASE:-master}

RUN apk add --no-cache bash python py-setuptools curl \
    && apk add --no-cache --virtual build-dep gcc libxml2-dev libxslt-dev musl-dev linux-headers python-dev py-pip \
    && pip install planemo \
    && mkdir /src && cd /src \
    && curl -L -s $TEST_REPO/archive/$TEST_RELEASE.tar.gz | tar xzf - --strip-components=1 \
    && apk del build-dep

ADD ./run.sh /usr/bin/run.sh

WORKDIR /src

ENTRYPOINT /usr/bin/run.sh
