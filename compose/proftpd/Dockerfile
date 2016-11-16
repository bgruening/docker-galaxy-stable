# ProFTP Image, used by the Galaxy Docker project

FROM ubuntu:14.04

ENV GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -c "Galaxy user" $GALAXY_USER && \
    apt-get -qq update && \
    apt-get install --no-install-recommends -y software-properties-common && \
    apt-add-repository ppa:ansible/ansible && \
    apt-get -qq update && \
    apt-get install --no-install-recommends -y ansible openssh-client proftpd proftpd-mod-pgsql && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#ADD ansible /ansible
ADD ansible /ansible
ADD run.sh /usr/bin/run.sh
RUN chown $GALAXY_UID:$GALAXY_GID /usr/bin/run.sh && chmod 755 /usr/bin/run.sh

EXPOSE 21 22

# Autostart script that is invoked during container start
CMD ["/usr/bin/run.sh"]
#CMD ["proftpd","--nodaemon"]
