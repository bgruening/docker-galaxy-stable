#!/bin/bash
# This script initializes the export directory if it isn't initialized already


function error_trap() {
  echo "#### Error at line ${BASH_LINENO[0]} running command ${BASH_COMMAND} ####" >&2
}

trap error_trap ERR
set -o errexit

echo "Initializing export"
# Always copy current config to .distribution_config
echo "Copying to /export/.distribution_config"
rm -rf /export/.distribution_config
cp -rp /galaxy-export/config/ /export/.distribution_config
chown $GALAXY_UID:$GALAXY_GID /export

for export_me in /galaxy-export/*
do
  export_name=$(basename $export_me)
  dest_path="/export/$export_name"
  if [ ! "x$GALAXY_INIT_FORCE_COPY" = "x" ]; then
     # delete so that if can be copied again if in the force-copy env var
     # Example content for $GALAXY_INIT_FORCE_COPY
     # GALAXY_INIT_FORCE_COPY = __venv__,__tools__
     if [[ $GALAXY_INIT_FORCE_COPY = *__"$export_name"__* ]]; then
       echo "Removing ${dest_path} as part of forced copy process."
       rm -rf "${dest_path}"
     fi
  fi
  if [ ! -d "${dest_path}" ]
  then
    echo "Copying to ${dest_path}"
    cp -rp "$export_me" "${dest_path}"
    chown -R $GALAXY_UID:$GALAXY_GID "${dest_path}"
  else
    echo "Skipping $export_me (directory already and overwrite isn't forced)"
  fi
done

# Optional, might not work
{
  if [ -d "/var/lib/docker" ]
  then
      if [ ! -d "/export/var/lib/docker" ]
      then
        echo "Moving to /export/var/lib/docker"
        mkdir -p /export/var/lib/
        mv /var/lib/docker /export/var/lib/docker
        chown -R $GALAXY_UID:$GALAXY_GID /export/var/lib/docker
      fi
    fi
} || echo "Moving docker lib failed, this is not a fatal error"

echo "Initialization complete"

if [ "x$DISABLE_SLEEPLOCK" = "x" ]
then
    SLEEPLOCK_FILE=/export/.initdone
    echo "done">$SLEEPLOCK_FILE
    echo "Init notified, sleeping now"
    sleep infinity
fi

exit 0
