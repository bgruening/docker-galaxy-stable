#!/usr/bin/env bash

# Setup the galaxy user UID/GID and pass control on to supervisor
if id "$SLURM_USER_NAME" >/dev/null 2>&1; then
        echo "user exists"
else
        echo "user does not exist, creating"
        useradd -m -d /var/"$SLURM_USER_NAME" "$SLURM_USER_NAME"
fi
usermod -u $SLURM_UID  $SLURM_USER_NAME
groupmod -g $SLURM_GID $SLURM_USER_NAME
if [ ! -f "$MUNGE_KEY_PATH" ]
  then
    cp /etc/munge/munge.key "$MUNGE_KEY_PATH"
fi

if [ ! -f "$SLURM_CONF_PATH" ]
  then
    python /usr/local/bin/configure_slurm.py
    cp /etc/slurm-llnl/slurm.conf "$SLURM_CONF_PATH"
fi
if [ ! -f "$GALAXY_DIR"/.venv ]
  then
    mkdir -p "$GALAXY_DIR"/.venv
    chown $SLURM_USER_NAME:$SLURM_USER_NAME "$GALAXY_DIR"/.venv
    su - $SLURM_USER_NAME --preserve-environment -c \
                      'virtualenv "$GALAXY_DIR"/.venv &&\
                    . "$GALAXY_DIR"/.venv/bin/activate &&\
                    pip install galaxy-lib'
fi
chown $SLURM_USER_NAME /tmp/slurm
ln -s "$GALAXY_DIR" "$SYMLINK_TARGET"
ln -s "$SLURM_CONF_PATH" /etc/slurm-llnl/slurm.conf
exec /usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf
