FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales && \
    apt-get update -qq && apt-get install -y --no-install-recommends \
    apt-transport-https software-properties-common supervisor && \
    echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/ubuntu/stable/ trusty contrib" > /etc/apt/sources.list.d/htcondor.list && \
    wget -qO - http://research.cs.wisc.edu/htcondor/ubuntu/HTCondor-Release.gpg.key | sudo apt-key add - && \
    apt-get update -qq && apt-get install -y condor && \
    rm -rf /var/lib/apt/lists/*
