#!/bin/bash

# Color
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

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

CUSTOMER=""
# CUSTOMER="NCKU"
VERSION=$2
if [ "$2" == "" ]
then
    VERSION="v1"
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

echo "HOME_NAME       = "$HOME_NAME
echo "CUSTOMER        = "$CUSTOMER

IFS=$'\n'
function Fun_EvalCmd()
{
    cmd_list=$1
    i=0
    for cmd in ${cmd_list[*]}
    do
        ((i+=1))
        printf "${GREEN}${cmd}${NC}\n"
        eval $cmd
    done
}


if [ "$1" == "build" ]
then
    export GID=$(id -g)

    echo "docker build --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$GID --build-arg HOME_NAME=$HOME_NAME"
    echo "-f $DOCKERFILE_NAME -t $IMAGE_NAME ."

    lCmdList=(
                "docker build \
                    --build-arg USER=$USER \
                    --build-arg UID=$UID \
                    --build-arg GID=$GID \
                    --build-arg HOME_NAME=$HOME_NAME \
                    -f $DOCKERFILE_NAME \
                    -t $IMAGE_NAME ."
             )
    Fun_EvalCmd "${lCmdList[*]}"

elif [ "$1" = "run" ]
then
    if [ "$CUSTOMER" == "NCKU" ]
    then
        CONFIG_PATH=/mnt/datasets/pneu/config
        DICOM_PATH=/mnt/datasets/pneu/dicom
        RESULT_PATH=/mnt/datasets/pneu/result

        lCmdList=(
                    "sudo mkdir -p $CONFIG_PATH" \
                    "sudo mkdir -p $DICOM_PATH" \
                    "sudo mkdir -p $RESULT_PATH" \
                    "sudo chown -R $USER:$USER /mnt"
                 )
        Fun_EvalCmd "${lCmdList[*]}"

    else
        CONFIG_PATH=$HOST_AOI_PATH/config
        DICOM_PATH=$HOST_AOI_PATH/dicom
        RESULT_PATH=$HOST_AOI_PATH/result

        lCmdList=(
                    "mkdir -p $CONFIG_PATH" \
                    "mkdir -p $DICOM_PATH" \
                    "mkdir -p $RESULT_PATH"
                 )
        Fun_EvalCmd "${lCmdList[*]}"

    fi

    lCmdList=(
                "docker run --name $CONTAINER_NAME $IMAGE_NAME" \
                "docker cp $CONTAINER_NAME:/tmp/data/config/config.yaml $CONFIG_PATH" \
                "docker stop $CONTAINER_NAME" \
                "docker rm $CONTAINER_NAME" \
                "docker run --gpus all -itd \
                    --name $CONTAINER_NAME \
                    -v /tmp/.X11-unix:/tmp/.X11-unix \
                    -v $HOST_AOI_PATH/pneu_aiaa:/home/$HOME_NAME/pneu_aiaa \
                    -v $CONFIG_PATH:/tmp/data/config \
                    -v $DICOM_PATH:/tmp/data/dicom \
                    -v $RESULT_PATH:/tmp/data/result \
                    --mount type=bind,source=$SCRIPT_PATH/.bashrc,target=/home/$HOME_NAME/.bashrc \
                    -p 8080:5000 \
                    $IMAGE_NAME /bin/bash"
             )
    Fun_EvalCmd "${lCmdList[*]}"

    # -p 80:5050 \

elif [ "$1" = "exec" ]
then
    lCmdList=(
                "docker exec -it $CONTAINER_NAME /bin/bash"
             )
    Fun_EvalCmd "${lCmdList[*]}"

elif [ "$1" = "start" ]
then
    lCmdList=(
                "docker start $CONTAINER_NAME"
             )
    Fun_EvalCmd "${lCmdList[*]}"

elif [ "$1" = "stop" ]
then
    lCmdList=(
                "docker stop $CONTAINER_NAME"
             )
    Fun_EvalCmd "${lCmdList[*]}"

elif [ "$1" = "rm" ]
then
    lCmdList=(
                "docker rm $CONTAINER_NAME"
             )
    Fun_EvalCmd "${lCmdList[*]}"

elif [ "$1" = "rmi" ]
then
    lCmdList=(
                "docker rmi $IMAGE_NAME"
             )
    Fun_EvalCmd "${lCmdList[*]}"

fi
