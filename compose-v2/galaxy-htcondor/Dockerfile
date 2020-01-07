FROM ubuntu:19.10

ENV DEBIAN_FRONTEND noninteractive

ENV GALAXY_USER=galaxy \
    GALAXY_UID=1450 \
    GALAXY_GID=1450 \
    GALAXY_HOME=/home/galaxy \
    EXPORT_DIR=/export \
    # Setting a standard encoding. This can get important for things like the unix sort tool.
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

ENV CONDOR_CPUS=1 \
    CONDOR_MEMORY=1024

# Condor master
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
    && echo 'Acquire::http::Timeout "20";' > /etc/apt/apt.conf.d/98AcquireTimeout \
    && echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/99AcquireRetries \
    && apt-get update -qq && apt-get install -y --no-install-recommends locales \
    && locale-gen en_US.UTF-8 && dpkg-reconfigure locales \
    && apt-get install -y --no-install-recommends \
        supervisor \
        htcondor \
        wget \
    && touch /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog \
    && mkdir -p /var/run/condor/ /var/lock/condor/ \
    && chown -R condor: /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog /var/run/condor/ /var/lock/condor/

# Condor executor
RUN mkdir -p /tmp/download && \
    wget --no-check-certificate -qO - https://download.docker.com/linux/static/stable/x86_64/docker-17.06.2-ce.tgz | tar -xz -C /tmp/download && \
    mv /tmp/download/docker/docker /usr/bin/ && \
    rm -rf /tmp/download && \
    rm -rf ~/.cache/ && \
    groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
    groupadd --gid 999 docker && \
    gpasswd -a $GALAXY_USER docker && \
    adduser condor docker

ADD supervisord.conf /etc/supervisord.conf

ENTRYPOINT ["/usr/bin/supervisord"]