#!/bin/sh

set -x

# This usually drastically reduced the container size
# at the cost of the startup time of your application
find / -name '*.pyc' -delete

find / -name '*.log' -delete
find / -name '.cache' -delete
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/*

# https://askubuntu.com/questions/266738/how-to-truncate-all-logfiles
truncate -s 0 /var/log/*log || true
truncate -s 0 /var/log/**/*log || true
