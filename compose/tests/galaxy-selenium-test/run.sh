#!/bin/bash
set -e # Stop script, if a test fails

supervisord &

sleep 5

echo "Waiting for Galaxy..."
until [ "$(curl -s -o /dev/null -w '%{http_code}' ${GALAXY_URL:-nginx}/api/users/current\?key\=${GALAXY_DEFAULT_ADMIN_KEY:-fakekey})" -eq "200" ] && echo Galaxy started; do
    sleep 1;
done;

export GALAXY_TEST_SELENIUM_REMOTE=1
export GALAXY_TEST_SELENIUM_REMOTE_HOST=localhost
export GALAXY_TEST_SELENIUM_REMOTE_PORT=4444
export GALAXY_TEST_EXTERNAL_FROM_SELENIUM=${GALAXY_URL:-http://nginx}
export GALAXY_TEST_EXTERNAL=${GALAXY_URL:-http://nginx}
export GALAXY_CONFIG_MASTER_API_KEY=${GALAXY_DEFAULT_ADMIN_KEY:-fakekey}


for test in $(echo "$TESTS" | sed "s/,/ /g"); do
  echo "Running test $test"
  ./galaxy/run_tests.sh --skip-common-startup -selenium "/galaxy/lib/galaxy_test/selenium/test_$test"
done
