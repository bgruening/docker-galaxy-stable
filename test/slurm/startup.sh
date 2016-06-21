#!/usr/bin/env bash

# Setup the galaxy user UID/GID and pass control on to supervisor
usermod -u $SLURM_UID  $SLURM_USER_NAME
groupmod -g $SLURM_GID $SLURM_USER_NAME
if [ -f /export/munge.key ]
  then cp /export/munge.key /etc/munge/munge.key
else
  cp /etc/munge/munge.key /export/munge.key
fi

if [ -f /export/slurm.conf ]
  then cp /export/slurm.conf /etc/slurm-llnl/slurm.conf
else
  python /usr/local/bin/configure_slurm.py
  cp /etc/slurm-llnl/slurm.conf /export/slurm.conf
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
exec /usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf

