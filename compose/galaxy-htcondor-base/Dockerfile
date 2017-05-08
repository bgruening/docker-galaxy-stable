FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    echo 'Acquire::http::Timeout "20";' > /etc/apt/apt.conf.d/98AcquireTimeout && \
    echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/99AcquireRetries && \
    locale-gen en_US.UTF-8 && dpkg-reconfigure locales && \
    apt-get update -qq && apt-get install -y --no-install-recommends \
    apt-transport-https wget supervisor && \
    echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/ubuntu/stable/ trusty contrib" > /etc/apt/sources.list.d/htcondor.list && \
    wget -qO - http://research.cs.wisc.edu/htcondor/ubuntu/HTCondor-Release.gpg.key | sudo apt-key add - && \
    apt-get update -qq && apt-get install -y condor && \
    rm -rf /var/lib/apt/lists/*
