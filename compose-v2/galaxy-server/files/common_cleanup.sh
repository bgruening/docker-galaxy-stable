#!/bin/sh

set -x

# This usually drastically reduced the container size
# at the cost of the startup time of your application
find / -name '*.pyc' -delete

find / -name '*.log' -delete
find / -name '.cache' -delete
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/*
