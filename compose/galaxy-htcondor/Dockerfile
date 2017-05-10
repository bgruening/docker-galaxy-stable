FROM quay.io/bgruening/galaxy-htcondor-base

ADD condor_config.local /etc/condor/condor_config.local
ADD supervisord.conf /etc/supervisord.conf

CMD ["/usr/bin/supervisord"]
