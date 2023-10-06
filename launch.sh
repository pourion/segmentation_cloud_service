#!/usr/bin/env bash


CONT_NAME=${CONT_NAME:=segmentation}
IMAGE_NAME=${IMAGE_NAME:=docker.io/pourion/segmentation}
REGISTRY_USER=${REGISTRY_USER:='$oauthtoken'}
REGISTRY=${REGISTRY:=NotSpecified}
REGISTRY_ACCESS_TOKEN=${REGISTRY_ACCESS_TOKEN:=NotSpecified}
JUPYTER_PORT=${JUPYTER_PORT:=8888}
DATA_PATH=${DATA_PATH:=/data}
DATA_MOUNT_PATH=${DATA_MOUNT_PATH:=/data}
RESULT_MOUNT_PATH=${RESULT_MOUNT_PATH:=/results}
RESULT_PATH=${RESULT_PATH:=/results/}
###############################################################################
#
# if $LOCAL_ENV file exists, source it to specify my environment
#
###############################################################################
LOCAL_ENV=.env

if [ -e ./$LOCAL_ENV ]
then
    echo sourcing environment from ./$LOCAL_ENV
    . ./$LOCAL_ENV
    write_env=0
else
    echo $LOCAL_ENV does not exist. Writing deafults to $LOCAL_ENV
    write_env=1
fi

###############################################################################
#
# If $LOCAL_ENV was not found, write out a template for user to edit
#
###############################################################################

if [ $write_env -eq 1 ]; then
    echo CONT_NAME=${CONT_NAME} >> $LOCAL_ENV
    echo IMAGE_NAME=${IMAGE_NAME} >> $LOCAL_ENV
    echo JUPYTER_PORT=${JUPYTER_PORT} >> $LOCAL_ENV
    echo DATA_PATH=${DATA_PATH} >> $LOCAL_ENV
    echo DATA_MOUNT_PATH=${DATA_MOUNT_PATH} >> $LOCAL_ENV
    echo RESULT_MOUNT_PATH=${RESULT_MOUNT_PATH} >> $LOCAL_ENV
    echo RESULT_PATH=${RESULT_PATH} >> $LOCAL_ENV
    echo REGISTRY_USER=${REGISTRY_USER} >> $LOCAL_ENV
    echo REGISTRY=${REGISTRY} >> $LOCAL_ENV
    echo REGISTRY_ACCESS_TOKEN=${REGISTRY_ACCESS_TOKEN} >> $LOCAL_ENV
fi



DOCKER_CMD="docker run \
    --network host \
    --gpus all \
    --shm-size=64gb \
    -p ${JUPYTER_PORT}:8888 \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -v /etc/shadow:/etc/shadow:ro \
    -v $(pwd):/workspace \
    -e HOME=/workspace \
    -w /workspace"


usage() {
    echo "Please read README."
}


build() {
    set -x
    DOCKER_FILE="Dockerfile"

    echo -e "Building ${DOCKER_FILE}..."
    docker build \
        -t ${IMAGE_NAME}:0.0.1 \
        -t ${IMAGE_NAME}:latest \
        -f ${DOCKER_FILE} .
}


dev() {
    local DEV_IMG=${IMAGE_NAME}

    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--image)
                DEV_IMG="$2"
                shift
                shift
                ;;
	    -d|--deamon)
                DOCKER_CMD="${DOCKER_CMD} -d"
                shift
                ;;
            *)
                echo "Unknown option $1"
                exit 1
                ;;
        esac
    done

    $DOCKER_CMD \
        --name ${CONT_NAME} \
        -u $(id -u):$(id -u) \
        -e PYTHONPATH=$DEV_PYTHONPATH \
        -it --rm \
        ${DEV_IMG} \
        bash
}


attach() {
    DOCKER_CMD="docker exec"
    CONTAINER_ID=$(docker ps | grep ${CONT_NAME} | cut -d' ' -f1)
    ${DOCKER_CMD} -it ${CONTAINER_ID} /bin/bash
    exit
}


push() {
    local IMG_BASENAME=($(echo ${IMAGE_NAME} | tr ":" "\n"))
    docker login ${REGISTRY} -u ${REGISTRY_USER} -p ${REGISTRY_ACCESS_TOKEN}
    # docker push ${IMG_BASENAME[0]}:latest
    docker push ${IMAGE_NAME}
    exit
}


pull() {
    docker login ${REGISTRY} -u ${REGISTRY_USER} -p ${REGISTRY_ACCESS_TOKEN}
    docker pull ${IMAGE_NAME}
    exit
}


case $1 in
    build)
        "$@"
        ;;
    push)
        "$@"
        ;;
    pull)
        "$@"
        ;;
    dev)
        "$@"
        exit 0
        ;;
    attach)
        $@
        ;;
    *)
        usage
        ;;
esac
