FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    slurm-llnl slurm-llnl-torque slurm-drmaa-dev python-psutil supervisor
RUN adduser galaxy &&\
    /usr/sbin/create-munge-key &&\
    touch /var/log/slurm-llnl/slurmctld.log /var/log/slurm-llnl/slurmd.log &&\
    mkdir /tmp/slurm
ADD configure_slurm.py /usr/local/bin/configure_slurm.py
ADD munge.conf /etc/default/munge
RUN service munge start && service munge stop
ADD startup.sh /usr/bin/startup.sh
ADD supervisor_slurm.conf /etc/supervisor/conf.d/slurm.conf
RUN chmod +x /usr/bin/startup.sh
ENV GALAXY_UID=1450 \
    GALAXY_GID=1450

VOLUME ["/export/"]
CMD ["/usr/bin/startup.sh"]
