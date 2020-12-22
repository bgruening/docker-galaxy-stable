FROM alpine:3.11

ENV TEST_REPO=${TEST_REPO:-https://github.com/usegalaxy-eu/workflow-testing} \
    TEST_RELEASE=${TEST_RELEASE:-master}

RUN apk add --no-cache bash python3 curl \
    && apk add --no-cache --virtual build-dep gcc libxml2-dev libxslt-dev musl-dev linux-headers python3-dev \
    && pip3 install planemo \
    && mkdir /src && cd /src \
    && curl -L -s $TEST_REPO/archive/$TEST_RELEASE.tar.gz | tar xzf - --strip-components=1 \
    && apk del build-dep

# Make Python3 standard
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 9
ADD ./run.sh /usr/bin/run.sh

WORKDIR /src

ENTRYPOINT /usr/bin/run.sh
