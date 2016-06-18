#!/usr/bin/env bash

# Test that jobs run successfully on an external slurm cluster

# We use /tmp as an export dir that will hold the shared data between
# galaxy and slurm:
EXPORT=/tmp
JOB_CONF_XML=`pwd`"/../job_conf.xml"
# We build the slurm image
# docker build -t slurm ../
# We fire up a slurm node (with hostname slurm)
docker run -d -v "$EXPORT":/export --name slurm --hostname slurm slurm
# We start galaxy (without the internal slurm, but with a modified job_conf.xml)
# and link it to the slurm container (so that galaxy resolves the slurm container's hostname)
docker run -d -e "NONUSE=slurmd,slurmctld" \
   -v "$JOB_CONF_XML":/etc/galaxy/job_conf.xml \
   --link slurm --name galaxy-slurm-test -h galaxy \
   -p 80:80 -v "$EXPORT":/export quay.io/bgruening/galaxy
# Let's submit a job from the galaxy container and check it runs in the slurm container
sleep 40s
/bin/cat <<EOM >"$EXPORT"/test.sh
#!/bin/bash
printenv
EOM
chmod +x "$EXPORT"/test.sh
docker exec galaxy-slurm-test su - galaxy -c 'srun /export/test.sh' | grep "SLURMD_NODENAME=slurm" && \
docker stop galaxy-slurm-test slurm && \
docker rm galaxy-slurm-test slurm
# TODO: Run a galaxy tool and check it runs on the cluster
