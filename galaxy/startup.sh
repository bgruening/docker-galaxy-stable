#!/bin/bash

cd /galaxy-central/
# If /export/ is mounted, export_user_files file moving all data to /export/
# symlinks will point from the original location to the new path under /export/
# If /export/ is not given, nothing will happen in that step
python ./export_user_files.py $PG_DATA_DIR_DEFAULT
service postgresql start
# start Galaxy
./run.sh --daemon
# start Apache in Foreground, that is needed for Docker
apache2 -D FOREGROUND
