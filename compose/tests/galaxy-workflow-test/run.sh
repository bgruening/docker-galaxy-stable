#!/bin/bash
set -e # Stop script, if a test fails

echo "Waiting for Galaxy..."
until [ "$(curl -s -o /dev/null -w '%{http_code}' "${GALAXY_URL:-nginx}/api/users/current\?key\=${GALAXY_DEFAULT_ADMIN_KEY:-fakekey}")" -eq "200" ] && echo Galaxy started; do
  sleep 1;
done;

for workflow in ${WORKFLOWS//,/ }
do
  echo "Running test $workflow"
  planemo "${PLANEMO_OPTIONS}" test \
    --galaxy_url "${GALAXY_URL:-nginx}" \
    --galaxy_admin_key "${GALAXY_USER_KEY:-fakekey}" \
    --shed_install \
    --engine external_galaxy \
    --test_output "${GALAXY_ROOT:-/galaxy}/database/tool_test_output.html" \
    --test_output_json "${GALAXY_ROOT:-/galaxy}/database/tool_test_output.json" \
    "${workflow}";
done
