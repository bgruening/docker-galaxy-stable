FROM quay.io/bgruening/galaxy-htcondor-base:19.01

ENV GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450 \
GALAXY_HOME=/home/galaxy \
EXPORT_DIR=/export \
# Setting a standard encoding. This can get important for things like the unix sort tool.
LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8

ADD startup.sh /usr/bin/startup.sh

RUN mkdir -p /tmp/download && \
    wget --no-check-certificate -qO - https://download.docker.com/linux/static/stable/x86_64/docker-17.06.2-ce.tgz | tar -xz -C /tmp/download && \
    mv /tmp/download/docker/docker /usr/bin/ && \
    rm -rf /tmp/download && \
    rm -rf ~/.cache/ && \
    groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
    groupadd --gid 999 docker && \
    gpasswd -a $GALAXY_USER docker && \
    adduser condor docker && \
    #mkdir /root/.docker && \
    #chown root:docker /root/.docker && \
    #chmod 750 /root/.docker && \
    #chmod +rx /root && \
    chmod +x /usr/bin/startup.sh

ENV CONDOR_CPUS=1 \
    CONDOR_MEMORY=1024

ADD startup.sh /usr/bin/startup.sh
RUN chmod +x /usr/bin/startup.sh

CMD ["/usr/bin/startup.sh"]
