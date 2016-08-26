FROM toolshed/requirements

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    slurm-llnl slurm-llnl-torque slurm-drmaa-dev \
    python-pip python-psutil supervisor samtools apt-transport-https software-properties-common
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 \
    --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
    sh -c "echo deb https://apt.dockerproject.org/repo ubuntu-trusty main > /etc/apt/sources.list.d/docker.list" && \
    apt-get update && \
    apt-get install -y docker-engine
RUN adduser galaxy &&\
    /usr/sbin/create-munge-key &&\
    touch /var/log/slurm-llnl/slurmctld.log /var/log/slurm-llnl/slurmd.log &&\
    mkdir /tmp/slurm && pip install --upgrade supervisor
RUN apt-get remove -y supervisor && mkdir /var/log/supervisor
ADD configure_slurm.py /usr/local/bin/configure_slurm.py
ADD munge.conf /etc/default/munge
RUN service munge start && service munge stop
ADD startup.sh /usr/bin/startup.sh
ADD supervisor_slurm.conf /etc/supervisor/conf.d/slurm.conf
RUN chmod +x /usr/bin/startup.sh
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV GALAXY_DIR=/export/galaxy-central \
    SYMLINK_TARGET=/galaxy-central \
    SLURM_USER_NAME=galaxy \
    SLURM_UID=1450 \
    SLURM_GID=1450 \
    SLURM_PARTITION_NAME=work \
    SLURM_CLUSTER_NAME=Cluster \
    SLURMD_AUTOSTART=True \
    SLURMCTLD_AUTOSTART=True \
    SLURM_CONF_PATH=/export/slurm.conf \
    MUNGE_KEY_PATH=/export/munge.key

VOLUME ["/export/", "/var/lib/docker"]
CMD ["/usr/bin/startup.sh"]
