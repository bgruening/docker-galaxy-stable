#!/bin/bash
. $GALAXY_VIRTUAL_ENV/bin/activate
sh create_db.sh -c $GALAXY_CONFIG_FILE
echo "Creating user \"$GALAXY_DEFAULT_ADMIN_USER\" with password \"$GALAXY_DEFAULT_ADMIN_PASSWORD\" and key \"$GALAXY_DEFAULT_ADMIN_KEY\" if \"$GALAXY_DEFAULT_ADMIN_USER\" doesn't already exist. To modify these settings, change \044GALAXY_DEFAULT_ADMIN_USER, \044GALAXY_DEFAULT_ADMIN_PASSWORD and \044GALAXY_DEFAULT_ADMIN_KEY."
python /usr/local/bin/create_galaxy_user.py --user $GALAXY_DEFAULT_ADMIN_USER --password $GALAXY_DEFAULT_ADMIN_PASSWORD -c $GALAXY_CONFIG_FILE --key $GALAXY_DEFAULT_ADMIN_KEY

