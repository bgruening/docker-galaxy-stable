#!/bin/bash

if [ "$GALAXY_OVERWRITE_CONFIG" != "true" ]; then
    echo "GALAXY_OVERWRITE_CONFIG is not true. Skipping configuration of Galaxy"
    exit 0
fi

cd ${GALAXY_CONFIG_DIR:-/galaxy/config} || { echo "Error: Could not find Galaxy config dir"; exit 1; }

echo "Waiting for Galaxy config dir to be initially populated (in case of first startup)"
until [ "$(ls -p | grep -v /)" != "" ] && echo Galaxy config populated; do
    sleep 0.5;
done;

echo "Configuring job_conf.xml"
j2 --undefined -o /galaxy/config/job_conf.xml /templates/job_conf.xml.j2

echo "Finished configuring Galaxy"

if [ "$DONT_EXIT" = "true" ]; then
    echo "Integration test detected. Galaxy Configurator will go to sleep (to not interrupt docker-compose)."
    sleep infinity
fi