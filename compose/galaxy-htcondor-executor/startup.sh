#!/bin/bash

echo "
CONDOR_HOST = $CONDOR_HOST
DAEMON_LIST = MASTER, STARTD
DISCARD_SESSION_KEYRING_ON_STARTUP=False
TRUST_UID_DOMAIN=true

NUM_SLOTS=1
NUM_SLOTS_TYPE_1=1
SLOT_TYPE_1=Cpu=${CONDOR_CPUS},mem=${CONDOR_MEMORY}

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
SCHED_NAME = $CONDOR_HOST
" > /etc/condor/condor_config.local

/usr/bin/telegraf --config /etc/telegraf/telegraf.conf &
tail -f -n 1000 /var/log/condor/StartLog /var/log/condor/StarterLog &

# Mysterious bug? Docker doesn't output its version as condor user if this is not executed before
docker -v

/usr/sbin/condor_master -pidfile /var/run/condor/condor.pid -f -t
