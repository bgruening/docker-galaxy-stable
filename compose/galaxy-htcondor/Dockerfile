FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    apt-transport-https software-properties-common supervisor wget && \
    echo "deb http://research.cs.wisc.edu/htcondor/ubuntu/stable/ trusty contrib" > /etc/apt/sources.list.d/htcondor.list && \
    wget -qO - http://research.cs.wisc.edu/htcondor/ubuntu/HTCondor-Release.gpg.key | sudo apt-key add - && \
    apt-get update -qq && apt-get install -y condor && \
    rm -rf /var/lib/apt/lists/*
#    mkdir /var/run/condor && chown condor:condor /var/run/condor/
    

ADD condor_config.local /etc/condor/condor_config.local
ADD supervisord.conf /etc/supervisord.conf

CMD ["/usr/bin/supervisord"]
