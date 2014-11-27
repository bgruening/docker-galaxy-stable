#!/bin/sh

# start Galaxy
/etc/init.d/postgresql start
./run.sh --daemon
sleep 60

python ./scripts/api/install_tool_shed_repositories.py --api admin -l http://localhost:8080 --tool-deps --repository-deps $1
exit_code=$?

if [ $exit_code != 0 ] ; then
    exit $exit_code
fi

# stop everything
./run.sh --stop-daemon
service postgresql stop
