#!/bin/bash

# Nginx configuration
if [ "$NGINX_OVERWRITE_CONFIG" != "true" ]; then
  echo "NGINX_OVERWRITE_CONFIG is not true. Skipping configuration of Nginx"
else
  nginx_configs=( "nginx.conf" )

  for conf in "${nginx_configs[@]}"; do
    echo "Configuring $conf"
    j2 --customize /customize.py --undefined -o "/tmp/$conf" "/templates/nginx/$conf.j2" /base_config.yml
    echo "The following changes will be applied to $conf:"
    diff "${NGINX_CONFIG_DIR:-/etc/nginx/}/$conf" "/tmp/$conf"
    mv -f "/tmp/$conf" "${NGINX_CONFIG_DIR:-/etc/nginx}/$conf"
  done
fi
# Galaxy configuration
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

galaxy_configs=( "job_conf.xml" "galaxy.yml" "job_metrics.xml" )

for conf in "${galaxy_configs[@]}"; do
  echo "Configuring $conf"
  j2 --customize /customize.py --undefined -o "/tmp/$conf" "/templates/galaxy/$conf.j2" /base_config.yml
  echo "The following changes will be applied to $conf:"
  diff "${GALAXY_CONFIG_DIR:-/galaxy/config}/$conf" "/tmp/$conf"
  mv -f "/tmp/$conf" "${GALAXY_CONFIG_DIR:-/galaxy/config}/$conf"
done

echo "Finished configuring Galaxy"

if [ "$DONT_EXIT" = "true" ]; then
    echo "Integration test detected. Galaxy Configurator will go to sleep (to not interrupt docker-compose)."
    sleep infinity
fi
