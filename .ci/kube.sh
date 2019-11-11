#!/usr/bin/env bash

set -o errexit

source .ci/set_env.sh
source .ci/functions.sh

# setup k8s, we will do this before building Galaxy because it takes some time and hopefully we can do both in prallel
gimme 1.11.1
source ~/.gimme/envs/go1.11.1.env
sudo ln -s /home/travis/.gimme/versions/go1.11.1.linux.amd64/bin/gofmt /usr/bin/gofmt
sudo ln -s /home/travis/.gimme/versions/go1.11.1.linux.amd64/bin/go /usr/bin/go
go version
mkdir ../kubernetes
wget -q -O - https://github.com/kubernetes/kubernetes/archive/master.tar.gz | tar xzf - --strip-components=1 -C ../kubernetes
cd ../kubernetes
# k8s API port is running by default on 8080 as Galaxy, can this to 8000
export API_PORT=8000
./hack/install-etcd.sh
sudo ln -s `pwd`/third_party/etcd/etcd /usr/bin/etcd
sudo ln -s `pwd`/third_party/etcd/etcdctl /usr/bin/etcdctl
# this needs to run in backgroud later, for now try to see the output
./hack/local-up-cluster.sh &
cd ../docker-galaxy-stable

# Installing kompose to convert the docker-compose YAML file

# The compose file recognises ENV vars to change the defaul behavior
cd ${COMPOSE_DIR}
ln -sf .env_k8_native .env

curl -L https://github.com/kubernetes-incubator/kompose/releases/download/v1.17.1/kompose-linux-amd64 -o kompose
chmod +x kompose
sudo mv ./kompose /usr/bin/kompose

# start building this repo
#git submodule update --init --recursive
#sudo chown 1450 /tmp && sudo chmod a=rwx /tmp


bash .ci/build_compose.sh

docker-compose logs --tail 50
docker ps


sleep 10
docker_exec_run shed-tools install -g "http://localhost:80" -a admin -t "$SAMPLE_TOOLS"

