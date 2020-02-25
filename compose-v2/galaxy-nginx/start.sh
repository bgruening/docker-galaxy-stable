#!/bin/bash
sleep 5 # ToDo: Use locking or so to be sure we really have the newest version
echo "Waiting for Nginx config"
until [ "$(ls -p | grep -v /config)" != "" ] && echo Nginx config found; do
    sleep 0.5;
done;

cp -f /config/* /etc/nginx

echo "Running nginx startup command"
nginx -g "daemon off;"
