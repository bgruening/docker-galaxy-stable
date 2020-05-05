#!/bin/sh

set -x

find / -name '*.pyc' -delete
find / -name '*.log' -delete
find / -name '.cache' -delete
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/*
