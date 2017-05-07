# Galaxy - Stable
#
# VERSION       Galaxy-central

FROM toolshed/requirements

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

ARG ANSIBLE_REPO=galaxyproject/ansible-galaxy-extras
ARG ANSIBLE_RELEASE=4b6344450ccd50d0b26806f3e0c1ed39b45aaeee

ENV GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450 \
GALAXY_HOME=/home/galaxy \
GALAXY_LOGS_DIR=/home/galaxy/logs \
GALAXY_ROOT=/export/galaxy-central \
GALAXY_VIRTUAL_ENV=/export/venv \
EXPORT_DIR=/export \
# Setting a standard encoding. This can get important for things like the unix sort tool.
LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8

ENV \
GALAXY_CONFIG_FILE=/export/config/galaxy.ini \
GALAXY_CONFIG_STATIC_ENABLED=False \
GALAXY_CONFIG_DATABASE_CONNECTION=postgresql://localhost/galaxy?client_encoding=utf8 \
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
GALAXY_CONFIG_WELCOME_URL=/web/welcome.html \
NGINX_WELCOME_LOCATION=/web \
NGINX_WELCOME_PATH=/export/welcome \
GALAXY_CONFIG_OVERRIDE_DEBUG=False \
GALAXY_CONFIG_FILE_PATH=$GALAXY_ROOT/database/files \
GALAXY_CONFIG_NEW_FILE_PATH=$GALAXY_ROOT/database/files \
GALAXY_CONFIG_OVERRIDE_DEBUG=False \
GALAXY_CONDA_PREFIX=/export/tool_deps/_conda \
GALAXY_CONFIG_BRAND="Galaxy Docker Build" \
GALAXY_CONFIG_TOOL_DEPENDENCY_DIR=/export/tool_deps \
GALAXY_CONFIG_JOB_WORKING_DIRECTORY=$GALAXY_ROOT/database/job_working_directory \
# We need to set $HOME for some Tool Shed tools (e.g Perl libs with $HOME/.cpan)
HOME=$GALAXY_HOME

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

RUN apt-get -qq update && apt-get install --no-install-recommends -y apt-transport-https software-properties-common wget && \
    sh -c "wget -qO- - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -" && \
    add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu trusty stable" && \
#    echo deb https://apt.dockerproject.org/repo ubuntu-trusty main > /etc/apt/sources.list.d/docker.list && \
    sh -c "echo deb http://research.cs.wisc.edu/htcondor/ubuntu/stable/ trusty contrib > /etc/apt/sources.list.d/htcondor.list" && \
    sh -c "wget -qO - http://research.cs.wisc.edu/htcondor/ubuntu/HTCondor-Release.gpg.key | sudo apt-key add -" && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-get update -qq && apt-get upgrade -y && \
    apt-get install --no-install-recommends -y mercurial libpq-dev python-psycopg2 sudo samtools python-virtualenv \
    uwsgi uwsgi-plugin-python supervisor \
    docker-ce linux-image-extra-virtual \
    slurm-llnl slurm-llnl-torque libswitch-perl \
    slurm-drmaa-dev libyaml-dev nodejs-legacy npm ansible pbs-drmaa-dev \
    nano nmap lynx vim curl python-crypto python-pip python-gnuplot python-rpy2 python-psutil condor python-ldap \
    gridengine-common gridengine-drmaa1.0 && \
    pip install --upgrade pip && \
    pip install ephemeris && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
    mkdir $EXPORT_DIR $GALAXY_HOME $GALAXY_LOGS_DIR && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $GALAXY_LOGS_DIR $EXPORT_DIR && \
    gpasswd -a $GALAXY_USER docker && \
    adduser condor docker
ADD ./bashrc $GALAXY_HOME/.bashrc

# Container Style
ADD condor_config.local /etc/condor/condor_config.local
# fetch ansible galaxy extras
RUN mkdir -p /ansible/galaxyprojectdotorg.galaxyextras && cd /ansible/galaxyprojectdotorg.galaxyextras && wget -pO- https://api.github.com/repos/$ANSIBLE_REPO/tarball/$ANSIBLE_RELEASE | tar xvz --strip-components=1
ADD provision.yml /ansible/provision.yml

# Install database script
ADD ./install_db.sh /usr/bin/install_db.sh

# script to install BioJS visualizations
ADD install_biojs_vis.sh /usr/bin/install-biojs

ADD startup.sh /usr/bin/startup

# Make scripts runnable
RUN chmod +x /usr/bin/install_db.sh /usr/bin/startup /usr/bin/install-biojs

# This needs to happen here and not above, otherwise the Galaxy start
# (without running the startup.sh script) will crash because integrated_tool_panel.xml could not be found.
ENV GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG=/export/galaxy-central/integrated_tool_panel.xml

# Create symlinks for export, the destination will be created by galaxy-init
# TODO: Is this even required?
RUN ln -s -f /export/shed_tools /shed_tools && \
    ln -s -f /export/tool_deps /tool_deps && \
#    ln -s -f /export/var/lib/docker /var/lib/docker && \
    ln -s -f /export/galaxy-central /galaxy-central && \
    ln -s -f /export/venv /galaxy_venv && \
    mkdir /etc/galaxy && ln -s -f /export/welcome /etc/galaxy/web

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
