FROM quay.io/bgruening/galaxy-htcondor-base:18.01

ADD condor_config.local /etc/condor/condor_config.local
ADD supervisord.conf /etc/supervisord.conf

CMD ["/usr/bin/supervisord"]
