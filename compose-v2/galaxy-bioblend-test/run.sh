#!/bin/sh

echo "Waiting for Galaxy..."
until [ "$(curl -s -o /dev/null -w '%{http_code}' nginx)" -eq "200" ] && echo Galaxy started; do
    sleep 1;
done;

tox -e py38 -- -k "not test_download_dataset and not test_upload_from_galaxy_filesystem and not test_get_datasets and not test_datasets_from_fs and not test_existing_history and not test_new_history and not test_params and not test_tool_dependency_install and not test_download_history and not test_export_and_download"