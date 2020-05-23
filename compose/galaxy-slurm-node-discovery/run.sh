#!/bin/sh

# This script is used to replace the container name of a slurm node
# with its correct hostname. This is needed, as a hostname can not
# include '_', which is the case for docker-compose.
sleep 5
echo "Waiting for Galaxy configurator to finish and release lock"
until [ ! -f /etc/slurm-llnl/configurator.lock ] && echo Lock released; do
  sleep 0.1;
done;

grep < /etc/slurm-llnl/slurm.conf "NodeName=" | while read -r line; do
  node=$(echo "$line" | sed "s/NodeName=\(.*\) \(NodeAddr.*\)/\1/")
  node_hostname=$(curl -s --unix-socket /var/run/docker.sock -XGET \
                       -H "Content-Type: application/json" http://v1.40/containers/json \
                       -G --data-urlencode "filters={\"name\":[\"$node\"]}" \
                  | jq -r '.[0] | .["Id"]' | head -c 12)
  sed -i "s/$node/$node_hostname/g" /etc/slurm-llnl/slurm.conf
done

sleep infinity
