# Galaxy - Stable
#
# VERSION       Galaxy-central

FROM toolshed/requirements

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

# * Make sure the package repository is up to date
# * Install all requirements that are recommend by the Galaxy project
# * Enable the @natefoo magic
# Web server infrastructure matching usegalaxy.org - supervisor, uwsgi, and nginx.

RUN apt-get -qq update && apt-get install --no-install-recommends -y apt-transport-https  software-properties-common && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9 && \
    sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list" && \
    apt-get update -qq && apt-get upgrade -y && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-add-repository -y ppa:galaxyproject/nginx && \
    apt-get -qq update && \
    apt-get purge -y software-properties-common && \
    apt-get install --no-install-recommends -y mercurial python-psycopg2 postgresql-9.3 sudo samtools python-virtualenv wget \ 
    nginx-extras uwsgi uwsgi-plugin-python supervisor lxc-docker slurm-llnl slurm-llnl-torque libswitch-perl \
    slurm-drmaa-dev proftpd proftpd-mod-pgsql libyaml-dev nodejs-legacy npm aufs-tools ansible \
    nano nmap lynx vim curl python-pip && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download latest stable release of Galaxy.
ENV GALAXY_RELEASE default
ENV GALAXY_ROOT /galaxy-central
ENV GALAXY_CONFIG_DIR /etc/galaxy
ENV GALAXY_CONFIG_FILE $GALAXY_CONFIG_DIR/galaxy.ini
ENV GALAXY_VIRTUALENV /home/galaxy/venv
ENV GALAXY_USER galaxy
ENV GALAXY_HOME /home/galaxy
ENV EXPORT_DIR /export

RUN groupadd -r $GALAXY_USER -g 450 && \
    useradd -u 451 -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
    mkdir $EXPORT_DIR $GALAXY_HOME && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $EXPORT_DIR && \
    gpasswd -a $GALAXY_USER docker

RUN mkdir $GALAXY_ROOT && wget -q -O - https://bitbucket.org/galaxy/galaxy-central/get/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_ROOT

# TODO: ensure virtualenv as part of galaxy role
RUN su $GALAXY_USER -c "virtualenv $GALAXY_VIRTUALENV"

# Setup Galaxy configuration files.
RUN mkdir -p $GALAXY_CONFIG_DIR && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_CONFIG_DIR

RUN su $GALAXY_USER -c "cp $GALAXY_ROOT/config/galaxy.ini.sample $GALAXY_CONFIG_FILE && \
                        cp $GALAXY_ROOT/config/reports_wsgi.ini.sample $GALAXY_CONFIG_DIR/reports_wsgi.ini"
ADD job_metrics_conf.xml $GALAXY_CONFIG_DIR/job_metrics_conf.xml
ADD ./servers.ini $GALAXY_CONFIG_DIR/servers.ini
RUN cat $GALAXY_CONFIG_DIR/servers.ini >> $GALAXY_CONFIG_FILE && rm $GALAXY_CONFIG_DIR/servers.ini
ADD roles/ /tmp/ansible/roles
ADD provision.yml /tmp/ansible/provision.yml
RUN ansible-playbook /tmp/ansible/provision.yml --extra-vars galaxy_user_name=$GALAXY_USER --extra-vars galaxy_config_file=$GALAXY_CONFIG_FILE --extra-vars galaxy_config_dir=$GALAXY_CONFIG_DIR --tags=galaxyextras -c local && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD roles/ /tmp/ansible/roles
ADD provision.yml /tmp/ansible/provision.yml

RUN mkdir /shed_tools && chown $GALAXY_USER:$GALAXY_USER /shed_tools

# The following commands will be executed as User galaxy
USER galaxy

WORKDIR /galaxy-central

# Configure Galaxy to use the Tool Shed
RUN mkdir $GALAXY_ROOT/tool_deps

# Fetching all Galaxy python dependencies
RUN . $GALAXY_VIRTUALENV/bin/activate && python scripts/fetch_eggs.py -c $GALAXY_CONFIG_FILE && python scripts/fetch_eggs.py -e drmaa -c $GALAXY_CONFIG_FILE

# Updating genome informations from UCSC
#RUN export GALAXY=/galaxy-central && sh ./cron/updateucsc.sh.sample

ENV GALAXY_CONFIG_DATABASE_CONNECTION postgresql://galaxy:galaxy@localhost:5432/galaxy
ENV GALAXY_CONFIG_TOOL_DEPENDENCY_DIR ./tool_deps
ENV GALAXY_CONFIG_ADMIN_USERS admin@galaxy.org
ENV GALAXY_CONFIG_MASTER_API_KEY HSNiugRFvgT574F43jZ7N9F3
ENV GALAXY_CONFIG_BRAND Galaxy Docker Build
ENV GALAXY_CONFIG_STATIC_ENABLED False
ENV GALAXY_CONFIG_JOB_WORKING_DIRECTORY /export/galaxy-central/database/job_working_directory
ENV GALAXY_CONFIG_FILE_PATH /export/galaxy-central/database/files
ENV GALAXY_CONFIG_NEW_FILE_PATH /export/galaxy-central/database/files
ENV GALAXY_CONFIG_TEMPLATE_CACHE_PATH /export/galaxy-central/database/compiled_templates
ENV GALAXY_CONFIG_CITATION_CACHE_DATA_DIR /export/galaxy-central/database/citations/data
ENV GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY /export/galaxy-central/database/pbs
ENV GALAXY_CONFIG_FTP_UPLOAD_DIR /export/galaxy-central/database/ftp
ENV GALAXY_CONFIG_FTP_UPLOAD_SITE galaxy.docker.org
ENV GALAXY_CONFIG_USE_PBKDF2 False
ENV GALAXY_CONFIG_NGINX_X_ACCEL_REDIRECT_BASE /_x_accel_redirect
ENV GALAXY_CONFIG_NGINX_X_ARCHIVE_FILES_BASE /_x_accel_redirect
ENV GALAXY_CONFIG_NGINX_UPLOAD_STORE /tmp/nginx_upload_store
ENV GALAXY_CONFIG_NGINX_UPLOAD_PATH /_upload
ENV GALAXY_CONFIG_DYNAMIC_PROXY_MANAGE False
ENV GALAXY_CONFIG_VISUALIZATION_PLUGINS_DIRECTORY config/plugins/visualizations
ENV GALAXY_CONFIG_TRUST_IPYTHON_NOTEBOOK_CONVERSION True
ENV GALAXY_CONFIG_TOOLFORM_UPGRADE True
# Next line allow child docker container for viz to find this docker container.
ENV GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL http://$HOST_IP/
ENV GALAXY_CONFIG_SANITIZE_ALL_HTML False
ENV GALAXY_CONFIG_TOOLFORM_UPGRADE True
ENV GALAXY_CONFIG_OVERRIDE_DEBUG False

# Define the default postgresql database path
ENV PG_DATA_DIR_DEFAULT /var/lib/postgresql/9.3/main/
ENV PG_DATA_DIR_HOST /export/postgresql/9.3/main/


# Install all required Node dependencies. This is required to get proxy support to work for Interactive Environments
RUN  cd /galaxy-central/lib/galaxy/web/proxy/js && npm install

# Container Style
ADD GalaxyDocker.png /galaxy-central/static/welcome/GalaxyDocker.png
ADD welcome.html /galaxy-central/static/welcome.html

# Switch back to User root
USER root

# Setting a standard encoding. This can get important for things like the unix sort tool.
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

# Include all needed scripts from the host
ADD ./setup_postgresql.py /galaxy-central/setup_postgresql.py
ADD ./export_user_files.py /galaxy-central/export_user_files.py

# Configure PostgreSQL
# 1. Remove all old configuration
# 2. Create DB-user 'galaxy' with password 'galaxy' in database 'galaxy'
# 3. Create Galaxy Admin User 'admin@galaxy.org' with password 'admin' and API key 'admin'
RUN service postgresql stop
RUN rm $PG_DATA_DIR_DEFAULT -rf
RUN python setup_postgresql.py --dbuser galaxy --dbpassword galaxy --db-name galaxy --dbpath $PG_DATA_DIR_DEFAULT
RUN service postgresql start && sh create_db.sh -c $GALAXY_CONFIG_FILE
ADD ./create_galaxy_user.py /galaxy-central/create_galaxy_user.py
RUN service postgresql start && sleep 5 && python create_galaxy_user.py --user admin@galaxy.org --password admin -c $GALAXY_CONFIG_FILE --key admin
RUN service postgresql start && sudo -u galaxy -i -- sh -c "cd /galaxy-central/ && sh run.sh --daemon && sleep 60 && sh run.sh --stop-daemon"

ADD ./startup.sh /usr/bin/startup
# Script that enables easier downstream installation of tools (e.g. for different Galaxy Docker flavours)
ADD install_repo_wrapper.sh /usr/bin/install-repository
RUN chmod +x /usr/bin/install-repository /usr/bin/startup

# This needs to happen here and not above, otherwise the Galaxy start 
# (without running the startup.sh script) will crash because integrated_tool_panel.xml could not be found.
ENV GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG /export/galaxy-central/integrated_tool_panel.xml

ADD ./cgroupfs_mount.sh /root/cgroupfs_mount.sh

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9001 (Galaxy report app)
EXPOSE :80
EXPOSE :21
EXPOSE :8800
EXPOSE :9001

# We need to set $HOME for some Tool Shed tools (e.g Perl libs with $HOME/.cpan)
ENV HOME /home/galaxy

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
