#!/bin/bash

echo "
CONDOR_HOST = $CONDOR_HOST
DAEMON_LIST = MASTER, STARTD
DISCARD_SESSION_KEYRING_ON_STARTUP=False
TRUST_UID_DOMAIN=true

# Disable cgroup support by defining the base cgroup as an empty string
BASE_CGROUP=

#ALLOW_ADMINISTRATOR = \$(CONDOR_HOST)
#ALLOW_OWNER = \$(FULL_HOSTNAME), \$(ALLOW_ADMINISTRATOR)
ALLOW_ADMINISTRATOR = *
ALLOW_OWNER = *
ALLOW_READ = *
ALLOW_WRITE = *
ALLOW_CLIENT = *
ALLOW_NEGOTIATOR_SCHEDD = *
ALLOW_WRITE_COLLECTOR = *
ALLOW_WRITE_STARTD    = *
ALLOW_READ_COLLECTOR  = *
ALLOW_READ_STARTD     = *
UID_DOMAIN = galaxy



DOCKER_VOLUMES = DOCKER_IN

#Define a mount point for each volume:
DOCKER_VOLUME_DIR_DOCKER_IN = /export:/export/:rw
#DOCKER_VOLUME_DIR_DOCKER_OUT = /export:/export:rw

#Configure those volumes to be mounted on each Docker container:
DOCKER_MOUNT_VOLUMES = DOCKER_IN



SCHED_NAME = $CONDOR_HOST
" > /etc/condor/condor_config.local

sudo -u condor touch /var/log/condor/StartLog
sudo -u condor touch /var/log/condor/StarterLog
tail -f -n 1000 /var/log/condor/StartLog /var/log/condor/StarterLog &

# Mysterious bug? Docker doesn't output its version as condor user if this is not executed before
docker -v

/usr/sbin/condor_master -pidfile /var/run/condor/condor.pid -f -t
