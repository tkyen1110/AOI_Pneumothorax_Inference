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
    VERSION="v5.4"
else
    VERSION=$2
fi
echo "VERSION        = "$VERSION

IMAGE_NAME="pneu-online:$VERSION"
CONTAINER_NAME="pneu-online-$VERSION"
echo "IMAGE_NAME     = "$IMAGE_NAME
echo "CONTAINER_NAME = "$CONTAINER_NAME

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
    # docker load --input pneu-online-images-$VERSION.tar
    # docker tag $IMAGE_ID $IMAGE_NAME

    lCmdList=(
                "unzip twcc_online_$VERSION.zip" \
                "cd twcc_online_$VERSION/dockerfile" \
                "bash dockerfile-pneu-build.sh"
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
        CONFIG_PATH=$SCRIPT_PATH/config
        DICOM_PATH=$SCRIPT_PATH/dicom
        RESULT_PATH=$SCRIPT_PATH/result

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
                    -v $CONFIG_PATH:/tmp/data/config \
                    -v $DICOM_PATH:/tmp/data/dicom \
                    -v $RESULT_PATH:/tmp/data/result \
                    -p 5050:5050 \
                    $IMAGE_NAME /bin/bash" \
                "docker exec -it $CONTAINER_NAME /bin/bash"
             )
    Fun_EvalCmd "${lCmdList[*]}"

    # docker run --runtime=nvidia -it \
    # --mount type=bind,source=$SCRIPT_PATH/.bashrc,target=/home/$USER/.bashrc \

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
