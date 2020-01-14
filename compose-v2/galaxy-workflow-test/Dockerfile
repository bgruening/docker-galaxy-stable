FROM alpine:3.11

ENV TEST_REPO=${TEST_REPO:-https://github.com/usegalaxy-eu/workflow-testing} \
    TEST_RELEASE=${TEST_RELEASE:-master}

RUN apk update && apk add bash gcc libxml2-dev libxslt-dev musl-dev linux-headers python-dev py-pip curl \
    && pip install planemo

RUN mkdir /src && cd /src \
    && curl -L -s $TEST_REPO/archive/$TEST_RELEASE.tar.gz | tar xzf - --strip-components=1

ADD ./run.sh /usr/bin/run.sh

WORKDIR /src

ENTRYPOINT /usr/bin/run.sh