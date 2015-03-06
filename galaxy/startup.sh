#!/bin/bash

cd /galaxy-central/
# If /export/ is mounted, export_user_files file moving all data to /export/
# symlinks will point from the original location to the new path under /export/
# If /export/ is not given, nothing will happen in that step
umount /var/lib/docker
python /usr/local/bin/export_user_files.py $PG_DATA_DIR_DEFAULT

# Configure SLURM with runtime hostname.
python /usr/sbin/configure_slurm.py

# Try to guess if we are running under --privileged mode
if mount | grep "/proc/kcore"; then
    echo "Disable Galaxy Interactive Environments. Start with --privileged to enable IE's."
    export GALAXY_CONFIG_INTERACTIVE_ENVIRONMENT_PLUGINS_DIRECTORY=""
    /usr/bin/supervisord
    sleep 5
else
    echo "Enable Galaxy Interactive Environments."
    export GALAXY_CONFIG_INTERACTIVE_ENVIRONMENT_PLUGINS_DIRECTORY="config/plugins/interactive_environments"
    if [ x$DOCKER_PARENT == "x" ]; then 
        #build the docker in docker environment
        bash /root/cgroupfs_mount.sh
        /usr/bin/supervisord
        sleep 5
        supervisorctl start docker
    else
        #inheriting /var/run/docker.sock from parent, assume that you need to
        #run docker with sudo to validate
        echo "galaxy ALL = NOPASSWD : ALL" >> /etc/sudoers
        /usr/bin/supervisord
        sleep 5
    fi
fi

if [ `echo ${GALAXY_LOGGING:-'no'} | tr [:upper:] [:lower:]` = "full" ]
    then
        tail -f /var/log/supervisor/* /var/log/nginx/* /home/galaxy/*.log
    else
        tail -f /home/galaxy/*.log
fi

if [ "x$DISABLE_REPORTS_AUTH" == "x" ]
    then
        # Authentification is enabled by default. There should be /etc/nginx/htpasswd file.
    else
        # disable authentification by deleting the htpasswd file
        rm /etc/nginx/htpasswd
fi


