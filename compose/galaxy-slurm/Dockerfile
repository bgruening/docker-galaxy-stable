FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

ENV GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450 \
SINGULARITY_VERSION=2.3

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -m -r -g $GALAXY_USER -c "Galaxy user" $GALAXY_USER && \
    apt-get update -qq && apt-get install -y --no-install-recommends apt-transport-https \
        unattended-upgrades python-pip python-psutil python-setuptools supervisor wget \
        build-essential munge locales slurm-wlm slurm-wlm-torque && \
    wget https://depot.galaxyproject.org/deb/ubuntu/18.04/slurm-drmaa1_1.2.0-dev.deca826_amd64.deb && \
    wget https://depot.galaxyproject.org/deb/ubuntu/18.04/slurm-drmaa-dev_1.2.0-dev.deca826_amd64.deb && \
    dpkg -i slurm-drmaa1_1.2.0-dev.deca826_amd64.deb && \
    dpkg -i slurm-drmaa-dev_1.2.0-dev.deca826_amd64.deb && \
    /usr/sbin/create-munge-key && \
    pip install --upgrade virtualenv && \
    wget https://github.com/singularityware/singularity/releases/download/$SINGULARITY_VERSION/singularity-$SINGULARITY_VERSION.tar.gz && \
    tar xvf singularity-$SINGULARITY_VERSION.tar.gz && \
    cd singularity-$SINGULARITY_VERSION && \
    ./configure --prefix=/usr/local --sysconfdir=/etc && \
    make && \
    make install && \
    rm -rf singularity-$SINGULARITY_VERSION singularity-$SINGULARITY_VERSION.tar.gz && \
    apt-get remove -y build-essential && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p /tmp/download && \
    wget -qO - https://download.docker.com/linux/static/stable/x86_64/docker-17.06.2-ce.tgz | tar -xz -C /tmp/download && \
    mv /tmp/download/docker/docker /usr/bin/ && \
    rm -rf /tmp/download && \
    rm -rf ~/.cache/



ADD configure_slurm.py /usr/local/bin/configure_slurm.py
ADD munge.conf /etc/default/munge
ADD startup.sh /usr/bin/startup.sh
ADD supervisor_slurm.conf /etc/supervisor/conf.d/slurm.conf
RUN service munge start && service munge stop && \
    chmod +x /usr/bin/startup.sh && \
    locale-gen en_US.UTF-8 && dpkg-reconfigure locales

ENV GALAXY_DIR=/export/galaxy-central \
    SYMLINK_TARGET=/galaxy-central \
    SLURM_USER_NAME=galaxy \
    SLURM_UID=1450 \
    SLURM_GID=1450 \
    SLURM_PARTITION_NAME=work \
    SLURM_CLUSTER_NAME=Cluster \
    SLURM_CONTROL_ADDR=galaxy-slurm \
    SLURM_NODE_NAME=galaxy-slurm \
    SLURMD_AUTOSTART=True \
    SLURMCTLD_AUTOSTART=True \
    SLURM_CONF_PATH=/export/slurm.conf \
    MUNGE_KEY_PATH=/export/munge.key \
    GALAXY_VENV=/galaxy_venv

ADD requirements.txt "$GALAXY_VENV"/
RUN chown -R $SLURM_UID:$SLURM_GID "$GALAXY_VENV" && \
    virtualenv "$GALAXY_VENV" && \
    . "$GALAXY_VENV"/bin/activate && \
    pip install --upgrade pip && \
    pip install galaxy-lib && \
    pip install -r "$GALAXY_VENV"/requirements.txt --index-url https://wheels.galaxyproject.org/simple --extra-index-url https://pypi.python.org/simple && \
    rm -rf ~/.cache/


VOLUME ["/export/", "/var/lib/docker"]
CMD ["/usr/bin/startup.sh"]
