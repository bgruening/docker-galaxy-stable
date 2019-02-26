#!/bin/bash
# vi: fdm=marker

set -e

### Constants ###

SCRIPT_NAME="${0##*/}"
TRUE='true'
FALSE='false'
DFT_DOCKER_PUSH_ENABLED=$TRUE

### Functions ###

function log() {
  echo -e "$@" >&2
}

function error {
	local msg=$1
	local code=$2
	[[ -z $code ]] && code=1
	log "[ERROR] $msg"

	exit $code
}


function debug {
    local msg=$1
    local level=$2
    [[ -n $level ]] || level=1

    [[ $DEBUG -lt $level ]] || log "[DEBUG] $msg"
}

function warning {
    local msg=$1

    log "[WARNING] ##### $msg #####"
}

function print_help {
    (
        echo "Usage: $SCRIPT_NAME [options]"
        echo
        echo "Build Galaxy docker compose images for different purposes."
        echo
        echo "Options:"
        echo "   -g, --debug                    Debug mode. [false]"
        echo "   -h, --help                     Print this help message."
        echo "   -p, --push                     Push docker images. You can also set environment variable DOCKER_PUSH_ENABLED to \"true\". [true]"
        echo "   +p, --no-push                  Do not push dockers. You can also set environment variable DOCKER_PUSH_ENABLED to \"false\"."
        echo "       --push-intermediate        Also push intermediate images [false]"
        echo "       --no-cache                 Tell Docker not to use cached images. [false]"
        echo "       --init-tag       <tag>     Set the tag for the Galaxy Init Flavour container image."
        echo "       --postgres-tag   <tag>     Set the tag for the Galaxy Postgres container image."
        echo "       --proftpd-tag    <tag>     Set the tag for the Galaxy Proftpd container image."
        echo "       --web-tag        <tag>     Set the tag for the Galaxy Web k8s container image."
        echo "       --k8s                      Set settings for Kubernetes usage."
        echo "       --grafana                  Build grafana container."
        echo "       --condor                   Build condor containers."
        echo "       --slurm                    Build slurm containers."
        echo "   -u, --container-user <user>    Set the container user. You can also set the environment variable CONTAINER_USER."
        echo "   -r, --container-registry <reg> Set the container registry. You can also set the environment variable CONTAINER_REGISTRY."
        echo
    ) >&2
}

function read_args {

    local args="$*" # save arguments for debugging purpose

    # Read options
    while [[ $# > 0 ]] ; do
        shift_count=1
        case $1 in
            -g|--debug)              DEBUG=$((DEBUG + 1)) ;;
            -h|--help)               print_help ; exit 0 ;;
            -p|--push)               DOCKER_PUSH_ENABLED=$TRUE ;;
            +p|--no-push)            DOCKER_PUSH_ENABLED=$FALSE ;;
            --k8s)                   BUILD_FOR_K8S=$TRUE ;;
            --condor)                BUILD_FOR_CONDOR=$TRUE ;;
            --slurm)                 BUILD_FOR_SLURM=$TRUE ;;
            --grafana)               BUILD_FOR_GRAFANA=$TRUE ;;
            --push-intermediate)     PUSH_INTERMEDIATE_IMAGES=$TRUE ;;
            --no-cache)              NO_CACHE="--no-cache" ;;
            --postgres-tag)          OVERRIDE_POSTGRES_TAG="$2" ; shift_count=2 ;;
            --proftpd-tag)           OVERRIDE_PROFTPD_TAG="$2" ; shift_count=2 ;;
            --init-tag)              OVERRIDE_GALAXY_INIT_PHENO_FLAVOURED_TAG="$2" ; shift_count=2 ;;
            --web-tag)               OVERRIDE_GALAXY_WEB_TAG="$2" ; shift_count=2 ;;
            -u|--container-user)     CONTAINER_USER="$2" ; shift_count=2 ;;
            -r|--container-registry) CONTAINER_REGISTRY="$2" ; shift_count=2 ;;
            *) error "Illegal option $1." 98 ;;
        esac
        shift $shift_count
    done

    # Debug messages
    debug "Command line arguments: $args"
    debug "Argument DEBUG=$DEBUG"
    debug "Argument DOCKER_PUSH_ENABLED=$DOCKER_PUSH_ENABLED"
    debug "Argument DOCKER_USER=$DOCKER_USER"
    debug "Argument OVERRIDE_GALAXY_WEB_TAG=$OVERRIDE_GALAXY_WEB_TAG"
    debug "Argument OVERRIDE_POSTGRES_TAG=$OVERRIDE_POSTGRES_TAG"
    debug "Argument OVERRIDE_PROFTPD_TAG=$OVERRIDE_PROFTPD_TAG"
    debug "shift_count=$shift_count"
}

### MAIN ###
BUILD_FOR_K8S=$FALSE
BUILD_FOR_CONDOR=$FALSE
BUILD_FOR_GRAFANA=$FALSE
BUILD_FOR_SLURM=$FALSE

read_args "$@"

DOCKER_PUSH_ENABLED=${DOCKER_PUSH_ENABLED:-$DFT_DOCKER_PUSH_ENABLED}

DOCKER_REPO=${CONTAINER_REGISTRY:-quay.io/}
DOCKER_USER=${CONTAINER_USER:-bgruening}

ANSIBLE_REPO=${ANSIBLE_REPO:-galaxyproject/ansible-galaxy-extras}
ANSIBLE_RELEASE=${ANSIBLE_RELEASE:-master}

GALAXY_VERSION=${GALAXY_VERSION:-19.01}

# GALAXY_BASE_FROM_TO_REPLACE=${GALAXY_BASE_FROM_TO_REPLACE:-quay.io/bgruening/galaxy-base:$GALAXY_VERSION}
GALAXY_BASE_FROM_TO_REPLACE=$(grep ^FROM galaxy-init/Dockerfile | awk '{ print $2 }') # init starts from base, so we get it from there.
CONDOR_BASE_FROM_TO_REPLACE=quay.io/bgruening/galaxy-htcondor-base:$GALAXY_VERSION

GALAXY_RELEASE=${GALAXY_RELEASE:-release_$GALAXY_VERSION}
GALAXY_REPO=${GALAXY_REPO:-galaxyproject/galaxy}

GALAXY_VER_FOR_POSTGRES=$GALAXY_VERSION
# Uncomment to push intermediate images, otherwise only the images needed for the helm chart are pushed.
#PUSH_INTERMEDIATE_IMAGES=yes

# Set tags
TAG=${GALAXY_TAG:-$GALAXY_VERSION}

# TODO This is PhenoMeNal Jenkins specific, should be removed at some point.
if [[ -n ${CONTAINER_TAG_PREFIX:-} && -n ${BUILD_NUMBER:-} ]]; then
    TAG=${CONTAINER_TAG_PREFIX}.${BUILD_NUMBER}
fi

if [[ -n "${DOCKER_REPO}" ]]; then
    # Append slash, avoiding double slash
    DOCKER_REPO="${DOCKER_REPO%/}/"
fi

GALAXY_BASE_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-base:$TAG
GALAXY_INIT_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-init:$TAG
GALAXY_WEB_TAG=${OVERRIDE_GALAXY_WEB_TAG:-$DOCKER_REPO$DOCKER_USER/galaxy-web:$TAG}

# Set postgres tag
if [[ -n "${OVERRIDE_POSTGRES_TAG:-}" ]]; then
    POSTGRES_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-postgres:$OVERRIDE_POSTGRES_TAG
else
    PG_Dockerfile="galaxy-postgres/Dockerfile"

    [[ -f "${PG_Dockerfile}" ]] || error "The galaxy-postgres Dockerfile is missing under galaxy-Postgres." 99
    POSTGRES_VERSION=$(grep FROM "${PG_Dockerfile}" | awk -F":" '{ print $2 }')

    POSTGRES_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-postgres:$POSTGRES_VERSION"_for_"$GALAXY_VER_FOR_POSTGRES
fi

if [[ -n "${OVERRIDE_PROFTPD_TAG:-}" ]]; then
    PROFTPD_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-proftpd:$OVERRIDE_PROFTPD_TAG
else
    PROFTPD_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-proftpd:for_galaxy_$GALAXY_VER_FOR_POSTGRES
fi

CONDOR_BASE_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-htcondor-base:$TAG
CONDOR_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-htcondor:$TAG
CONDOR_EXEC_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-htcondor-executor:$TAG
GRAFANA_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-grafana:$TAG
SLURM_TAG=$DOCKER_REPO$DOCKER_USER/galaxy-slurm:$TAG
### do work

if [ -n $ANSIBLE_REPO ]
    then
       log "Making custom galaxy-base:$TAG from $ANSIBLE_REPO at $ANSIBLE_RELEASE"
       docker build $NO_CACHE --build-arg ANSIBLE_REPO=$ANSIBLE_REPO --build-arg ANSIBLE_RELEASE=$ANSIBLE_RELEASE -t $GALAXY_BASE_TAG galaxy-base/
       if [[ ! -z ${PUSH_INTERMEDIATE_IMAGES+x} ]];
       then
	         log "Pushing intermediate image $DOCKER_REPO$DOCKER_USER/galaxy-base:$TAG"
           docker push $GALAXY_BASE_TAG
       fi
fi


if [ -n $GALAXY_REPO ]
    then
       log "Making custom galaxy-init:$TAG from $GALAXY_REPO at $GALAXY_RELEASE"
       DOCKERFILE_INIT_1=Dockerfile
       if [ -n $ANSIBLE_REPO ]
       then
         sed s+$GALAXY_BASE_FROM_TO_REPLACE+$GALAXY_BASE_TAG+ galaxy-init/Dockerfile > galaxy-init/Dockerfile_init
	       FROM=`grep ^FROM galaxy-init/Dockerfile_init | awk '{ print $2 }'`
	       log "Using FROM $FROM for galaxy init"
	       DOCKERFILE_INIT_1=Dockerfile_init
       fi
       docker build $NO_CACHE --build-arg GALAXY_REPO=$GALAXY_REPO --build-arg GALAXY_RELEASE=$GALAXY_RELEASE -t $GALAXY_INIT_TAG -f galaxy-init/$DOCKERFILE_INIT_1 galaxy-init/
       if [[ "${DOCKER_PUSH_ENABLED:-}" = "true" ]]; then
	       log "Pushing image $GALAXY_INIT_TAG"
         docker push $GALAXY_INIT_TAG
       fi
fi


DOCKERFILE_WEB=Dockerfile
if [ -n $GALAXY_REPO ]
then
	log "Making custom galaxy-web:$TAG from $GALAXY_REPO at $GALAXY_RELEASE"
	GALAXY_BASE_FROM_TO_REPLACE=$(grep ^FROM galaxy-web/Dockerfile | awk '{ print $2 }')
	sed s+$GALAXY_BASE_FROM_TO_REPLACE+$GALAXY_BASE_TAG+ galaxy-web/Dockerfile > galaxy-web/Dockerfile_web
	FROM=$(grep ^FROM galaxy-web/Dockerfile_web | awk '{ print $2 }')
	log "Using FROM $FROM for galaxy web"
	DOCKERFILE_WEB=Dockerfile_web
fi
K8S_ANSIBLE_TAGS=""
if $BUILD_FOR_K8S; then
  K8S_ANSIBLE_TAGS=,k8,k8s
fi
docker build $NO_CACHE --build-arg GALAXY_ANSIBLE_TAGS=supervisor,startup,scripts,nginx,cvmfs$K8S_ANSIBLE_TAGS -t $GALAXY_WEB_TAG -f galaxy-web/$DOCKERFILE_WEB galaxy-web/
if $DOCKER_PUSH_ENABLED; then
  docker push $GALAXY_WEB_TAG
fi

# Create dump for postgres based on init created here
export GALAXY_INIT_TAG
./dumpsql.sh

# Build postgres
docker build -t $POSTGRES_TAG -f galaxy-postgres/Dockerfile galaxy-postgres/
if $DOCKER_PUSH_ENABLED; then
  docker push $POSTGRES_TAG
fi

# Build proftpd
docker build -t $PROFTPD_TAG -f galaxy-proftpd/Dockerfile galaxy-proftpd/
if $DOCKER_PUSH_ENABLED; then
  docker push $PROFTPD_TAG
fi

# Build condor
if $BUILD_FOR_CONDOR; then
  docker build $NO_CACHE -t $CONDOR_BASE_TAG galaxy-htcondor-base
  sed s+$CONDOR_BASE_FROM_TO_REPLACE+$CONDOR_BASE_TAG+ galaxy-htcondor/Dockerfile > galaxy-htcondor/Dockerfile_condor
  FROM=`grep ^FROM galaxy-htcondor/Dockerfile_condor | awk '{ print $2 }'`
  log "Using FROM $FROM for condor"
  docker build $NO_CACHE -t $CONDOR_TAG -f galaxy-htcondor/Dockerfile_condor galaxy-htcondor/
  sed s+$CONDOR_BASE_FROM_TO_REPLACE+$CONDOR_BASE_TAG+ galaxy-htcondor-executor/Dockerfile > galaxy-htcondor-executor/Dockerfile_condor
  FROM=`grep ^FROM galaxy-htcondor-executor/Dockerfile_condor | awk '{ print $2 }'`
  log "Using FROM $FROM for condor-executor"
  docker build $NO_CACHE -t $CONDOR_EXEC_TAG -f galaxy-htcondor-executor/Dockerfile_condor galaxy-htcondor-executor/
  if $DOCKER_PUSH_ENABLED; then
    docker push $CONDOR_TAG
    docker push $CONDOR_EXEC_TAG
  fi
fi

# Build for slurm
if $BUILD_FOR_SLURM; then
  docker build -t $SLURM_TAG ./galaxy-slurm
fi

# Build for grafana
if $BUILD_FOR_GRAFANA; then
  docker build -t $GRAFANA_TAG ./galaxy-grafana
fi

log "Relevant containers:"
log "Web:          $GALAXY_WEB_TAG"
log "Init:         $GALAXY_INIT_TAG"
log "Postgres:     $POSTGRES_TAG"
log "Proftpd:      $PROFTPD_TAG"
if $BUILD_FOR_CONDOR; then
  log "Condor:       $CONDOR_TAG"
  log "Condor-exec:  $CONDOR_EXEC_TAG"
fi
if $BUILD_FOR_SLURM; then
  log "Slurm:        $SLURM_TAG"
fi
if $BUILD_FOR_GRAFANA; then
  log "Grafana:     $GRAFANA_TAG"
fi

log "Now build your own Galaxy init container starting FROM $GALAXY_INIT_TAG to add you own flavour, tools, workflows, etc."
if $BUILD_FOR_K8S; then
  log ""
  log "For k8s: Once you have built your own init container use it within the galaxy-stable Helm chart at https://github.com/galaxyproject/galaxy-kubernetes together with:"
  log " - Web: $GALAXY_WEB_TAG"
  log " - Postgres: $POSTGRES_TAG"
  log " - Proftpd: $PROFTPD_TAG"
fi

echo "export TAG="$(echo $GALAXY_WEB_TAG | awk -F':' '{print $2}')  > tags-for-compose-to-source.sh
echo "export TAG_POSTGRES="$(echo $POSTGRES_TAG | awk -F':' '{print $2}') >> tags-for-compose-to-source.sh
echo "export TAG_PROFTPD="$(echo $PROFTPD_TAG | awk -F':' '{print $2}') >> tags-for-compose-to-source.sh
