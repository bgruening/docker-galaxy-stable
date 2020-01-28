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

if [ ! -f /base_config.yml ]; then
    echo "Warning: 'base_config.yml' does not exist. Configuration will solely happen through env!"
    touch /base_config.yml
fi

echo "Configuring job_conf.xml"
j2 --customize /customize.py --undefined -o /galaxy/config/job_conf.xml /templates/job_conf.xml.j2

echo "Configuring galaxy.yml"
j2 --customize /customize.py --undefined -o /galaxy/config/galaxy.yml /templates/galaxy.yml.j2 /base_config.yml

echo "Configuring job_metrics.xml"
j2 --customize /customize.py --undefined -o /galaxy/config/job_metrics.xml /templates/job_metrics.xml.j2 /base_config.yml

echo "Finished configuring Galaxy"

if [ "$DONT_EXIT" = "true" ]; then
    echo "Integration test detected. Galaxy Configurator will go to sleep (to not interrupt docker-compose)."
    sleep infinity
fi
