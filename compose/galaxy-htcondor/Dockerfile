FROM quay.io/bgruening/galaxy-htcondor-base:18.09

ADD condor_config.local /etc/condor/condor_config.local
ADD supervisord.conf /etc/supervisord.conf

RUN touch /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog && \
    mkdir -p /var/run/condor/ /var/lock/condor/ && \
    chown -R condor: /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog /var/run/condor/ /var/lock/condor/

CMD ["/usr/bin/supervisord"]
