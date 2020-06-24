#!/bin/bash
# Absolute path to this script.
# e.g. /home/ubuntu/workspaces/AOI_LinKou_Inference/dockerfile/dockerfile_aoi.sh
SCRIPT=$(readlink -f "$0")

# Absolute path this script is in.
# e.g. /home/ubuntu/workspaces/AOI_LinKou_Inference/dockerfile
SCRIPT_PATH=$(dirname "$SCRIPT")

# Absolute path to the AOI path
# e.g. /home/ubuntu/workspaces/AOI_LinKou_Inference
HOST_AOI_PATH=$(dirname "$SCRIPT_PATH")
echo "HOST_AOI_PATH  = "$HOST_AOI_PATH

# AOI directory name
IFS='/' read -a array <<< "$HOST_AOI_PATH"
AOI_DIR_NAME="${array[-1]}"
echo "AOI_DIR_NAME   = "$AOI_DIR_NAME


VERSION=$2
if [ "$2" == "" ]
then
    VERSION="v0"
else
    VERSION=$2
fi
echo "VERSION         = "$VERSION

DOCKERFILE_NAME="dockerfile_pneu_aiaa"
IMAGE_NAME="pneu_aiaa:$VERSION"
CONTAINER_NAME="pneu_aiaa_$VERSION"
echo "DOCKERFILE_NAME = "$DOCKERFILE_NAME
echo "IMAGE_NAME      = "$IMAGE_NAME
echo "CONTAINER_NAME  = "$CONTAINER_NAME

HOME_NAME="webService"
if [ -z "$HOME_NAME" ]
then
    HOME_NAME=$USER
fi
CUSTOMER=""
# CUSTOMER="NCKU"
echo "HOME_NAME       = "$HOME_NAME
echo "CUSTOMER        = "$CUSTOMER

if [ "$1" == "build" ]
then
    export GID=$(id -g)

    echo "docker build --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$GID --build-arg HOME_NAME=$HOME_NAME"
    echo "-f $DOCKERFILE_NAME -t $IMAGE_NAME ."

    docker build \
        --build-arg USER=$USER \
        --build-arg UID=$UID \
        --build-arg GID=$GID \
        --build-arg HOME_NAME=$HOME_NAME \
        -f $DOCKERFILE_NAME \
        -t $IMAGE_NAME .

elif [ "$1" = "run" ]
then
    if [ "$CUSTOMER" == "NCKU" ]
    then
        CONFIG_PATH=/mnt/datasets/pneu/config
        DICOM_PATH=/mnt/datasets/pneu/dicom
        RESULT_PATH=/mnt/datasets/pneu/result

        echo "sudo mkdir -p $CONFIG_PATH"
        echo "sudo mkdir -p $DICOM_PATH"
        echo "sudo mkdir -p $RESULT_PATH"
        echo "sudo chown -R $USER:$USER /mnt"

        sudo mkdir -p $CONFIG_PATH
        sudo mkdir -p $DICOM_PATH
        sudo mkdir -p $RESULT_PATH
        sudo chown -R $USER:$USER /mnt
    else
        CONFIG_PATH=$HOST_AOI_PATH/config
        DICOM_PATH=$HOST_AOI_PATH/dicom
        RESULT_PATH=$HOST_AOI_PATH/result

        echo "mkdir -p $CONFIG_PATH"
        echo "mkdir -p $DICOM_PATH"
        echo "mkdir -p $RESULT_PATH"

        mkdir -p $CONFIG_PATH
        mkdir -p $DICOM_PATH
        mkdir -p $RESULT_PATH
    fi

    echo "docker run --gpus all -it --name $CONTAINER_NAME -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOST_AOI_PATH/pneu_aiaa:/home/$HOME_NAME/pneu_aiaa"
    echo "-v $DICOM_PATH:/tmp/data/dicom -v $RESULT_PATH:/tmp/data/result"
    echo "--mount type=bind,source=$SCRIPT_PATH/.bashrc,target=/home/$HOME_NAME/.bashrc -p 5000:5000 $IMAGE_NAME /bin/bash"

    docker run --gpus all -it \
        --name $CONTAINER_NAME \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v $HOST_AOI_PATH/pneu_aiaa:/home/$HOME_NAME/pneu_aiaa \
        -v $DICOM_PATH:/tmp/data/dicom \
        -v $RESULT_PATH:/tmp/data/result \
        --mount type=bind,source=$SCRIPT_PATH/.bashrc,target=/home/$HOME_NAME/.bashrc \
        -p 5000:5000 \
        $IMAGE_NAME /bin/bash

elif [ "$1" = "exec" ]
then
    echo "docker exec -it $CONTAINER_NAME /bin/bash"
    docker exec -it $CONTAINER_NAME /bin/bash

elif [ "$1" = "start" ]
then
    echo "docker start $CONTAINER_NAME"
    docker start $CONTAINER_NAME

elif [ "$1" = "stop" ]
then
    echo "docker stop $CONTAINER_NAME"
    docker stop $CONTAINER_NAME

elif [ "$1" = "rm" ]
then
    echo "docker rm $CONTAINER_NAME"
    docker rm $CONTAINER_NAME

elif [ "$1" = "rmi" ]
then
    echo "docker rmi $IMAGE_NAME"
    docker rmi $IMAGE_NAME
fi
