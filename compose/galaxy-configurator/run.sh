#!/bin/bash

# Set default config dirs
export GALAXY_CONF_DIR=${GALAXY_CONF_DIR:-/galaxy/config} \
       NGINX_CONF_DIR=${NGINX_CONF_DIR:-/etc/nginx/} \
       SLURM_CONF_DIR=${SLURM_CONF_DIR:-/etc/slurm-llnl} \
       HTCONDOR_CONF_DIR=${HTCONDOR_CONF_DIR:-/htcondor} \
       PULSAR_CONF_DIR=${PULSAR_CONF_DIR:-/pulsar/config} \
       KIND_CONF_DIR=${KIND_CONF_DIR:-/kind}
# Nginx configuration
if [ "$NGINX_OVERWRITE_CONFIG" != "true" ]; then
  echo "NGINX_OVERWRITE_CONFIG is not true. Skipping configuration of Nginx"
else
  nginx_configs=( "nginx.conf" )

  for conf in "${nginx_configs[@]}"; do
    echo "Configuring $conf"
    j2 --customize /customize.py --undefined -o "/tmp/$conf" "/templates/nginx/$conf.j2" /base_config.yml
    echo "The following changes will be applied to $conf:"
    diff "${NGINX_CONF_DIR}/$conf" "/tmp/$conf"
    mv -f "/tmp/$conf" "${NGINX_CONF_DIR}/$conf"
  done
fi

# Slurm configuration
if [ "$SLURM_OVERWRITE_CONFIG" != "true" ]; then
  echo "SLURM_OVERWRITE_CONFIG is not true. Skipping configuration of Slurm"
else
  echo "Locking Slurm config"
  touch "${SLURM_CONF_DIR:-/etc/slurm-llnl}/configurator.lock"
  slurm_configs=( "slurm.conf" )

  for conf in "${slurm_configs[@]}"; do
    echo "Configuring $conf"
    j2 --customize /customize.py --undefined -o "/tmp/$conf" "/templates/slurm/$conf.j2" /base_config.yml
    echo "The following changes will be applied to $conf:"
    diff "${SLURM_CONF_DIR}/$conf" "/tmp/$conf"
    mv -f "/tmp/$conf" "${SLURM_CONF_DIR}/$conf"
  done

  rm "${SLURM_CONF_DIR}/configurator.lock"
  echo "Lock for Slurm config released"
fi

# HTCondor configuration
if [ "$HTCONDOR_OVERWRITE_CONFIG" != "true" ]; then
  echo "HTCONDOR_OVERWRITE_CONFIG is not true. Skipping configuration of HTCondor"
else
  echo "Locking HTCondor config"
  touch "${HTCONDOR_CONF_DIR:-/htcondor}/configurator.lock"
  htcondor_configs=( "galaxy.conf" "master.conf" "executor.conf" )

  for conf in "${htcondor_configs[@]}"; do
    echo "Configuring $conf"
    j2 --customize /customize.py --undefined -o "/tmp/$conf" "/templates/htcondor/$conf.j2" /base_config.yml
    echo "The following changes will be applied to $conf:"
    diff "${HTCONDOR_CONF_DIR}/$conf" "/tmp/$conf"
    mv -f "/tmp/$conf" "${HTCONDOR_CONF_DIR}/$conf"
  done

  rm "${HTCONDOR_CONF_DIR}/configurator.lock"
  echo "Lock for HTCondor config released"
fi

# Pulsar configuration
if [ "$PULSAR_OVERWRITE_CONFIG" != "true" ]; then
  echo "PULSAR_OVERWRITE_CONFIG is not true. Skipping configuration of Pulsar"
else
  echo "Locking Pulsar config"
  touch "${PULSAR_CONF_DIR:-/pulsar/config}/configurator.lock"
  pulsar_configs=( "server.ini" "app.yml" "dependency_resolvers_conf.xml" )

  for conf in "${pulsar_configs[@]}"; do
    echo "Configuring $conf"
    j2 --customize /customize.py --undefined -o "/tmp/$conf" "/templates/pulsar/$conf.j2" /base_config.yml
    echo "The following changes will be applied to $conf:"
    diff "${PULSAR_CONF_DIR}/$conf" "/tmp/$conf"
    mv -f "/tmp/$conf" "${PULSAR_CONF_DIR}/$conf"
  done

  rm "${PULSAR_CONF_DIR}/configurator.lock"
  echo "Lock for Pulsar config released"
fi

# Galaxy configuration
if [ "$GALAXY_OVERWRITE_CONFIG" != "true" ]; then
  echo "GALAXY_OVERWRITE_CONFIG is not true. Skipping configuration of Galaxy"
  exit 0
fi

cd "${GALAXY_CONF_DIR}" || { echo "Error: Could not find Galaxy config dir"; exit 1; }

echo "Waiting for Galaxy config dir to be initially populated (in case of first startup)"
until [ "$(ls -p | grep -v /)" != "" ] && echo Galaxy config populated; do
  sleep 0.5;
done;

if [ ! -f /base_config.yml ]; then
  echo "Warning: 'base_config.yml' does not exist. Configuration will solely happen through env!"
  touch /base_config.yml
fi

galaxy_configs=( "job_conf.xml" "galaxy.yml" "job_metrics.xml" "container_resolvers_conf.xml" "GALAXY_PROXY_PREFIX.txt" )

for conf in "${galaxy_configs[@]}"; do
  echo "Configuring $conf"
  j2 --customize /customize.py --undefined -o "/tmp/$conf" "/templates/galaxy/$conf.j2" /base_config.yml
  echo "The following changes will be applied to $conf:"
  diff "${GALAXY_CONF_DIR}/$conf" "/tmp/$conf"
  mv -f "/tmp/$conf" "${GALAXY_CONF_DIR}/$conf"
done

echo "Finished configuring Galaxy"

if [ "$DONT_EXIT" = "true" ]; then
  echo "Integration test detected. Galaxy Configurator will go to sleep (to not interrupt docker-compose)."
  sleep infinity
fi
