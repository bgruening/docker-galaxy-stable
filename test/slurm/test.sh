#!/usr/bin/env bash

# Test that jobs run successfully on an external slurm cluster

# We use /tmp as an export dir that will hold the shared data between
# galaxy and slurm:
EXPORT=/tmp
# We build the slurm image
docker build -t slurm .
# We fire up a slurm node (with hostname slurm)
docker run -d -v "$EXPORT":/export --name slurm \
           --hostname slurm \
           slurm
# We start galaxy (without the internal slurm, but with a modified job_conf.xml)
# and link it to the slurm container (so that galaxy resolves the slurm container's hostname)
docker run -d -e "NONUSE=slurmd,slurmctld" \
   --link slurm --name galaxy-slurm-test -h galaxy \
   -p 80:80 -v "$EXPORT":/export quay.io/bgruening/galaxy
# We wait for the creation of the /galaxy-central/config/ if it does not exist yet
sleep 20s
# We copy the job_conf.xml to the $EXPORT folder
cp job_conf.xml "$EXPORT"/galaxy-central/config/
# We restart galaxy
docker stop galaxy-slurm-test
docker rm galaxy-slurm-test
docker run -d -e "NONUSE=slurmd,slurmctld" \
   --link slurm --name galaxy-slurm-test -h galaxy \
   -p 80:80 -v "$EXPORT":/export quay.io/bgruening/galaxy
# Let's submit a job from the galaxy container and check it runs in the slurm container
sleep 40s
docker cp testscript.sh galaxy-slurm-test:/export/galaxy-central/testscript.sh
docker exec galaxy-slurm-test chmod +x /export/galaxy-central/testscript.sh
docker exec galaxy-slurm-test su - galaxy -c 'srun hostname' | grep slurm && \
docker stop galaxy-slurm-test slurm && \
docker rm galaxy-slurm-test slurm
# TODO: Run a galaxy tool and check it runs on the cluster
