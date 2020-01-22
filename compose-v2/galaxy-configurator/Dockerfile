FROM alpine:3.11

RUN apk add --no-cache bash python3 \
    && pip3 install j2cli[yaml]

COPY ./templates /templates
COPY ./run.sh /usr/bin/run.sh

ENTRYPOINT "/usr/bin/run.sh"
