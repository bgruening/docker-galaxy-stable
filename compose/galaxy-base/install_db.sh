#!/bin/bash
# Create the galaxy database and migrate
. $GALAXY_VIRTUAL_ENV/bin/activate
sh $GALAXY_ROOT/create_db.sh -c $GALAXY_CONFIG_FILE
