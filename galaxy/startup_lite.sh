#!/bin/bash

cd /galaxy-central/

cp config/galaxy.ini.sample $GALAXY_CONFIG_FILE
export GALAXY_CONFIG_STATIC_ENABLED=True
export GALAXY_CONFIG_ALLOW_LIBRARY_PATH_PASTE=True
export GALAXY_CONFIG_JOB_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_conf_lite.xml
unset GALAXY_CONFIG_NGINX_UPLOAD_STORE
unset GALAXY_CONFIG_NGINX_UPLOAD_PATH

cat >> $GALAXY_CONFIG_FILE << _EOF
[server:main]
use = egg:Paste#http
port = 8080
host = 0.0.0.0
use_threadpool = True
threadpool_workers = 10
_EOF

service postgresql start
./run.sh --daemon
