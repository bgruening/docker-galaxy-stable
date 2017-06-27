FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo 'Acquire::http::Timeout "20";' > /etc/apt/apt.conf.d/98AcquireTimeout && \
    echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/99AcquireRetries && \
    locale-gen en_US.UTF-8 && dpkg-reconfigure locales && \
    apt-get update -qq && apt-get install -y --no-install-recommends \
    apt-transport-https wget supervisor && \
    apt-get install -y unattended-upgrades && \
    # Condor mirror is really unreliable and times out too often, using a copy of the deb from cargo port
    #echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/ubuntu/stable/ trusty contrib" > /etc/apt/sources.list.d/htcondor.list
    wget -q --no-check-certificate https://depot.galaxyproject.org/software/condor/condor_8.6.3_linux_all.deb && \
    dpkg -i condor_8.6.3_linux_all.deb ; apt-get install -f -y && \
    rm condor_8.6.3_linux_all.deb && \
    rm -rf /var/lib/apt/lists/*
