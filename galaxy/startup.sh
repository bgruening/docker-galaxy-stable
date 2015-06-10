#!/bin/bash

cd /galaxy-central/
# If /export/ is mounted, export_user_files file moving all data to /export/
# symlinks will point from the original location to the new path under /export/
# If /export/ is not given, nothing will happen in that step
umount /var/lib/docker
python /usr/local/bin/export_user_files.py $PG_DATA_DIR_DEFAULT

#Copy or link the slurm/munge config files
if [ -e /export/slurm.conf ]
then
    rm -f /etc/slurm-llnl/slurm.conf
    ln -s /export/slurm.conf /etc/slurm-llnl/slurm.conf
else
    # Configure SLURM with runtime hostname.
    python /usr/sbin/configure_slurm.py
fi
if [ -e /export/munge.key ]
then
    rm -f /etc/munge/munge.key
    ln -s /export/munge.key /etc/munge/munge.key
    chmod 400 /export/munge.key
fi
#We need to run munged regardless
mkdir -p /var/run/munge && /usr/sbin/munged -f

# $NONUSE can be set to include proftp, reports or nodejs
# if included we will _not_ start these services.
function start_supervisor {
    /usr/bin/supervisord
    sleep 5
    if [[ $NONUSE != *"proftp"* ]]
    then
        echo "Starting ProFTP"
        supervisorctl start proftpd
    fi
    if [[ $NONUSE != *"reports"* ]]
    then
        echo "Starting Galaxy reports webapp"
        supervisorctl start reports
    fi
    if [[ $NONUSE != *"nodejs"* ]]
    then
        echo "Starting nodejs"
        supervisorctl start galaxy:galaxy_nodejs_proxy
    fi
    if [[ $NONUSE != *"slurmd"* ]]
    then
        echo "Starting slurmd"
        /usr/sbin/slurmd -D -L /home/galaxy/slurmd.log
    fi
    if [[ $NONUSE != *"slurmctld"* ]]
    then
        echo "Starting slurmctld"
        /usr/sbin/slurmctld -D -L /home/galaxy/slurmctld.log
    fi
}


# Try to guess if we are running under --privileged mode
if mount | grep "/proc/kcore"; then
    echo "Disable Galaxy Interactive Environments. Start with --privileged to enable IE's."
    export GALAXY_CONFIG_INTERACTIVE_ENVIRONMENT_PLUGINS_DIRECTORY=""
    start_supervisor
else
    echo "Enable Galaxy Interactive Environments."
    export GALAXY_CONFIG_INTERACTIVE_ENVIRONMENT_PLUGINS_DIRECTORY="config/plugins/interactive_environments"
    if [ x$DOCKER_PARENT == "x" ]; then 
        #build the docker in docker environment
        bash /root/cgroupfs_mount.sh
        start_supervisor
        supervisorctl start docker
    else
        #inheriting /var/run/docker.sock from parent, assume that you need to
        #run docker with sudo to validate
        echo "galaxy ALL = NOPASSWD : ALL" >> /etc/sudoers
        start_supervisor
    fi
fi

# Enable verbose output
if [ `echo ${GALAXY_LOGGING:-'no'} | tr [:upper:] [:lower:]` = "full" ]
    then
        tail -f /var/log/supervisor/* /var/log/nginx/* /home/galaxy/*.log
    else
        tail -f /home/galaxy/*.log
fi

# Disable authentication of Galaxy reports
if [ "x$DISABLE_REPORTS_AUTH" != "x" ]
    then
        # disable authentification by deleting the htpasswd file
        echo "Disable Galaxy reports authentification "
        rm /etc/nginx/htpasswd
fi


