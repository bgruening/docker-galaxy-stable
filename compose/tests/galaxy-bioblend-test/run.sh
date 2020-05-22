#!/bin/sh

echo "Waiting for Galaxy..."
until [ "$(curl -s -o /dev/null -w '%{http_code}' ${GALAXY_URL:-nginx}/api/users/current\?key\=${GALAXY_DEFAULT_ADMIN_KEY:-fakekey})" -eq "200" ] && echo Galaxy started; do
    sleep 1;
done;

export BIOBLEND_GALAXY_URL=${GALAXY_URL:-http://nginx}
export BIOBLEND_GALAXY_API_KEY=${GALAXY_DEFAULT_ADMIN_KEY:-fakekey}
export BIOBLEND_TEST_JOB_TIMEOUT=${BIOBLEND_TEST_JOB_TIMEOUT:-240}

tox -e py38 -- -k "not test_dataset_peek and not test_create_quota and not test_get_quotas and not test_delete_undelete_quota and not test_update_quota and not test_download_dataset and not test_upload_from_galaxy_filesystem and not test_get_datasets and not test_datasets_from_fs and not test_existing_history and not test_new_history and not test_params and not test_tool_dependency_install and not test_download_history and not test_export_and_download"
