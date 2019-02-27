# Galaxy - Stable
#
# VERSION       Galaxy-central

FROM quay.io/bgruening/galaxy-base:19.01

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

ARG GALAXY_ANSIBLE_TAGS=supervisor,startup,scripts,nginx,cvmfs

ENV GALAXY_DESTINATIONS_DEFAULT=slurm_cluster \
# The following 2 ENV vars can be used to set the number of uwsgi processes and threads
UWSGI_PROCESSES=2 \
UWSGI_THREADS=4 \
# Set HTTPS to use a self-signed certificate (or your own certificate in /export/{server.key,server.crt})
USE_HTTPS=False \
# Set USE_HTTPS_LENSENCRYPT and GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL to a domain that is reachable to get a letsencrypt certificate
USE_HTTPS_LETSENCRYPT=False \
GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL=http://localhost \
# Set the number of Galaxy handlers
GALAXY_HANDLER_NUMPROCS=2

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    apt-get -qq update && apt-get install --no-install-recommends -y apt-transport-https wget && \
    echo "deb https://deb.nodesource.com/node_9.x $(lsb_release -sc) main" > /etc/apt/sources.list.d/nodejs.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68576280 && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y nodejs \
    nginx-extras nginx-common supervisor autofs slurm-wlm slurm-wlm-torque && \
    wget https://depot.galaxyproject.org/deb/ubuntu/18.04/slurm-drmaa1_1.2.0-dev.deca826_amd64.deb && \
    wget https://depot.galaxyproject.org/deb/ubuntu/18.04/slurm-drmaa-dev_1.2.0-dev.deca826_amd64.deb && \
    dpkg -i slurm-drmaa1_1.2.0-dev.deca826_amd64.deb && \
    dpkg -i slurm-drmaa-dev_1.2.0-dev.deca826_amd64.deb && \
    # install and remove supervisor, so get the service config file
    apt-get -qq remove -y supervisor && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    groupadd --gid 999 docker && \
    # this can be optimised I think, we should get the SLURM client only and update it
    gpasswd -a $GALAXY_USER docker && \
    mkdir -p /etc/supervisor/conf.d/ /var/log/supervisor/ && \
    #pip install --upgrade pip && \
    pip install ephemeris supervisor --upgrade && \
    ln -s /usr/local/bin/supervisord /usr/bin/supervisord

RUN rm -f /usr/bin/startup && \
    ansible-playbook /ansible/provision.yml \
    --extra-vars galaxy_server_dir=$GALAXY_ROOT \
    --extra-vars galaxy_venv_dir=$GALAXY_VIRTUAL_ENV \
    --extra-vars galaxy_log_dir=$GALAXY_LOGS_DIR \
    --extra-vars galaxy_user_name=$GALAXY_USER \
    --extra-vars galaxy_config_file=$GALAXY_CONFIG_FILE \
    --extra-vars galaxy_extras_config_postgres=False \
    --extra-vars galaxy_extras_config_condor=True \
    --extra-vars galaxy_extras_config_condor_docker=True \
    --extra-vars galaxy_extras_config_rabbitmq=False \
    --extra-vars galaxy_extras_config_slurm=False \
    --extra-vars galaxy_extras_config_proftpd=False \
    --extra-vars galaxy_extras_config_cvmfs=True \
    --extra-vars galaxy_tool_data_table_config_file=/etc/galaxy/tool_data_table_conf.xml \
    --extra-vars galaxy_extras_config_nginx_upload=False \
    --extra-vars nginx_welcome_location=$NGINX_WELCOME_LOCATION \
    --extra-vars nginx_welcome_path=$NGINX_WELCOME_PATH \
    --extra-vars startup_sleeplock=True \
    --extra-vars startup_export_user_files=False \
    --extra-vars supervisor_manage_slurm=False \
    --extra-vars supervisor_manage_postgres=False \
    --extra-vars supervisor_manage_proftp=False \
    # This is the only safe backend which works on all kinds of docker hosts.
    # See https://docs.docker.com/engine/userguide/storagedriver/selectadriver/ for details
    --extra-vars galaxy_extras_docker_storage_backend=vfs \
    # Used for detecting privileged mode
    --extra-vars host_docker_legacy=False \
    --extra-vars galaxy_extras_docker_legacy=False \
    --tags=$GALAXY_ANSIBLE_TAGS -c local && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN chmod +x /usr/bin/startup

# Mark folders as imported from the host.
VOLUME ["/export/", "/var/lib/docker"]

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
