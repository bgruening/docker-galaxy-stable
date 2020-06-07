#!/bin/bash

_term() {
  echo "Caught SIGTERM signal!"
  echo "Trying to stop Kind cluster"
  kind delete cluster --name "${K8S_CLUSTER_NAME:-galaxy}" || true
  exit 0
}
trap _term SIGTERM

if [ -z "$KIND_SKIP_CONFIG_LOCK" ]; then
  sleep 2
  echo "Waiting for Galaxy configurator to finish and release lock"
  until [ ! -f "$KIND_CONFIG_DIR/configurator.lock" ] && echo Lock released; do
  sleep 0.1;
  done;
fi
rm "${KUBECONFIG}_in_docker" || true

kind delete cluster --name "${K8S_CLUSTER_NAME:-galaxy}" || true
kind create cluster --config "$KIND_CONFIG_DIR/kind_config.yml" --kubeconfig "$KUBECONFIG" --name "${K8S_CLUSTER_NAME:-galaxy}" || true

# Create custom kubeconfig, that allows to reach the control-plane from inside the containers
REAL_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${K8S_CLUSTER_NAME:-galaxy}-control-plane")
cp "${KUBECONFIG}" "${KUBECONFIG}_in_docker"
sed -i "s/127.0.0.1:[0-9]*$/${REAL_IP}:6443/g" "${KUBECONFIG}_in_docker"

export KUBECONFIG="${KUBECONFIG}_in_docker"
kubectl cluster-info

# Not all resources can be easily updated, therefore it is easier
# to remove the resources first, while the whole setup is
# still starting up
ls "$KIND_CONFIG_DIR/k8s_config"
kubectl delete -f "$KIND_CONFIG_DIR/k8s_config" || true
kubectl apply -f "$KIND_CONFIG_DIR/k8s_config"

# Wait for SIGTERM and delete cluster
sleep inf & wait
