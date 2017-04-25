#!/usr/bin/env python

# Install kompose (e.g. brew install kompose).
# Install minikube (e.g. brew install minikube).
# $ minikube start  # Build a k8 cluster in a VM.
# $ eval $(minikube docker-env) # Target Docker commands at the VM's Docker host.
# $ cd ..; bash buildlocal.sh; cd k8 # Build Docker containers required for k8 setup.
# $ python convert.py  # Execute this wrapper around kompose to build native k8 artifacts.
# $ kompose -f docker-compose-for-kompose.yml up

import os
import subprocess
import yaml

DIRECTORY = os.path.abspath(os.path.dirname(__file__))
COMPOSE_TARGET = os.path.abspath(os.path.join(DIRECTORY, "..", "docker-compose.yml"))
KOMPOSE_TARGET = os.path.join(DIRECTORY, "docker-compose-for-kompose.yml")


def main():
    with open(COMPOSE_TARGET, "r") as f:
        raw_compose_def = yaml.load(f)
    
    _hack_for_kompose(raw_compose_def)
    with open(KOMPOSE_TARGET, "w") as f:
        yaml.dump(raw_compose_def, f)

    subprocess.check_call(["kompose", "-f", KOMPOSE_TARGET, "convert"])


def _hack_for_kompose(raw_compose_def):
    ftp_ports = raw_compose_def["services"]["proftpd"]["ports"]
    del ftp_ports[2]
    for i in range(10):
        # Replace "30000-30010:30000-30010" with individual entries.
        ftp_ports.append("%d:%d" % (30000 + i, 30000 + i))


if __name__ == "__main__":
    main()
