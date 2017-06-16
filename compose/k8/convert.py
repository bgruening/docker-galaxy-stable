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
    ftp_ports = raw_compose_def["services"]["galaxy-proftpd"]["ports"]
    del ftp_ports[2]
    for i in range(10):
        # Replace "30000-30010:30000-30010" with individual entries.
        ftp_ports.append("%d:%d" % (30000 + i, 30000 + i))

    # pgadmin can run without volumes and gets permission errors if not started this way in
    # minikube.
    if raw_compose_def["services"]["pgadmin4"].get("volumes"):
        del raw_compose_def["services"]["pgadmin4"]["volumes"]

    services = raw_compose_def["services"]
    for service_name in list(services.keys()):
        service_def = services[service_name]
        if "hostname" in service_def:
            hostname = service_def["hostname"]
            # These need to be same for Kompose it seems
            if hostname != service_name:
                services[hostname] = service_def
                del services[service_name]
            for service in services.values():
                links = service.get("links", [])
                if service_name in links:
                    links.remove(service_name)
                    links.append(hostname)

            del service_def["hostname"]
        
        if "privileged" in service_def:
            del service_dir["privileged"]

if __name__ == "__main__":
    main()
