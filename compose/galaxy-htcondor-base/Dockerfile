FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
    && echo 'Acquire::http::Timeout "20";' > /etc/apt/apt.conf.d/98AcquireTimeout \
    && echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/99AcquireRetries \
    && apt-get update -qq && apt-get install -y --no-install-recommends locales \
    && locale-gen en_US.UTF-8 && dpkg-reconfigure locales \
    && apt-get install -y --no-install-recommends \
        supervisor \
        htcondor \
        wget \
    && wget --no-check-certificate https://dl.influxdata.com/telegraf/releases/telegraf-1.5.0_linux_amd64.tar.gz \
    && cd / && tar xvfz telegraf-1.5.0_linux_amd64.tar.gz \
    && cp -Rv telegraf/* / \
    && find /usr/lib/ -name '*.pyc' -delete \
    ## && apt-get purge -y wget \
    && apt-get autoremove -y && apt-get clean \
    && rm -rf /tmp/* /root/.cache/ /var/tmp/* /var/cache/* /var/lib/apt/lists/* \
    && rm -rf telegraf \
    && rm telegraf-1.5.0_linux_amd64.tar.gz \
    && touch /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog \
    && mkdir -p /var/run/condor/ /var/lock/condor/ \
    && chown -R condor: /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog /var/run/condor/ /var/lock/condor/

ADD telegraf.conf /etc/telegraf/telegraf.conf
