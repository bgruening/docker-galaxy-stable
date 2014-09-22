# Galaxy - Stable
#
# VERSION       0.1.1

FROM ubuntu:14.04

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

# make sure the package repository is up to date
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq update

# Install all requirements that are recommend by the Galaxy project
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y autoconf
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y automake
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y build-essential
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y gfortran
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y cmake
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y git-core
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y libatlas-base-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y libblas-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y liblapack-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y mercurial
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y subversion
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y pkg-config
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y openjdk-7-jre-headless
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python-setuptools

# Help with Python
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python-virtualenv

# Enable the @natefoo magic... (software-properties-common required for add-apt-repository)
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y software-properties-common
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:natefoo/galaxy
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq update

# Web server infrastructure matching usegalaxy.org - supervisor, uwsgi, and nginx.
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y nginx-extras uwsgi uwsgi-plugin-python supervisor

# Setup Postgres
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y postgresql
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y sudo

# samtools is used to handle BAM files inside of Galaxy
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y samtools

# Download and update Galaxy to the latest stable release
RUN hg clone https://bitbucket.org/galaxy/galaxy-central/
WORKDIR /galaxy-central
RUN hg pull
RUN hg update latest_2014.08.11

# Configure Galaxy to use the Tool Shed
RUN cp ~/galaxy-central/universe_wsgi.ini.sample ~/galaxy-central/universe_wsgi.ini
RUN mkdir ~/shed_tools
RUN mkdir ~/galaxy-central/tool_deps

RUN sed -i 's|#database_connection.*|database_connection = postgresql://galaxy:galaxy@localhost:5432/galaxy|g' ~/galaxy-central/universe_wsgi.ini
RUN sed -i 's|#tool_dependency_dir = None|tool_dependency_dir = ./tool_deps|g' ~/galaxy-central/universe_wsgi.ini
RUN sed -i 's|#tool_config_file|tool_config_file|g' ~/galaxy-central/universe_wsgi.ini
RUN sed -i 's|#tool_path|tool_path|g' ~/galaxy-central/universe_wsgi.ini
RUN sed -i 's|#admin_users = None|admin_users = admin@galaxy.org|g' ~/galaxy-central/universe_wsgi.ini
RUN sed -i 's|#master_api_key=changethis|master_api_key=HSNiugRFvgT574F43jZ7N9F3|g' ~/galaxy-central/universe_wsgi.ini
RUN sed -i 's|#brand = None|brand = Galaxy Docker Build|g' ~/galaxy-central/universe_wsgi.ini
# debug = True is insecure and does not work with uwsgi very well.
RUN sed -i 's|debug = True|debug = False|g' ~/galaxy-central/universe_wsgi.ini

# Fetching all Galaxy python dependencies
RUN python scripts/fetch_eggs.py

# Define the default postgresql database path
# If you want to save your data locally you need to set GALAXY_DOCKER_MODE=HOST
ENV PG_DATA_DIR_DEFAULT /var/lib/postgresql/9.3/main/

# Include all needed scripts from the host
ADD ./setup_postgresql.py /galaxy-central/setup_postgresql.py
ADD ./create_galaxy_user.py /galaxy-central/create_galaxy_user.py
ADD ./export_user_files.py /galaxy-central/export_user_files.py
ADD ./startup.sh /usr/bin/startup

RUN chmod +x /usr/bin/startup
RUN service postgresql stop

# Configure PostgreSQL
# 1. Remove all old configuration
# 2. Create DB-user 'galaxy' with password 'galaxy' in database 'galaxy'
# 3. Create Galaxy Admin User 'admin@galaxy.org' with password 'admin' and API key 'admin'
RUN service postgresql stop
RUN rm $PG_DATA_DIR_DEFAULT -rf
RUN python setup_postgresql.py --dbuser galaxy --dbpassword galaxy --db-name galaxy --dbpath $PG_DATA_DIR_DEFAULT
RUN service postgresql start && sh create_db.sh
RUN service postgresql start && sleep 5 && python create_galaxy_user.py --user admin@galaxy.org --password admin --key admin
RUN service postgresql start && sh run.sh --daemon && sleep 120

# nginx and uwsgi Will be controller by supervisor
RUN update-rc.d -f uwsgi remove
RUN /etc/init.d/nginx stop
RUN update-rc.d -f nginx remove

RUN virtualenv /root/venv

RUN mkdir -p /opt/nginx/conf
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./supervisor.conf /etc/supervisor/conf.d/galaxy.conf

ADD ./servers.ini /galaxy-central/servers.ini
RUN cat /galaxy-central/servers.ini >> /galaxy-central/universe_wsgi.ini

# Expose port 80 to the host
EXPOSE :80

RUN rm ./.hg/ -rf
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Mark one folders as imported from the host.
VOLUME ["/export/"]

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
