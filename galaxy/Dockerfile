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
    nginx-extras uwsgi uwsgi-plugin-python supervisor lxc-docker && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV DEBIAN_FRONTEND newt

# Download and update Galaxy to the latest stable release
RUN hg clone https://bitbucket.org/galaxy/galaxy-central/ && \
    cd /galaxy-central/ && \
    hg update next-stable && \
    rm /galaxy-central/.hg/ -rf

WORKDIR /galaxy-central

# Configure Galaxy to use the Tool Shed
RUN cp /galaxy-central/config/galaxy.ini.sample /galaxy-central/config/galaxy.ini
RUN mkdir /shed_tools
RUN mkdir /galaxy-central/tool_deps

# Fetching all Galaxy python dependencies
RUN python scripts/fetch_eggs.py

ENV GALAXY_CONFIG_DATABASE_CONNECTION postgresql://galaxy:galaxy@localhost:5432/galaxy
ENV GALAXY_CONFIG_TOOL_DEPENDENCY_DIR ./tool_deps
ENV GALAXY_CONFIG_ADMIN_USERS admin@galaxy.org
ENV GALAXY_CONFIG_MASTER_API_KEY HSNiugRFvgT574F43jZ7N9F3
ENV GALAXY_CONFIG_BRAND Galaxy Docker Build
ENV GALAXY_CONFIG_STATIC_ENABLED False
ENV GALAXY_CONFIG_OVERRIDE_DEBUG False
ENV GALAXY_CONFIG_JOB_WORKING_DIRECTORY /export/galaxy-central/database/job_working_directory
ENV GALAXY_CONFIG_FILE_PATH /export/galaxy-central/database/files
ENV GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY /export/galaxy-central/database/pbs

# Define the default postgresql database path
ENV PG_DATA_DIR_DEFAULT /var/lib/postgresql/9.3/main/
ENV PG_DATA_DIR_HOST /export/postgresql/9.3/main/

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
RUN update-rc.d -f uwsgi remove
RUN update-rc.d -f nginx remove

RUN virtualenv /root/venv

RUN mkdir -p /opt/nginx/conf
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./supervisor.conf /etc/supervisor/conf.d/galaxy.conf

ADD ./servers.ini /galaxy-central/config/servers.ini
RUN cat /galaxy-central/config/servers.ini >> /galaxy-central/config/galaxy.ini

ADD ./startup.sh /usr/bin/startup
RUN chmod +x /usr/bin/startup

RUN mkdir /galaxy-central/database/job_working_directory/ /galaxy-central/database/files/

# This needs to happen here and not above, otherwise the Galaxy start 
# (without running the startup.sh script) will crash because integrated_tool_panel.xml could not be found.
ENV GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG /export/galaxy-central/integrated_tool_panel.xml

# Expose port 80 to the host
EXPOSE :80


# Mark one folders as imported from the host.
VOLUME ["/export/"]

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
