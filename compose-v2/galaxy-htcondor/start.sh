#!/bin/bash

sleep 5
echo "Waiting for Galaxy configurator to finish and release lock"
until [ ! -f /config/configurator.lock ] && echo Lock released; do
    sleep 0.1;
done;

cp -f "/config/$HTCONDOR_TYPE.conf" /etc/condor/condor_config.local

/usr/bin/supervisord
