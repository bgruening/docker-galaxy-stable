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
ALLOW_READ = *
ALLOW_WRITE = *
ALLOW_CLIENT = *
SCHED_NAME = $CONDOR_HOST
" > /etc/condor/condor_config.local

sudo -u condor touch /var/log/condor/StartLog
sudo -u condor touch /var/log/condor/StarterLog
tail -f -n 1000 /var/log/condor/StartLog /var/log/condor/StarterLog &

/usr/sbin/condor_master -pidfile /var/run/condor/condor.pid -f -t
