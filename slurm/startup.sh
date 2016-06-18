#!/usr/bin/env bash

# Setup the galaxy user UID/GID and pass control on to supervisor
if [ -f /export/munge.key ]
  then cp /export/munge.key /etc/munge/munge.key
else
  cp /etc/munge/munge.key /export/munge.key
fi

if [ -f /export/slurm.conf ]
  then cp /export/slurm.conf /etc/slurm-llnl/slurm.conf
else
  python /usr/local/bin/configure_slurm.py
  cp /etc/slurm-llnl/slurm.conf /export/slurm.conf
fi
usermod -u $GALAXY_UID  galaxy
groupmod -g $GALAXY_GID galaxy
chown galaxy /tmp/slurm
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

