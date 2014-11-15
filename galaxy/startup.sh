#!/bin/bash

cd /galaxy-central/
# If /export/ is mounted, export_user_files file moving all data to /export/
# symlinks will point from the original location to the new path under /export/
# If /export/ is not given, nothing will happen in that step
umount /var/lib/docker
python ./export_user_files.py $PG_DATA_DIR_DEFAULT

# Configure SLURM with runtime hostname.
python /usr/sbin/configure_slurm.py

if mount | grep "/proc/kcore"; then
    echo "Disable Galaxy Interactive Environments. Start with --privilegd to enable IE's."
    export GALAXY_CONFIG_INTERACTIVE_ENVIRONMENT_PLUGINS_DIRECTORY=""
    /usr/bin/supervisord
    sleep 5
else
    echo "Enable Galaxy Interactive Environments."
    export GALAXY_CONFIG_INTERACTIVE_ENVIRONMENT_PLUGINS_DIRECTORY="config/plugins/interactive_environments"
    bash /root/cgroupfs_mount.sh
    /usr/bin/supervisord
    sleep 5
    supervisorctl start docker
fi

if [ `echo ${GALAXY_LOGGING:-'no'} | tr [:upper:] [:lower:]` = "full" ]
    then 
        tail -f /root/*.log /var/log/supervisor/* /var/log/nginx/*
    else
        tail -f /root/*.log
fi
