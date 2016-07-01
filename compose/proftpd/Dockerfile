# ProFTP Image, used by the Galaxy Docker project

FROM ubuntu:14.04

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

ENV LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8

RUN apt-get -qq update && apt-get install --no-install-recommends -y proftpd proftpd-mod-pgsql && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /var/ftp
EXPOSE 21

# Autostart script that is invoked during container start
CMD ["proftpd","--nodaemon"]
