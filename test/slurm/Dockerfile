FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    slurmd slurmctld \
    python-psutil supervisor virtualenv samtools apt-transport-https software-properties-common curl sudo gpg-agent && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt update && \
    apt install -y docker-ce && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && rm -rf ~/.cache/ && \
    adduser galaxy &&\
    /usr/sbin/create-munge-key &&\
    touch /var/log/slurm-llnl/slurmctld.log /var/log/slurm-llnl/slurmd.log &&\
    mkdir /tmp/slurm

ADD configure_slurm.py /usr/local/bin/configure_slurm.py
ADD munge.conf /etc/default/munge
RUN service munge start && service munge stop
ADD startup.sh /usr/bin/startup.sh
ADD supervisor_slurm.conf /etc/supervisor/conf.d/slurm.conf
RUN chmod +x /usr/bin/startup.sh
#RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
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
