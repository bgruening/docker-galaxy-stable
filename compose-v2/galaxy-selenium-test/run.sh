#!/bin/bash
set -e # Stop script, if a test fails

supervisord &

sleep 5

echo "Waiting for Galaxy..."
until [ "$(curl -s -o /dev/null -w '%{http_code}' ${GALAXY_URL:-nginx})" -eq "200" ] && echo Galaxy started; do
    sleep 1;
done;

export GALAXY_TEST_SELENIUM_REMOTE=1
export GALAXY_TEST_SELENIUM_REMOTE_HOST=localhost
export GALAXY_TEST_SELENIUM_REMOTE_PORT=4444
export GALAXY_TEST_EXTERNAL_FROM_SELENIUM=http://${GALAXY_URL:-nginx}
export GALAXY_TEST_EXTERNAL=http://${GALAXY_URL:-nginx}
export GALAXY_CONFIG_MASTER_API_KEY=${GALAXY_DEFAULT_ADMIN_KEY:-admin}


for test in $(echo "$TESTS" | sed "s/,/ /g"); do
  echo "Running test $test"
  ./galaxy/run_tests.sh --skip-common-startup -selenium "/galaxy/lib/galaxy_test/selenium/test_$test"
done
