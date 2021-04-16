ARG DOCKER_REGISTRY=quay.io
ARG DOCKER_REGISTRY_USERNAME=bgruening
ARG IMAGE_TAG=latest

FROM $DOCKER_REGISTRY/$DOCKER_REGISTRY_USERNAME/galaxy-container-base:$IMAGE_TAG

# Base dependencies
RUN apt update && apt install --no-install-recommends gnupg2 -y \
    && /usr/bin/common_cleanup.sh

# Install HTCondor
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install --no-install-recommends htcondor -y \
    && rm /etc/condor/condor_config.local \
    && /usr/bin/common_cleanup.sh

# Install Slurm client
ENV MUNGER_USER=munge \
    MUNGE_UID=1200 \
    MUNGE_GID=1200
RUN groupadd -r $MUNGER_USER -g $MUNGE_GID \
    && useradd -u $MUNGE_UID -r -g $MUNGER_USER $MUNGER_USER \
    && echo "deb http://ppa.launchpad.net/natefoo/slurm-drmaa/ubuntu focal main" >> /etc/apt/sources.list \
    && echo "deb-src http://ppa.launchpad.net/natefoo/slurm-drmaa/ubuntu focal main" >> /etc/apt/sources.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8DE68488997C5C6BA19021136F2CC56412788738 \
    && apt update \
    && apt install --no-install-recommends python3-distutils slurm-client slurmd slurmctld slurm-drmaa1 -y \
    && apt --no-install-recommends install munge libmunge-dev -y \
    && ln -s /usr/lib/slurm-drmaa/lib/libdrmaa.so.1 /usr/lib/slurm-drmaa/lib/libdrmaa.so \
    && /usr/bin/common_cleanup.sh

# Install CVMFS
RUN apt update \
    && apt install wget lsb-release -y \
    && wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb \
    && dpkg -i cvmfs-release-latest_all.deb \
    && rm -f cvmfs-release-latest_all.deb \
    && apt update \
    && apt install --no-install-recommends cvmfs -y \
    && mkdir /srv/cvmfs \
    && /usr/bin/common_cleanup.sh
COPY files/cvmfs /etc/cvmfs
