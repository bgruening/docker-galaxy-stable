#!/bin/bash
set -e

if [ "x$ENABLE_CONDOR" != "x" ]
then
    echo "Enabling Condor"
    if [ -e /export/condor_config ]
    then
        rm -f /etc/condor/condor_config
        ln -s /export/condor_config /etc/condor/condor_config
    fi
    /etc/init.d/condor start
fi
bash /usr/bin/startup
