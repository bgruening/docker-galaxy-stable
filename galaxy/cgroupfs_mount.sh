#!/bin/bash
set -e

# DinD: a wrapper script which allows docker to be run inside a docker container.
# Original version by Jerome Petazzoni <jerome@docker.com>
# See the blog post: https://blog.docker.com/2013/09/docker-can-now-run-within-docker/
#
# This script should be executed inside a docker container in privilieged mode
# ('docker run --privileged', introduced in docker 0.6).

# Usage: dind CMD [ARG...]

# apparmor sucks and Docker needs to know that it's in a container (c) @tianon
export container=docker

if [ -d /sys/kernel/security ] && ! mountpoint -q /sys/kernel/security; then
	mount -t securityfs none /sys/kernel/security || {
		echo >&2 'Could not mount /sys/kernel/security.'
		echo >&2 'AppArmor detection and --privileged mode might break.'
	}
fi

# Mount /tmp (conditionally)
if ! mountpoint -q /tmp; then
	mount -t tmpfs none /tmp
fi


# If a pidfile is still around (for example after a container restart),
# delete it so that docker can start.
rm -rf /var/run/docker.pid
