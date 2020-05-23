#!/bin/bash

# Inspired by: https://github.com/giovtorres/slurm-docker-cluster

sleep 10 # ToDo: Use locking or so to be sure we really have the newest version
echo "Waiting for Slurm config"
until [ -f /etc/slurm-llnl/slurm.conf ] && echo Config found; do
    sleep 0.5;
done;

if [ "$1" = "slurmctld" ]; then
    if [ ! -f /etc/munge/munge.key ]; then
      gosu "$MUNGE_USER" /usr/sbin/create-munge-key
    fi
    echo "Starting Munge.."
    /etc/init.d/munge start

    echo "Starting Slurmctld"
    exec /usr/sbin/slurmctld -D
fi

if [ "$1" = "slurmd" ]; then
    echo "Waiting for munge.key"
    until [ -f /etc/munge/munge.key ] && echo munge.key found; do
        sleep 0.5;
    done;
    sleep 1

    echo "Starting Munge.."
    /etc/init.d/munge start

    echo "Starting Slurmd"
    exec /usr/sbin/slurmd -D
fi

exec "$@"
