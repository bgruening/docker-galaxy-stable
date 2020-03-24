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

ENV GALAXY_USER=galaxy \
    GALAXY_GROUP=galaxy \
    GALAXY_UID=1450 \
    GALAXY_GID=1450 \
    GALAXY_HOME=/home/galaxy

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && mkdir $GALAXY_HOME \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME

# Install Slurm
ENV SLURM_USER=galaxy \
    SLURM_UID=1450 \
    SLURM_GID=1450 \
    MUNGER_USER=munge \
    MUNGE_UID=1200 \
    MUNGE_GID=1200

RUN groupadd -r $MUNGER_USER -g $MUNGE_GID \
    && useradd -u $MUNGE_UID -r -g $MUNGER_USER $MUNGER_USER \
    && apt update \
    && apt install --no-install-recommends gosu munge python python-dev slurm-wlm -y \
    && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/*

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

COPY start.sh /usr/bin/start.sh

ENTRYPOINT [ "/usr/bin/start.sh" ]
