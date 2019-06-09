#!/usr/bin/env bash

sudo rm -rf ./local_folder | true
sudo rm -rf /export | true
docker stop galaxy | true
docker rm galaxy | true
