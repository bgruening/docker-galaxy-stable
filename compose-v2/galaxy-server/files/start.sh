#!/bin/bash

# First start?? Check if something exists that indicates that environment is not new.. Config file? Something in DB maybe??

echo "Initialization: Check if files already exist, export otherwise."
if [ ! -d  "$EXPORT_DIR/$GALAXY_ROOT" ]; then
    # Create initial $GALAXY_ROOT in $EXPORT_DIR
    mkdir "$EXPORT_DIR/$GALAXY_ROOT"
fi

# shellcheck disable=SC2143,SC2086,SC2010
if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_DIR" ] || [ -z "$(ls -p $EXPORT_DIR/$GALAXY_CONFIG_DIR | grep -v /)" ]; then
    # Move config to $EXPORT_DIR and create symlink 
    mkdir "$EXPORT_DIR/$GALAXY_CONFIG_DIR"
    chown "$GALAXY_USER:$GALAXY_USER" "$EXPORT_DIR/$GALAXY_CONFIG_DIR"
    cp -rpf $GALAXY_CONFIG_DIR/* $EXPORT_DIR/$GALAXY_CONFIG_DIR
    cp -rpf $GALAXY_CONFIG_DIR/plugins/* $EXPORT_DIR/$GALAXY_CONFIG_DIR/plugins
fi
rm -rf "$GALAXY_CONFIG_DIR"
ln -v -s "$EXPORT_DIR/$GALAXY_CONFIG_DIR" "$GALAXY_CONFIG_DIR"
chown -h "$GALAXY_USER:$GALAXY_USER" "$GALAXY_CONFIG_DIR"

# shellcheck disable=SC2143,SC2086,SC2010
if [ ! -d  "$EXPORT_DIR/$GALAXY_STATIC_DIR" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_STATIC_DIR)" ]; then
    # Move static to $EXPORT_DIR and create symlink
    mkdir "$EXPORT_DIR/$GALAXY_STATIC_DIR"
    chown "$GALAXY_USER:$GALAXY_USER" "$EXPORT_DIR/$GALAXY_STATIC_DIR"
    cp -rpf $GALAXY_STATIC_DIR/* $EXPORT_DIR/$GALAXY_STATIC_DIR
fi
rm -rf "$GALAXY_STATIC_DIR"
ln -v -s "$EXPORT_DIR/$GALAXY_STATIC_DIR" "$GALAXY_STATIC_DIR"
chown -h "$GALAXY_USER:$GALAXY_USER" "$GALAXY_STATIC_DIR"

# shellcheck disable=SC2143,SC2086,SC2010
if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH)" ]; then
    # Move environment to export and create symlink
    mkdir "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH"
    chown "$GALAXY_USER:$GALAXY_USER" "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH"
    cp -rpf $GALAXY_CONFIG_TOOL_PATH/* $EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH
fi
rm -rf "$GALAXY_CONFIG_TOOL_PATH"
ln -v -s "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH" "$GALAXY_CONFIG_TOOL_PATH"
chown -h "$GALAXY_USER:$GALAXY_USER" "$GALAXY_CONFIG_TOOL_PATH"

# shellcheck disable=SC2143,SC2086,SC2010
if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR)" ]; then
    # Move tools and tool-deps to export and create symlink
    mkdir "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR"
    chown "$GALAXY_USER:$GALAXY_USER" "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR"
    cp -rpf $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR/* $EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR
fi
rm -rf "$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR"
ln -v -s "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR" "$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR"
chown -h "$GALAXY_USER:$GALAXY_USER" "$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR"

# Move Galaxy virtual environment
# shellcheck disable=SC2143,SC2086,SC2010
if [ ! -d  "$EXPORT_DIR/$GALAXY_VIRTUAL_ENV" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_VIRTUAL_ENV)" ]; then
    mkdir "$EXPORT_DIR/$GALAXY_VIRTUAL_ENV"
    chown "$GALAXY_USER:$GALAXY_USER" "$EXPORT_DIR/$GALAXY_VIRTUAL_ENV"
    cp -rpf $GALAXY_VIRTUAL_ENV/* $EXPORT_DIR/$GALAXY_VIRTUAL_ENV
fi
rm -rf "$GALAXY_VIRTUAL_ENV"
ln -v -s "$EXPORT_DIR/$GALAXY_VIRTUAL_ENV" "$GALAXY_VIRTUAL_ENV"
chown -h "$GALAXY_USER:$GALAXY_USER" "$GALAXY_VIRTUAL_ENV"

# Export database-folder (used for job files etc)
rm -rf "$GALAXY_DATABASE_PATH"
mkdir "$EXPORT_DIR/$GALAXY_DATABASE_PATH"
chown "$GALAXY_USER:$GALAXY_USER" "$EXPORT_DIR/$GALAXY_DATABASE_PATH"
ln -v -s "$EXPORT_DIR/$GALAXY_DATABASE_PATH" "$GALAXY_DATABASE_PATH"
chown -h "$GALAXY_USER:$GALAXY_USER" "$GALAXY_DATABASE_PATH"

echo "Finished initialization"

echo "Waiting for RabbitMQ..."
until nc -z -w 2 rabbitmq 5672 && echo RabbitMQ started; do
    sleep 1;
done;

echo "Waiting for Postgres..."
. $GALAXY_VIRTUAL_ENV/bin/activate
until /usr/local/bin/check_database.py 2>&1 >/dev/null; do 
    sleep 1; 
done;
deactivate
echo "Postgres started"

if [ -f "/etc/condor/condor_config.local" ]; then
    echo "HTCondor config file found"
    echo "Copying Galaxy library to /export (needed by HTCondor workers).."
    mkdir "$EXPORT_DIR/$GALAXY_ROOT/lib"
    chown "$GALAXY_USER:$GALAXY_USER" "$EXPORT_DIR/$GALAXY_ROOT/lib"
    cp -rpf $GALAXY_ROOT/lib/* $EXPORT_DIR/$GALAXY_ROOT/lib
    echo "Starting HTCondor.."
    service condor start
    # export CONDOR_CONFIG="/etc/condor/condor_config.local"
    # export PATH="/opt/htcondor/bin:/opt/htcondor/sbin:$PATH"
    # #ln -s /
    # "$HTCONDOR_ROOT/sbin/condor_master"
fi

# In case the user wants the default admin to be created, do so.
if [[ -n $GALAXY_DEFAULT_ADMIN_USER ]]; then
    echo "Creating admin user $GALAXY_DEFAULT_ADMIN_USER with key $GALAXY_DEFAULT_ADMIN_KEY and password $GALAXY_DEFAULT_ADMIN_PASSWORD if not existing"
    . $GALAXY_VIRTUAL_ENV/bin/activate
    python /usr/local/bin/create_galaxy_user.py --user "$GALAXY_DEFAULT_ADMIN_EMAIL" --password "$GALAXY_DEFAULT_ADMIN_PASSWORD" \
    -c "$GALAXY_CONFIG_FILE" --username "$GALAXY_DEFAULT_ADMIN_USER" --key "$GALAXY_DEFAULT_ADMIN_KEY"
    deactivate
fi

echo "Starting Galaxy now.."
cd "$GALAXY_ROOT" || { echo "Error: Could not change to $GALAXY_ROOT"; exit 1; }
"$GALAXY_VIRTUAL_ENV/bin/uwsgi" --yaml "$GALAXY_CONFIG_DIR/galaxy.yml" --pythonpath "$GALAXY_ROOT/lib" --module "galaxy.webapps.galaxy.buildapp:uwsgi_app()" --virtualenv /galaxy/.venv --uid "$GALAXY_UID" --gid "$GALAXY_GID"