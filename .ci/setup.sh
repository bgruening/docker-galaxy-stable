#!/usr/bin/env bash

set -e

sudo apt-get update -qq
sudo apt-get install docker-ce --no-install-recommends -y -o Dpkg::Options::="--force-confmiss" -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew"
sudo apt-get install sshpass --no-install-recommends -y

pip install ephemeris

docker --version
docker info
