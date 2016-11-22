#!/bin/bash
useradd -u 1450 -m galaxy
/usr/local/bin/setup_gridengine.sh
tail -f /var/spool/gridengine/qmaster/messages
