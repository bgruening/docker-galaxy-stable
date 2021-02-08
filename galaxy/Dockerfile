# Galaxy - Stable
#
# VERSION       Galaxy-central

FROM ubuntu:20.04

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

# TODO
#
# * README: only Docker next to Docker is supported
# * NodeJS is getting globally installed via the playbook, this is not needed anymore isn't it?
# * the playbooks are not cleaning anything up
# * autofs is big and should be installed during startup, only in case --priv is enables ?
#
ARG GALAXY_RELEASE
ARG GALAXY_REPO

ENV GALAXY_RELEASE=${GALAXY_RELEASE:-release_20.09} \
    GALAXY_REPO=${GALAXY_REPO:-https://github.com/galaxyproject/galaxy} \
    GALAXY_ROOT=/galaxy-central \
    GALAXY_CONFIG_DIR=/etc/galaxy \
    EXPORT_DIR=/export \
    DEBIAN_FRONTEND=noninteractive \
    PG_VERSION=11


ENV GALAXY_CONFIG_FILE=$GALAXY_CONFIG_DIR/galaxy.yml \
    GALAXY_CONFIG_JOB_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_conf.xml \
    GALAXY_CONFIG_JOB_METRICS_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_metrics_conf.xml \
    GALAXY_CONFIG_TOOL_DATA_TABLE_CONFIG_PATH=/etc/galaxy/tool_data_table_conf.xml \
    GALAXY_CONFIG_WATCH_TOOL_DATA_DIR=True \
    GALAXY_CONFIG_TOOL_DEPENDENCY_DIR=$EXPORT_DIR/tool_deps \
    GALAXY_CONFIG_TOOL_PATH=$EXPORT_DIR/galaxy-central/tools \
    GALAXY_VIRTUAL_ENV=/galaxy_venv \
    GALAXY_USER=galaxy \
    GALAXY_UID=1450 \
    GALAXY_GID=1450 \
    GALAXY_POSTGRES_UID=1550 \
    GALAXY_POSTGRES_GID=1550 \
    GALAXY_HOME=/home/galaxy \
    GALAXY_LOGS_DIR=/home/galaxy/logs \
    GALAXY_DEFAULT_ADMIN_USER=admin \
    GALAXY_DEFAULT_ADMIN_EMAIL=admin@galaxy.org \
    GALAXY_DEFAULT_ADMIN_PASSWORD=password \
    GALAXY_DEFAULT_ADMIN_KEY=fakekey \
    GALAXY_DESTINATIONS_DEFAULT=slurm_cluster \
    GALAXY_RUNNERS_ENABLE_SLURM=True \
    GALAXY_RUNNERS_ENABLE_CONDOR=False \
    GALAXY_CONFIG_DATABASE_CONNECTION=postgresql://galaxy:galaxy@localhost:5432/galaxy?client_encoding=utf8 \
    GALAXY_CONFIG_ADMIN_USERS=admin@galaxy.org \
    GALAXY_CONFIG_MASTER_API_KEY=HSNiugRFvgT574F43jZ7N9F3 \
    GALAXY_CONFIG_BRAND="Galaxy Docker Build" \
    GALAXY_CONFIG_STATIC_ENABLED=False \
    # Define the default postgresql database path
    PG_DATA_DIR_DEFAULT=/var/lib/postgresql/$PG_VERSION/main/ \
    PG_CONF_DIR_DEFAULT=/etc/postgresql/$PG_VERSION/main/ \
    PG_DATA_DIR_HOST=$EXPORT_DIR/postgresql/$PG_VERSION/main/ \
    # The following 2 ENV vars can be used to set the number of uwsgi processes and threads
    UWSGI_PROCESSES=2 \
    UWSGI_THREADS=4 \
    # Set HTTPS to use a self-signed certificate (or your own certificate in $EXPORT_DIR/{server.key,server.crt})
    USE_HTTPS=False \
    # Set USE_HTTPS_LENSENCRYPT and GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL to a domain that is reachable to get a letsencrypt certificate
    USE_HTTPS_LETSENCRYPT=False \
    GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL=http://localhost \
    # Set the number of Galaxy handlers
    GALAXY_HANDLER_NUMPROCS=2 \
    # Setting a standard encoding. This can get important for things like the unix sort tool.
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    NODE_OPTIONS=--max-old-space-size=4096 \
    GALAXY_CONDA_PREFIX=/tool_deps/_conda

# 16MB
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
    && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache \
    && apt-get -qq update && apt-get install --no-install-recommends -y locales \
    && locale-gen en_US.UTF-8 && dpkg-reconfigure locales \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache/ \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* /galaxy-central/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm/

# Create the postgres user before apt-get does (with the configured UID/GID) to facilitate sharing $EXPORT_DIR/postgresql with non-Linux hosts
RUN groupadd -r postgres -g $GALAXY_POSTGRES_GID \
    && adduser --system --quiet --home /var/lib/postgresql --no-create-home --shell /bin/bash --gecos "" --uid $GALAXY_POSTGRES_UID --gid $GALAXY_POSTGRES_GID postgres \
    && apt-get -qq update && apt-get install --no-install-recommends -y software-properties-common gpg-agent curl sudo \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && sudo add-apt-repository ppa:natefoo/slurm-drmaa \
    && apt-get update -qq \
    ## && apt-get purge -y software-properties-common gpg-agent \
    ## && apt-get install postgresql-10 --no-install-recommends -y \
    && apt-get install nginx-extras nginx-common --no-install-recommends -y \
    && apt-get install docker-ce-cli --no-install-recommends -y \
    && apt-get install slurm-client slurmd slurmctld slurm-drmaa1 --no-install-recommends -y \
    && ln -s /usr/lib/slurm-drmaa/lib/libdrmaa.so.1 /usr/lib/slurm-drmaa/lib/libdrmaa.so \
    && apt-get install proftpd proftpd-mod-pgsql --no-install-recommends -y \
    && apt-get install munge libmunge-dev --no-install-recommends -y \
    && apt-get install nano --no-install-recommends -y \
    && apt-get install htcondor --no-install-recommends -y \
    && apt-get install git --no-install-recommends -y \
    && apt-get install gridengine-common gridengine-drmaa1.0 --no-install-recommends -y \
    && apt-get install rabbitmq-server --no-install-recommends -y \
    && apt-get install --no-install-recommends -y libswitch-perl supervisor \
    && apt-get purge -y software-properties-common gpg-agent apt-transport-https python3-minimal  \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && rm -rf ~/.cache/ \
    && mkdir -p /etc/supervisor/conf.d/ /var/log/supervisor/ \
    # we will recreate this later
    ## && rm -rf $PG_DATA_DIR_DEFAULT \
    && groupadd -r $GALAXY_USER -g $GALAXY_GID \
    && useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" --shell /bin/bash $GALAXY_USER \
    && mkdir $EXPORT_DIR $GALAXY_HOME $GALAXY_LOGS_DIR && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $EXPORT_DIR $GALAXY_LOGS_DIR \
    # cleanup dance
    && find /usr/lib/ -name '*.pyc' -delete \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm/

ADD ./bashrc $GALAXY_HOME/.bashrc

# Install miniconda, then virtualenv from conda and then
# download latest stable release of Galaxy.

RUN curl -s -L https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.3-Linux-x86_64.sh > ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p $GALAXY_CONDA_PREFIX/ \
    && rm ~/miniconda.sh \
    && ln -s $GALAXY_CONDA_PREFIX/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". $GALAXY_CONDA_PREFIX/etc/profile.d/conda.sh" >> $GALAXY_HOME/.bashrc \
    && echo "conda activate base" >> $GALAXY_HOME/.bashrc \
    && export PATH=$GALAXY_CONDA_PREFIX/bin/:$PATH \
    && conda config --add channels defaults \
    && conda config --add channels bioconda \
    && conda config --add channels conda-forge \
    && conda install virtualenv pip ephemeris \
    && chown $GALAXY_USER:$GALAXY_USER -R /tool_deps/ /etc/profile.d/conda.sh \
    && conda clean --packages -t -i \
    # cleanup dance
    && find $GALAXY_ROOT -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm


RUN cp $GALAXY_HOME/.bashrc ~/
RUN mkdir $GALAXY_ROOT \
    && curl -L -s $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT \
    && PATH=$GALAXY_CONDA_PREFIX/bin/:$PATH virtualenv $GALAXY_VIRTUAL_ENV \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_VIRTUAL_ENV \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_ROOT \
    # Setup Galaxy configuration files.
    && mkdir -p $GALAXY_CONFIG_DIR $GALAXY_CONFIG_DIR/web \
    && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_CONFIG_DIR \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm \
    && su $GALAXY_USER -c "cp $GALAXY_ROOT/config/galaxy.yml.sample $GALAXY_CONFIG_FILE" \
    # cleanup dance
    && find $GALAXY_ROOT -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm


ADD ./reports_wsgi.ini.sample $GALAXY_CONFIG_DIR/reports_wsgi.ini
ADD sample_tool_list.yaml $GALAXY_HOME/ephemeris/sample_tool_list.yaml
ADD roles/ /ansible/roles
ADD provision.yml /ansible/provision.yml
ADD postgresql_provision.yml /ansible/postgresql_provision.yml

## This is playbook is modifying/installing python2 and python3 stuff
RUN apt update -qq && apt install --no-install-recommends -y ansible dirmngr gpg gpg-agent \
    && ansible-playbook /ansible/postgresql_provision.yml \
    && apt purge ansible dirmngr gpg gpg-agent -y && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # cleanup dance
    && find $GALAXY_ROOT/ -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm


# Include all needed scripts from the host
ADD ./setup_postgresql.py /usr/local/bin/setup_postgresql.py

# Configure PostgreSQL
# 1. Remove all old configuration
# 2. Create DB-user 'galaxy' with password 'galaxy' in database 'galaxy'
# 3. Create Galaxy Admin User 'admin@galaxy.org' with password 'admin' and API key 'admin'

RUN mkdir -p /shed_tools $EXPORT_DIR/ftp/ \
    && chown $GALAXY_USER:$GALAXY_USER /shed_tools $EXPORT_DIR/ftp \
    && ln -s /tool_deps/ $EXPORT_DIR/tool_deps \
    # Configure Galaxy to use the Tool Shed
    && chown $GALAXY_USER:$GALAXY_USER $EXPORT_DIR/tool_deps \
    && apt update -qq && apt install --no-install-recommends -y ansible \
    && ansible-playbook /ansible/provision.yml \
    --extra-vars galaxy_venv_dir=$GALAXY_VIRTUAL_ENV \
    --extra-vars galaxy_log_dir=$GALAXY_LOGS_DIR \
    --extra-vars galaxy_user_name=$GALAXY_USER \
    --extra-vars galaxy_config_file=$GALAXY_CONFIG_FILE \
    --extra-vars galaxy_config_dir=$GALAXY_CONFIG_DIR \
    --extra-vars galaxy_job_conf_path=$GALAXY_CONFIG_JOB_CONFIG_FILE \
    --extra-vars galaxy_job_metrics_conf_path=$GALAXY_CONFIG_JOB_METRICS_CONFIG_FILE \
    --extra-vars supervisor_manage_slurm="" \
    --extra-vars galaxy_extras_config_condor=True \
    --extra-vars galaxy_extras_config_condor_docker=True \
    --extra-vars galaxy_extras_config_rabbitmq=True \
    --extra-vars galaxy_extras_config_cvmfs=True \
    --extra-vars galaxy_extras_config_uwsgi=False \
    --extra-vars proftpd_db_connection=galaxy@galaxy \
    --extra-vars proftpd_files_dir=$EXPORT_DIR/ftp \
    --extra-vars proftpd_use_sftp=True \
    --extra-vars galaxy_extras_docker_legacy=False \
    --extra-vars galaxy_minimum_version=19.01 \
    --extra-vars supervisor_postgres_config_path=$PG_CONF_DIR_DEFAULT/postgresql.conf \
    --extra-vars supervisor_postgres_autostart=false \
    --extra-vars nginx_use_remote_header=True \
    --tags=galaxyextras,cvmfs -c local \
    && . $GALAXY_VIRTUAL_ENV/bin/activate \
    && pip install WeasyPrint \
    && deactivate \
    # TODO: no clue why this is needed here again
    && cd $GALAXY_ROOT && ./scripts/common_startup.sh \
    && cd config && find . -name 'node_modules' -type d -prune -exec rm -rf '{}' + \
    && find . -name '.cache' -type d -prune -exec rm -rf '{}' + \
    && cd / \
    && rm $PG_DATA_DIR_DEFAULT -rf \
    && python /usr/local/bin/setup_postgresql.py --dbuser galaxy --dbpassword galaxy --db-name galaxy --dbpath $PG_DATA_DIR_DEFAULT --dbversion $PG_VERSION \
    && service postgresql start \
    && service postgresql stop \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && rm -rf ~/.cache/ \
    # cleanup dance
    && find $GALAXY_ROOT/ -name '*.pyc' -delete | true \
    && find /usr/lib/ -name '*.pyc' -delete | true \
    && find /var/log/ -name '*.log' -delete | true \
    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    && rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm

RUN touch /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog && \
    mkdir -p /var/run/condor/ /var/lock/condor/ && \
    chown -R condor: /var/log/condor/StartLog /var/log/condor/StarterLog /var/log/condor/CollectorLog /var/log/condor/NegotiatorLog /var/run/condor/ /var/lock/condor/

# The following commands will be executed as the galaxy user
USER $GALAXY_USER

WORKDIR $GALAXY_ROOT

# Updating genome informations from UCSC
#RUN export GALAXY=$GALAXY_ROOT && sh ./cron/updateucsc.sh.sample

ENV GALAXY_CONFIG_JOB_WORKING_DIRECTORY=$EXPORT_DIR/galaxy-central/database/job_working_directory \
    GALAXY_CONFIG_FILE_PATH=$EXPORT_DIR/galaxy-central/database/files \
    GALAXY_CONFIG_NEW_FILE_PATH=$EXPORT_DIR/galaxy-central/database/files \
    GALAXY_CONFIG_TEMPLATE_CACHE_PATH=$EXPORT_DIR/galaxy-central/database/compiled_templates \
    GALAXY_CONFIG_CITATION_CACHE_DATA_DIR=$EXPORT_DIR/galaxy-central/database/citations/data \
    GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY=$EXPORT_DIR/galaxy-central/database/pbs \
    GALAXY_CONFIG_FTP_UPLOAD_DIR=$EXPORT_DIR/ftp \
    GALAXY_CONFIG_FTP_UPLOAD_SITE=galaxy.docker.org \
    GALAXY_CONFIG_USE_PBKDF2=False \
    GALAXY_CONFIG_NGINX_X_ACCEL_REDIRECT_BASE=/_x_accel_redirect \
    GALAXY_CONFIG_NGINX_X_ARCHIVE_FILES_BASE=/_x_accel_redirect \
    GALAXY_CONFIG_DYNAMIC_PROXY_MANAGE=False \
    GALAXY_CONFIG_VISUALIZATION_PLUGINS_DIRECTORY=config/plugins/visualizations \
    GALAXY_CONFIG_TRUST_IPYTHON_NOTEBOOK_CONVERSION=True \
    GALAXY_CONFIG_TOOLFORM_UPGRADE=True \
    GALAXY_CONFIG_SANITIZE_ALL_HTML=False \
    GALAXY_CONFIG_TOOLFORM_UPGRADE=True \
    GALAXY_CONFIG_WELCOME_URL=$GALAXY_CONFIG_DIR/web/welcome.html \
    GALAXY_CONFIG_OVERRIDE_DEBUG=False \
    GALAXY_CONFIG_ENABLE_QUOTAS=True \
    # We need to set $HOME for some Tool Shed tools (e.g Perl libs with $HOME/.cpan)
    HOME=$GALAXY_HOME \
    GALAXY_CONDA_PREFIX=$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR/_conda

# Container Style
ADD GalaxyDocker.png $GALAXY_CONFIG_DIR/web/welcome_image.png
ADD welcome.html $GALAXY_CONFIG_DIR/web/welcome.html

#RUN ./scripts/common_startup.sh \
#    && export PATH=GALAXY_CONDA_PREFIX/bin/:$PATH \
#    && . $GALAXY_VIRTUAL_ENV/bin/activate \
#    && python ./scripts/manage_tool_dependencies.py -c "$GALAXY_CONFIG_FILE" init_if_needed \
#    # cleanup dance
#    && find $GALAXY_ROOT/ -name '*.pyc' -delete \
#    && find /usr/lib/ -name '*.pyc' -delete \
#    && find $GALAXY_CONDA_PREFIX/ -name '*.pyc' -delete \
#    && find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete \
#    && rm -rf /tmp/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm

# Install all required Node dependencies. This is required to get proxy support to work for Interactive Environments
#cd $GALAXY_ROOT/lib/galaxy/web/proxy/js && \
#npm install && \
#rm -rf ~/.cache/ $GALAXY_ROOT/client/node_modules/

# Switch back to User root
USER root


# Activate additional Tool Sheds
# Activate the Test Tool Shed during runtime, useful for testing repositories.
ADD ./tool_sheds_conf.xml $GALAXY_HOME/tool_sheds_conf.xml

# Script that enables easier downstream installation of tools (e.g. for different Galaxy Docker flavours)
ADD install_tools_wrapper.sh /usr/bin/install-tools
# script to install BioJS visualizations
ADD install_biojs_vis.sh /usr/bin/install-biojs
RUN chmod +x /usr/bin/install-tools /usr/bin/install-biojs && \
    cd /usr/bin/ && curl https://git.embl.de/grp-gbcs/galaxy-dir-sync/raw/master/src/galaxy-dir-sync.py > galaxy-dir-sync.py && \
    chmod +x galaxy-dir-sync.py

RUN echo "DISCARD_SESSION_KEYRING_ON_STARTUP=False" > /etc/condor/condor_config.local && \
    echo "TRUST_UID_DOMAIN=true" >> /etc/condor/condor_config.local

# use https://github.com/krallin/tini/ as tiny but valid init and PID 1
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /sbin/tini
RUN chmod +x /sbin/tini

# This needs to happen here and not above, otherwise the Galaxy start
# (without running the startup.sh script) will crash because integrated_tool_panel.xml could not be found.
ENV GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG $EXPORT_DIR/galaxy-central/integrated_tool_panel.xml

# Expose port 80, 443 (webserver), 21 (FTP server), 8800 (Proxy), 9002 (supvisord web app)
EXPOSE :21
EXPOSE :80
EXPOSE :443
EXPOSE :8800
EXPOSE :9002

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

ADD startup.sh /usr/bin/startup
ENV SUPERVISOR_POSTGRES_AUTOSTART=True \
    SUPERVISOR_MANAGE_POSTGRES=True \
    SUPERVISOR_MANAGE_CRON=True \
    SUPERVISOR_MANAGE_PROFTP=True \
    SUPERVISOR_MANAGE_REPORTS=True \
    SUPERVISOR_MANAGE_IE_PROXY=True \
    SUPERVISOR_MANAGE_CONDOR=True \
    SUPERVISOR_MANAGE_SLURM= \
    HOST_DOCKER_LEGACY= \
    GALAXY_EXTRAS_CONFIG_POSTGRES=True \
    STARTUP_EXPORT_USER_FILES=True

ENTRYPOINT ["/sbin/tini", "--"]

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
