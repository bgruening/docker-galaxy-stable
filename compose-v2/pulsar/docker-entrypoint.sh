#!/bin/bash

if [ -z "$PULSAR_SKIP_CONFIG_LOCK" ]; then
  sleep 10
  echo "Waiting for Galaxy configurator to finish and release lock"
  until [ ! -f "$PULSAR_CONFIG_DIR/configurator.lock" ] && echo Lock released; do
      sleep 0.1;
  done;
fi

cd "$PULSAR_ROOT" ||exit 1

. "$PULSAR_VIRTUALENV/bin/activate"

pulsar --mode "${PULSAR_MODE:-paster}"
