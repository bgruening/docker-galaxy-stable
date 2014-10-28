# Galaxy - Stable
#
# VERSION       0.2.0

FROM ubuntu:14.04

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

# * Make sure the package repository is up to date
# * Install all requirements that are recommend by the Galaxy project
# * Enable the @natefoo magic
# Web server infrastructure matching usegalaxy.org - supervisor, uwsgi, and nginx.

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get install --no-install-recommends -y apt-transport-https  software-properties-common && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9 && \
    sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list" && \
    apt-get update -qq && apt-get upgrade -y && \
    add-apt-repository ppa:galaxyproject/nginx && apt-get -qq update && \
    apt-get purge -y software-properties-common && \
    apt-get install --no-install-recommends -y autoconf automake build-essential gfortran cmake \
    git-core libatlas-base-dev libblas-dev liblapack-dev mercurial subversion python-dev pkg-config \
    openjdk-7-jre-headless python-setuptools python-psycopg2 postgresql-9.3 sudo samtools python-virtualenv \
    nginx-extras uwsgi uwsgi-plugin-python supervisor lxc-docker slurm-llnl slurm-llnl-torque \
     slurm-drmaa-dev zlib1g-dev proftpd proftpd-mod-pgsql && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and update Galaxy to the latest stable release
RUN hg clone https://bitbucket.org/galaxy/galaxy-central/ && \
    cd /galaxy-central/ && \
    hg update latest_2014.10.06 && \
    rm /galaxy-central/.hg/ -rf

WORKDIR /galaxy-central

# Configure Galaxy to use the Tool Shed
RUN cp /galaxy-central/config/galaxy.ini.sample /galaxy-central/config/galaxy.ini
RUN mkdir /shed_tools
RUN mkdir /galaxy-central/tool_deps

# Fetching all Galaxy python dependencies
RUN python scripts/fetch_eggs.py

# Updating genome informations from UCSC
RUN export GALAXY=/galaxy-central/ && sh ./cron/updateucsc.sh.sample

ENV GALAXY_CONFIG_DATABASE_CONNECTION postgresql://galaxy:galaxy@localhost:5432/galaxy
ENV GALAXY_CONFIG_TOOL_DEPENDENCY_DIR ./tool_deps
ENV GALAXY_CONFIG_ADMIN_USERS admin@galaxy.org
ENV GALAXY_CONFIG_MASTER_API_KEY HSNiugRFvgT574F43jZ7N9F3
ENV GALAXY_CONFIG_BRAND Galaxy Docker Build
ENV GALAXY_CONFIG_STATIC_ENABLED False
ENV GALAXY_CONFIG_JOB_WORKING_DIRECTORY /export/galaxy-central/database/job_working_directory
ENV GALAXY_CONFIG_FILE_PATH /export/galaxy-central/database/files
ENV GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY /export/galaxy-central/database/pbs
ENV GALAXY_CONFIG_FTP_UPLOAD_DIR /export/galaxy-central/database/ftp
ENV GALAXY_CONFIG_FTP_UPLOAD_SITE galaxy.docker.org
ENV GALAXY_CONFIG_USE_PBKDF2 False
ENV GALAXY_CONFIG_NGINX_X_ACCEL_REDIRECT_BASE /_x_accel_redirect
ENV GALAXY_CONFIG_NGINX_UPLOAD_STORE database/tmp/upload_store
ENV GALAXY_CONFIG_NGINX_UPLOAD_PATH /_upload
ENV GALAXY_CONFIG_OVERRIDE_DEBUG False

# Define the default postgresql database path
ENV PG_DATA_DIR_DEFAULT /var/lib/postgresql/9.3/main/
ENV PG_DATA_DIR_HOST /export/postgresql/9.3/main/

# Setting a standard encoding. This can get important for things like the unix sort tool.
ENV LC_ALL en_US.utf-8
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

RUN virtualenv /root/venv

RUN mkdir -p /opt/nginx/conf
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./supervisor.conf /etc/supervisor/conf.d/galaxy.conf

ADD ./servers.ini /galaxy-central/config/servers.ini
RUN cat /galaxy-central/config/servers.ini >> /galaxy-central/config/galaxy.ini && rm /galaxy-central/config/servers.ini

ADD ./job_conf.xml /galaxy-central/config/job_conf.xml

ADD ./proftpd.conf /etc/proftpd/proftpd.conf
RUN echo 'LoadModule mod_sql.c' >> /etc/proftpd/modules.conf && \
    echo 'LoadModule mod_sql_passwd.c' >> /etc/proftpd/modules.conf && \
    echo 'LoadModule mod_sql_postgres.c' >> /etc/proftpd/modules.conf


# Include all needed scripts from the host
ADD ./setup_postgresql.py /galaxy-central/setup_postgresql.py
ADD ./create_galaxy_user.py /galaxy-central/create_galaxy_user.py
ADD ./export_user_files.py /galaxy-central/export_user_files.py

# Configure PostgreSQL
# 1. Remove all old configuration
# 2. Create DB-user 'galaxy' with password 'galaxy' in database 'galaxy'
# 3. Create Galaxy Admin User 'admin@galaxy.org' with password 'admin' and API key 'admin'
RUN service postgresql stop
RUN rm $PG_DATA_DIR_DEFAULT -rf
RUN python setup_postgresql.py --dbuser galaxy --dbpassword galaxy --db-name galaxy --dbpath $PG_DATA_DIR_DEFAULT
RUN service postgresql start && sh create_db.sh
RUN service postgresql start && sleep 5 && python create_galaxy_user.py --user admin@galaxy.org --password admin --key admin
RUN service postgresql start && sh run.sh --daemon && sleep 60 && sh run.sh --stop-daemon

# nginx and uwsgi Will be controller by supervisor
RUN update-rc.d -f uwsgi remove && update-rc.d -f nginx remove && update-rc.d -f proftpd remove

ADD ./startup.sh /usr/bin/startup
RUN chmod +x /usr/bin/startup

RUN mkdir /galaxy-central/database/job_working_directory/ /galaxy-central/database/files/

# This needs to happen here and not above, otherwise the Galaxy start 
# (without running the startup.sh script) will crash because integrated_tool_panel.xml could not be found.
ENV GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG /export/galaxy-central/integrated_tool_panel.xml


# Setup SLURM
# TODO use fixed key
RUN /usr/sbin/create-munge-key
RUN mkdir -p /var/run/munge && chown root:root /var/lib/munge/ /var/log/munge/ /var/run/munge /etc/munge/ /etc/munge/munge.key
ADD ./configure_slurm.py /usr/sbin/configure_slurm.py


# Expose port 80 to the host
EXPOSE :80
EXPOSE :21

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/"]

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
