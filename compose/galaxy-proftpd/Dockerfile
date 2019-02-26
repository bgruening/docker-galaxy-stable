# ProFTP Image, used by the Galaxy Docker project

FROM ubuntu:18.04

ARG ANSIBLE_REPO=galaxyproject/ansible-galaxy-extras
ARG ANSIBLE_RELEASE=master

ENV GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -c "Galaxy user" $GALAXY_USER && \
    apt-get -qq update && \
    apt-get install --no-install-recommends -y software-properties-common \
    unattended-upgrades wget && \
    apt-add-repository ppa:ansible/ansible && \
    apt-get -qq update && \
    apt-get install --no-install-recommends -y ansible openssh-client proftpd proftpd-mod-pgsql && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD ansible /ansible
RUN mkdir -p /ansible/galaxyprojectdotorg.galaxyextras && \
    cd /ansible/galaxyprojectdotorg.galaxyextras && \
    wget -pO- https://api.github.com/repos/$ANSIBLE_REPO/tarball/$ANSIBLE_RELEASE | tar xvz --strip-components=1

# Generate ssh keys, all other config will be overwritte upon startup
RUN ansible-playbook /ansible/provision.yml \
    --tags=proftpd --skip-tags=proftpd_apt -c local \
    --extra-vars proftpd_generate_ssh_key="true" \
    --extra-vars proftpd_use_sftp="true"

ADD run.sh /usr/bin/run.sh
RUN chown $GALAXY_UID:$GALAXY_GID /usr/bin/run.sh && chmod 755 /usr/bin/run.sh

EXPOSE 21 22

# Autostart script that is invoked during container start
CMD ["/usr/bin/run.sh"]
