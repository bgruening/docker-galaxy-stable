#!/usr/bin/env bash

# Test that jobs run successfully on an external gridengine cluster
./travis_script.sh


# remove container
docker stop sgemaster
docker rm sgemaster
docker stop galaxytest
docker rm galaxytest

