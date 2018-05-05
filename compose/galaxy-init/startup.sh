#!/bin/bash
# This script initializes the export directory if it isn't initialized already

echo "Initializing export"
# Always copy current config to .distribution_config
echo "Copying to /export/.distribution_config"
rm -rf /export/.distribution_config
cp -rp /galaxy-export/config/ /export/.distribution_config
chown $GALAXY_UID:$GALAXY_GID /export

for export_me in /galaxy-export/*
do
  export_name=$(basename $export_me)
  if [ ! -d /export/$export_name ]
  then
    echo "Copying to /export/$export_name"
    cp -rp $export_me /export/$export_name
    chown -R $GALAXY_UID:$GALAXY_GID /export/$export_name
  fi
done

# Optional, might not work
{
  if [ ! -d "/export/var/lib/docker" ]
  then
    echo "Moving to /export/var/lib/docker"
    mkdir -p /export/var/lib/
    mv /var/lib/docker /export/var/lib/docker
    chown -R $GALAXY_UID:$GALAXY_GID /export/var/lib/docker
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
