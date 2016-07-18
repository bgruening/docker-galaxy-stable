# ProFTP Image, used by the Galaxy Docker project

FROM ubuntu:14.04

ENV GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -c "Galaxy user" $GALAXY_USER && \
    apt-get -qq update && apt-get install --no-install-recommends -y proftpd proftpd-mod-pgsql && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 21

# Autostart script that is invoked during container start
CMD ["proftpd","--nodaemon"]
