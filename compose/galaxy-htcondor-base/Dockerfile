FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo 'Acquire::http::Timeout "20";' > /etc/apt/apt.conf.d/98AcquireTimeout && \
    echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/99AcquireRetries && \
    locale-gen en_US.UTF-8 && dpkg-reconfigure locales && \
    apt-get update -qq && apt-get install -y --no-install-recommends \
    apt-transport-https wget supervisor unattended-upgrades ca-certificates && \
    # Condor mirror is really unreliable and times out too often, using a copy of the deb from cargo port
    #echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/ubuntu/stable/ trusty contrib" > /etc/apt/sources.list.d/htcondor.list
    wget -q https://depot.galaxyproject.org/software/condor/condor_8.6.3_linux_all.deb && \
    dpkg -i condor_8.6.3_linux_all.deb ; apt-get install -f -y && \
    rm condor_8.6.3_linux_all.deb && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://dl.influxdata.com/telegraf/releases/telegraf-1.5.0_linux_amd64.tar.gz && \
    cd / && tar xvfz telegraf-1.5.0_linux_amd64.tar.gz && \
    cp -Rv telegraf/* / && \
    rm -rf telegraf && \
    rm telegraf-1.5.0_linux_amd64.tar.gz

ADD telegraf.conf /etc/telegraf/telegraf.conf
