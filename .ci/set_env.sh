#!/usr/bin/env bash

export WORKING_DIR="${WORKING_DIR:=`pwd`}"

export GALAXY_HOME=/home/galaxy
export GALAXY_USER=admin@galaxy.org
export GALAXY_USER_EMAIL=admin@galaxy.org
export GALAXY_USER_PASSWD=admin
export BIOBLEND_GALAXY_API_KEY=admin
export BIOBLEND_GALAXY_URL=http://localhost:8080
export COMPOSE_DIR="${WORKING_DIR}/compose"
export SAMPLE_TOOLS=$GALAXY_HOME/ephemeris/sample_tool_list.yaml
