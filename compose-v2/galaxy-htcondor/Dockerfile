FROM buildpack-deps:18.04 as build_singularity

ENV SINGULARITY_VERSION=3.5.3
ENV GO_VERSION=1.13

# Install Go (only needed for building singularity)
RUN apt update && apt install --no-install-recommends cryptsetup-bin uuid-dev -y \
    && wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzvf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH=/usr/local/go/bin:${PATH}

RUN wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-${SINGULARITY_VERSION}.tar.gz \
    && tar -xzf singularity-${SINGULARITY_VERSION}.tar.gz \
    && cd singularity \
    && ./mconfig \
    && make -C builddir

FROM ubuntu:18.04 as final

ENV DEBIAN_FRONTEND noninteractive

ENV GALAXY_USER=galaxy \
    GALAXY_GROUP=galaxy \
    GALAXY_UID=1450 \
    GALAXY_GID=1450 \
    GALAXY_HOME=/home/galaxy

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && mkdir $GALAXY_HOME \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME

ENV EXPORT_DIR=/export \
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

ADD supervisord.conf /etc/supervisord.conf

# Install Docker
RUN apt update \
    && apt install --no-install-recommends docker.io -y \
    && usermod -aG docker $GALAXY_USER

# Install Singularity
COPY --from=build_singularity /singularity /singularity
RUN apt update \
    && apt install --no-install-recommends ca-certificates make squashfs-tools -y \
    && make -C /singularity/builddir install \
    && rm -rf /singularity \
    && sed -e '/bind path = \/etc\/localtime/s/^/#/g' -i /usr/local/etc/singularity/singularity.conf

ENTRYPOINT ["/usr/bin/supervisord"]
