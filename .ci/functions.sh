#!/usr/bin/env bash

## define a container size check function, first parameter is the container name, second the max allowed size in MB
container_size_check () {

  # check that the image size is not growing too much between releases
  # the 19.05 monolithic image was around 1.500 MB
  size=`docker image inspect $1 --format='{{.Size}}'`
  size_in_mb=$(($size/(1024*1024)))
  if [[ $size_in_mb -ge $2 ]]
  then
      echo "The new compiled image ($1) is larger than allowed. $size_in_mb vs. $2"
      sleep 2
      #exit
  fi
}

# Define start functions
docker_exec() {
    cd $WORKING_DIR
    docker-compose exec galaxy-web "$@"
}
docker_exec_run() {
cd $WORKING_DIR
    docker-compose exec galaxy-web "$@"
}
docker_run() {
    cd $WORKING_DIR
    docker-compose run "$@"
}
