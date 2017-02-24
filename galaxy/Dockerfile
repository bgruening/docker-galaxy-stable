# Galaxy - Stable
#
# VERSION       Galaxy-central

FROM toolshed/requirements

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

# * Make sure the package repository is up to date
# * Install all requirements that are recommend by the Galaxy project
# * Enable the @natefoo magic
# Web server infrastructure matching usegalaxy.org - supervisor, uwsgi, and nginx.

ARG GALAXY_RELEASE
ARG GALAXY_REPO

ENV GALAXY_RELEASE=${GALAXY_RELEASE:-release_17.01} \
GALAXY_REPO=${GALAXY_REPO:-https://github.com/galaxyproject/galaxy} \
GALAXY_ROOT=/galaxy-central \
GALAXY_CONFIG_DIR=/etc/galaxy

ENV GALAXY_CONFIG_FILE=$GALAXY_CONFIG_DIR/galaxy.ini \
GALAXY_CONFIG_JOB_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_conf.xml \
GALAXY_CONFIG_JOB_METRICS_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_metrics_conf.xml \
GALAXY_CONFIG_TOOL_DEPENDENCY_DIR=/export/tool_deps \
GALAXY_VIRTUAL_ENV=/galaxy_venv \
GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450 \
GALAXY_POSTGRES_UID=1550 \
GALAXY_POSTGRES_GID=1550 \
GALAXY_HOME=/home/galaxy \
GALAXY_LOGS_DIR=/home/galaxy/logs \
GALAXY_DEFAULT_ADMIN_USER=admin@galaxy.org \
GALAXY_DEFAULT_ADMIN_PASSWORD=admin \
GALAXY_DEFAULT_ADMIN_KEY=admin \
GALAXY_DESTINATIONS_DEFAULT=slurm_cluster \
# Define the default postgresql database path
PG_DATA_DIR_DEFAULT=/var/lib/postgresql/9.3/main/ \
PG_CONF_DIR_DEFAULT=/etc/postgresql/9.3/main/ \
PG_DATA_DIR_HOST=/export/postgresql/9.3/main/ \
EXPORT_DIR=/export \
# The following 2 ENV vars can be used to set the number of uwsgi processes and threads
UWSGI_PROCESSES=2 \
UWSGI_THREADS=4 \
# Set HTTPS to use a self-signed certificate (or your own certificate in /export/{server.key,server.crt})
USE_HTTPS=False \
# Set USE_HTTPS_LENSENCRYPT and GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL to a domain that is reachable to get a letsencrypt certificate
USE_HTTPS_LETSENCRYPT=False \
GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL=localhost \
# Set the number of Galaxy handlers
GALAXY_HANDLER_NUMPROCS=2 \
# Setting a standard encoding. This can get important for things like the unix sort tool.
LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales


# Create the postgres user before apt-get does (with the configured UID/GID) to facilitate sharing /export/postgresql with non-Linux hosts
RUN groupadd -r postgres -g $GALAXY_POSTGRES_GID && \
    adduser --system --quiet --home /var/lib/postgresql --no-create-home --shell /bin/bash --gecos "" --uid $GALAXY_POSTGRES_UID --gid $GALAXY_POSTGRES_GID postgres

RUN apt-get -qq update && apt-get install --no-install-recommends -y apt-transport-https software-properties-common wget && \
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
    sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list" && \
    sh -c "echo deb http://research.cs.wisc.edu/htcondor/ubuntu/stable/ trusty contrib > /etc/apt/sources.list.d/htcondor.list" && \
    sh -c "wget -qO - http://research.cs.wisc.edu/htcondor/ubuntu/HTCondor-Release.gpg.key | sudo apt-key add -" && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-add-repository -y ppa:galaxyproject/nginx && \
    apt-get update -qq && apt-get upgrade -y && \
    apt-get install --no-install-recommends -y mercurial python-psycopg2 postgresql-9.3 sudo samtools python-virtualenv \
    nginx-extras=1.4.6-1ubuntu3.4ppa1 nginx-common=1.4.6-1ubuntu3.4ppa1 uwsgi uwsgi-plugin-python supervisor lxc-docker-1.9.1 slurm-llnl slurm-llnl-torque libswitch-perl \
    slurm-drmaa-dev proftpd proftpd-mod-pgsql libyaml-dev nodejs-legacy npm ansible \
    nano nmap lynx vim curl python-crypto python-pip python-gnuplot python-rpy2 python-psutil condor python-ldap \
    gridengine-common gridengine-drmaa1.0 rabbitmq-server && \
    pip install --upgrade pip && \
    pip install ephemeris && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
    mkdir $EXPORT_DIR $GALAXY_HOME $GALAXY_LOGS_DIR && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $EXPORT_DIR $GALAXY_LOGS_DIR && \
    gpasswd -a $GALAXY_USER docker && \
    adduser condor docker
ADD ./bashrc $GALAXY_HOME/.bashrc

# Download latest stable release of Galaxy.
RUN mkdir $GALAXY_ROOT && \
    wget -q -O - $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT && \
    virtualenv $GALAXY_VIRTUAL_ENV && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_VIRTUAL_ENV && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_ROOT && \
    # Setup Galaxy configuration files.
    mkdir -p $GALAXY_CONFIG_DIR $GALAXY_CONFIG_DIR/web && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_CONFIG_DIR

RUN su $GALAXY_USER -c "cp $GALAXY_ROOT/config/galaxy.ini.sample $GALAXY_CONFIG_FILE"
ADD ./reports_wsgi.ini.sample $GALAXY_CONFIG_DIR/reports_wsgi.ini

ADD sample_tool_list.yaml $GALAXY_HOME/ephemeris/sample_tool_list.yaml
ADD roles/ /ansible/roles
ADD provision.yml /ansible/provision.yml
ADD postgresql_provision.yml /ansible/postgresql_provision.yml
RUN ansible-playbook /ansible/postgresql_provision.yml && \
    ansible-playbook /ansible/provision.yml \
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
    --extra-vars proftpd_db_connection=galaxy@galaxy \
    --extra-vars proftpd_files_dir=/export/ftp \
    --extra-vars proftpd_use_sftp=True \
    --extra-vars nginx_upload_store_path=/export/nginx_upload_store \
    --extra-vars supervisor_postgres_config_path=$PG_CONF_DIR_DEFAULT/postgresql.conf \
    --extra-vars supervisor_postgres_autostart=false \
    --tags=galaxyextras -c local && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /shed_tools && chown $GALAXY_USER:$GALAXY_USER /shed_tools && \
    mkdir /export/ftp/ && chown $GALAXY_USER:$GALAXY_USER /export/ftp && \
    mkdir /tool_deps/ && chown $GALAXY_USER:$GALAXY_USER /tool_deps && \
    ln -s /tool_deps/ /export/tool_deps && chown $GALAXY_USER:$GALAXY_USER /export/tool_deps # Configure Galaxy to use the Tool Shed

# The following commands will be executed as User galaxy
USER galaxy

WORKDIR $GALAXY_ROOT

# Updating genome informations from UCSC
#RUN export GALAXY=$GALAXY_ROOT && sh ./cron/updateucsc.sh.sample

ENV GALAXY_CONFIG_DATABASE_CONNECTION=postgresql://galaxy:galaxy@localhost:5432/galaxy?client_encoding=utf8 \
GALAXY_CONFIG_ADMIN_USERS=admin@galaxy.org \
GALAXY_CONFIG_MASTER_API_KEY=HSNiugRFvgT574F43jZ7N9F3 \
GALAXY_CONFIG_BRAND="Galaxy Docker Build" \
GALAXY_CONFIG_STATIC_ENABLED=False \
GALAXY_CONFIG_JOB_WORKING_DIRECTORY=/export/galaxy-central/database/job_working_directory \
GALAXY_CONFIG_FILE_PATH=/export/galaxy-central/database/files \
GALAXY_CONFIG_NEW_FILE_PATH=/export/galaxy-central/database/files \
GALAXY_CONFIG_TEMPLATE_CACHE_PATH=/export/galaxy-central/database/compiled_templates \
GALAXY_CONFIG_CITATION_CACHE_DATA_DIR=/export/galaxy-central/database/citations/data \
GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY=/export/galaxy-central/database/pbs \
GALAXY_CONFIG_FTP_UPLOAD_DIR=/export/ftp \
GALAXY_CONFIG_FTP_UPLOAD_SITE=galaxy.docker.org \
GALAXY_CONFIG_USE_PBKDF2=False \
GALAXY_CONFIG_NGINX_X_ACCEL_REDIRECT_BASE=/_x_accel_redirect \
GALAXY_CONFIG_NGINX_X_ARCHIVE_FILES_BASE=/_x_accel_redirect \
GALAXY_CONFIG_NGINX_UPLOAD_STORE=/export/nginx_upload_store \
GALAXY_CONFIG_NGINX_UPLOAD_PATH=/_upload \
GALAXY_CONFIG_DYNAMIC_PROXY_MANAGE=False \
GALAXY_CONFIG_VISUALIZATION_PLUGINS_DIRECTORY=config/plugins/visualizations \
GALAXY_CONFIG_TRUST_IPYTHON_NOTEBOOK_CONVERSION=True \
GALAXY_CONFIG_TOOLFORM_UPGRADE=True \
GALAXY_CONFIG_SANITIZE_ALL_HTML=False \
GALAXY_CONFIG_TOOLFORM_UPGRADE=True \
GALAXY_CONFIG_WELCOME_URL=$GALAXY_CONFIG_DIR/web/welcome.html \
GALAXY_CONFIG_OVERRIDE_DEBUG=False \
# We need to set $HOME for some Tool Shed tools (e.g Perl libs with $HOME/.cpan)
HOME=$GALAXY_HOME \
GALAXY_CONDA_PREFIX=$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR/_conda

# prefetch Python wheels
RUN ./scripts/common_startup.sh && \
    # Install all required Node dependencies. This is required to get proxy support to work for Interactive Environments
    cd $GALAXY_ROOT/lib/galaxy/web/proxy/js && \
    . "$GALAXY_VIRTUAL_ENV/bin/activate" && \
    python $GALAXY_ROOT/scripts/manage_tool_dependencies.py -c "$GALAXY_CONFIG_DIR/galaxy.ini" init_if_needed && \
    npm install

# Container Style
ADD GalaxyDocker.png $GALAXY_CONFIG_DIR/web/welcome_image.png
ADD welcome.html $GALAXY_CONFIG_DIR/web/welcome.html

# Switch back to User root
USER root

# Include all needed scripts from the host
ADD ./setup_postgresql.py /usr/local/bin/setup_postgresql.py

# Configure PostgreSQL
# 1. Remove all old configuration
# 2. Create DB-user 'galaxy' with password 'galaxy' in database 'galaxy'
# 3. Create Galaxy Admin User 'admin@galaxy.org' with password 'admin' and API key 'admin'

RUN rm $PG_DATA_DIR_DEFAULT -rf && \
    python /usr/local/bin/setup_postgresql.py --dbuser galaxy --dbpassword galaxy --db-name galaxy --dbpath $PG_DATA_DIR_DEFAULT && \
    service postgresql start && \
    . $GALAXY_VIRTUAL_ENV/bin/activate && \
    sh create_db.sh -c $GALAXY_CONFIG_FILE && \
    python /usr/local/bin/create_galaxy_user.py --user $GALAXY_DEFAULT_ADMIN_USER --password $GALAXY_DEFAULT_ADMIN_PASSWORD -c $GALAXY_CONFIG_FILE --key $GALAXY_DEFAULT_ADMIN_KEY && \
    service postgresql stop

# Activate additional Tool Sheds
# Activate the Test Tool Shed during runtime, useful for testing repositories.
ADD ./tool_sheds_conf.xml $GALAXY_HOME/tool_sheds_conf.xml
# Activate arbritrary Tool Sheds during build-time by manipulating the original tool_sheds_conf.xml file
ADD ./add_tool_shed.py /usr/bin/add-tool-shed

ADD ./startup_lite.sh /usr/bin/startup_lite
# Script that enables easier downstream installation of tools (e.g. for different Galaxy Docker flavours)
ADD install_tools_wrapper.sh /usr/bin/install-tools
# script to install BioJS visualizations
ADD install_biojs_vis.sh /usr/bin/install-biojs
RUN chmod +x /usr/bin/install-tools /usr/bin/startup /usr/bin/startup_lite /usr/bin/install-biojs /usr/bin/add-tool-shed

RUN echo "DISCARD_SESSION_KEYRING_ON_STARTUP=False" > /etc/condor/condor_config.local && \
    echo "TRUST_UID_DOMAIN=true" >> /etc/condor/condor_config.local

# This needs to happen here and not above, otherwise the Galaxy start
# (without running the startup.sh script) will crash because integrated_tool_panel.xml could not be found.
ENV GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG /export/galaxy-central/integrated_tool_panel.xml

# Expose port 80, 443 (webserver), 21 (FTP server), 8800 (Proxy), 9002 (supvisord web app)
EXPOSE :21
EXPOSE :80
EXPOSE :443
EXPOSE :8800
EXPOSE :9002

# Mark folders as imported from the host.
#VOLUME ["/export/", "/data/", "/var/lib/docker"]

ADD install_db.sh /usr/bin/install_db.sh
RUN chmod +x /usr/bin/install_db.sh

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
