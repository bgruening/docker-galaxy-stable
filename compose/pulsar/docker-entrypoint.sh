#!/bin/bash

if [ -z "$PULSAR_SKIP_CONFIG_LOCK" ]; then
  sleep 10
  echo "Waiting for Galaxy configurator to finish and release lock"
  until [ ! -f "$PULSAR_CONFIG_DIR/configurator.lock" ] && echo Lock released; do
    sleep 0.1;
  done;
fi

# Try to guess if we are running under --privileged mode
if mount | grep "/proc/kcore"; then
  PRIVILEGED=false
else
  PRIVILEGED=true
  echo "Privileged mode detected"
  chmod 666 /var/run/docker.sock
fi

if $PRIVILEGED; then
  echo "Mounting CVMFS"
  chmod 666 /dev/fuse
  mkdir /cvmfs/data.galaxyproject.org
  mount -t cvmfs data.galaxyproject.org /cvmfs/data.galaxyproject.org
  mkdir /cvmfs/singularity.galaxyproject.org
  mount -t cvmfs singularity.galaxyproject.org /cvmfs/singularity.galaxyproject.org
fi

cd "$PULSAR_ROOT" ||exit 1

# shellcheck source=/dev/null
. "$PULSAR_VIRTUALENV/bin/activate"

pulsar --mode "${PULSAR_MODE:-paster}"
