#!/bin/bash

# First start?? Check if something exists that indicates that environment is not new.. Config file? Something in DB maybe??

echo "Initialization: Check if files already exist, export otherwise."

# Create initial $GALAXY_ROOT in $EXPORT_DIR if not already existent
mkdir -p "$EXPORT_DIR/$GALAXY_ROOT"

declare -A exports=( ["$GALAXY_STATIC_DIR"]="$EXPORT_DIR/$GALAXY_STATIC_DIR" \
                     ["$GALAXY_CONFIG_TOOL_PATH"]="$EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH" \
                     ["$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR"]="$EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR" \
                     ["$GALAXY_VIRTUAL_ENV"]="$EXPORT_DIR/$GALAXY_VIRTUAL_ENV" )

# shellcheck disable=SC2143,SC2086,SC2010
for galaxy_dir in "${!exports[@]}"; do
    exp_dir=${exports[$galaxy_dir]}
    if [ ! -d  $exp_dir ] || [ -z "$(ls -A $exp_dir)" ]; then
        echo "Exporting $galaxy_dir to $exp_dir"
        mkdir $exp_dir
        chown "$GALAXY_USER:$GALAXY_USER" $exp_dir
        cp -rpf $galaxy_dir/* $exp_dir
    fi
    rm -rf $galaxy_dir
    ln -v -s $exp_dir $galaxy_dir
    chown -h "$GALAXY_USER:$GALAXY_USER" $galaxy_dir
done

# Export galaxy_config seperately (special treatment because of plugins-dir)
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

# Export database-folder (used for job files etc)
rm -rf "$GALAXY_DATABASE_PATH"
mkdir -p "$EXPORT_DIR/$GALAXY_DATABASE_PATH"
chown "$GALAXY_USER:$GALAXY_USER" "$EXPORT_DIR/$GALAXY_DATABASE_PATH"
ln -v -s "$EXPORT_DIR/$GALAXY_DATABASE_PATH" "$GALAXY_DATABASE_PATH"
chown -h "$GALAXY_USER:$GALAXY_USER" "$GALAXY_DATABASE_PATH"

# Try to guess if we are running under --privileged mode
if mount | grep "/proc/kcore"; then
    PRIVILEGED=false
else
    PRIVILEGED=true
    echo "Privileged mode detected"
    chmod 666 /var/run/docker.sock
fi

if $PRIVILEGED; then
  echo "Mounting CVMFS"
  chmod 666 /dev/fuse
  mkdir /cvmfs/data.galaxyproject.org
  mount -t cvmfs data.galaxyproject.org /cvmfs/data.galaxyproject.org
  mkdir /cvmfs/singularity.galaxyproject.org
  mount -t cvmfs singularity.galaxyproject.org /cvmfs/singularity.galaxyproject.org
fi

echo "Finished initialization"

echo "Waiting for RabbitMQ..."
until nc -z -w 2 rabbitmq 5672 && echo RabbitMQ started; do
    sleep 1;
done;

echo "Waiting for Postgres..."
until nc -z -w 2 postgres 5432 && echo Postgres started; do
     sleep 1;
done;

echo "Create/Upgrade Database if necessary"
$GALAXY_ROOT/create_db.sh

if [ -f "/etc/condor/condor_config.local" ]; then
    echo "HTCondor config file found"
    echo "Starting HTCondor.."
    service condor start
    # export CONDOR_CONFIG="/etc/condor/condor_config.local"
    # export PATH="/opt/htcondor/bin:/opt/htcondor/sbin:$PATH"
    # #ln -s /
    # "$HTCONDOR_ROOT/sbin/condor_master"
fi

if [ -f /etc/munge/munge.key ]; then
    echo "Munge key found"
    echo "Starting Munge.."
    /etc/init.d/munge start
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
"$GALAXY_VIRTUAL_ENV/bin/uwsgi" --yaml "$GALAXY_CONFIG_DIR/galaxy.yml" --uid "$GALAXY_UID" --gid "$GALAXY_GID"
