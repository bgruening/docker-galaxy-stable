# Galaxy - Stable
#
# VERSION       Galaxy-central

FROM quay.io/bgruening/galaxy-base:18.01b

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

ARG GALAXY_RELEASE=release_18.01
ARG GALAXY_REPO=galaxyproject/galaxy

# Create these folders and link to target directory for installation
RUN mkdir -p /export /galaxy-export && \
    mkdir /galaxy-export/shed_tools && \
    mkdir /galaxy-export/tool_deps && \
    mkdir /galaxy-export/venv && \
    mkdir /galaxy-export/galaxy-central && \
    mkdir /galaxy-export/nginx_upload_store && \
    mkdir /galaxy-export/ftp && \
    mkdir /galaxy-export/rabbitmq && \
    mkdir /galaxy-export/influxdb && \
    mkdir /galaxy-export/grafana && \
    mkdir /galaxy-export/postgres && \
    ln -s -f /galaxy-export/shed_tools /export/shed_tools && \
    ln -s -f /galaxy-export/tool_deps /export/tool_deps && \
    ln -s -f /galaxy-export/venv /export/venv && \
    ln -s -f /galaxy-export/galaxy-central /export/galaxy-central && \
    chown -R $GALAXY_USER:$GALAXY_USER /galaxy-export /export && \
    wget -q -O - https://api.github.com/repos/$GALAXY_REPO/tarball/$GALAXY_RELEASE | tar xz --strip-components=1 -C $GALAXY_ROOT && \
    virtualenv $GALAXY_VIRTUAL_ENV && \
    cp $GALAXY_ROOT/config/galaxy.yml.sample $GALAXY_CONFIG_FILE && \
    . $GALAXY_VIRTUAL_ENV/bin/activate && pip install pip --upgrade && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_VIRTUAL_ENV/* && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_ROOT/* && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_CONFIG_FILE

ADD config $GALAXY_ROOT/config
ADD welcome /galaxy-export/welcome

RUN ansible-playbook /ansible/provision.yml \
    --extra-vars galaxy_server_dir=$GALAXY_ROOT \
    --extra-vars galaxy_venv_dir=$GALAXY_VIRTUAL_ENV \
    --extra-vars galaxy_log_dir=$GALAXY_LOGS_DIR \
    --extra-vars galaxy_user_name=$GALAXY_USER \
    --extra-vars galaxy_config_file=$GALAXY_CONFIG_FILE \
    --extra-vars galaxy_extras_config_condor=True \
    --extra-vars galaxy_extras_config_condor_docker=True \
    --extra-vars galaxy_extras_config_k8s_jobs=True \
    --extra-vars galaxy_minimum_version=17.09 \
    --extra-vars galaxy_extras_config_rabbitmq=False \
    --extra-vars nginx_upload_store_path=/export/nginx_upload_store \
    --extra-vars nginx_welcome_location=$NGINX_WELCOME_LOCATION \
    --extra-vars nginx_welcome_path=$NGINX_WELCOME_PATH \
    #--extra-vars galaxy_extras_config_container_resolution=True \
    #--extra-vars container_resolution_explicit=True \
    #--extra-vars container_resolution_cached_mulled=False \
    #--extra-vars container_resolution_build_mulled=False \
    --tags=ie,pbs,slurm,uwsgi,metrics,k8s -c local && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#--extra-vars galaxy_extras_config_container_resolution=True \
#--extra-vars container_resolution_explicit=True \
#--extra-vars container_resolution_cached_mulled=False \
#--extra-vars container_resolution_build_mulled=False \


# The following commands will be executed as User galaxy
USER galaxy

#RUN cd $GALAXY_VIRTUAL_ENV && . bin/activate && pip install watchdog

WORKDIR $GALAXY_ROOT

# Updating genome informations from UCSC
#RUN export GALAXY=$GALAXY_ROOT && sh ./cron/updateucsc.sh.sample

# prefetch Python wheels
# Install all required Node dependencies. This is required to get proxy support to work for Interactive Environments
RUN ./scripts/common_startup.sh --skip-client-build && \
    . $GALAXY_VIRTUAL_ENV/bin/activate && \
    python ./scripts/manage_tool_dependencies.py -c "$GALAXY_CONFIG_FILE" init_if_needed && \
    # Install all required Node dependencies. This is required to get proxy support to work for Interactive Environments
    cd $GALAXY_ROOT/lib/galaxy/web/proxy/js && \
    npm install

# Switch back to User root
USER root

# Create symlinks from $GALAXY_ROOT/* to /export/*
RUN mv $GALAXY_ROOT/config /galaxy-export/config && ln -s -f /export/config $GALAXY_ROOT/config && \
    mv $GALAXY_ROOT/tools /galaxy-export/tools && ln -s -f /export/tools $GALAXY_ROOT/tools && \
    mv $GALAXY_ROOT/tool-data /galaxy-export/tool-data && ln -s -f /export/tool-data $GALAXY_ROOT/tool-data && \
    mv $GALAXY_ROOT/display_applications /galaxy-export/display_applications && ln -s -f /export/display_applications $GALAXY_ROOT/display_applications && \
    mv $GALAXY_ROOT/database /galaxy-export/database && ln -s -f /export/database $GALAXY_ROOT/database && \
    rm -rf $GALARY_ROOT/.venv && ln -s -f /export/venv $GALAXY_ROOT/.venv && ln -s -f /export/venv $GALAXY_ROOT/venv

WORKDIR /galaxy-export

# Mark folders as imported from the host.
VOLUME ["/export/"]

ADD startup.sh /usr/bin/startup
RUN chmod +x /usr/bin/startup

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
