FROM alpine:3.11

ENV TEST_REPO=${TEST_REPO:-https://github.com/jonas27/workflow-testing} \
    TEST_RELEASE=${TEST_RELEASE:-20.09-comment-filetype}

RUN apk add --no-cache bash python3 curl \
    && apk add --no-cache --virtual build-dep gcc libxml2-dev libxslt-dev musl-dev linux-headers python3-dev \
    && pip3 install planemo \
    && mkdir /src && cd /src \
    && curl -L -s $TEST_REPO/archive/$TEST_RELEASE.tar.gz | tar xzf - --strip-components=1 \
    && apk del build-dep

# Make Python3 standard
RUN ln /usr/bin/python3 /usr/bin/python && ln /usr/bin/python3 /usr/bin/python2

ADD ./run.sh /usr/bin/run.sh

WORKDIR /src

ENTRYPOINT /usr/bin/run.sh
