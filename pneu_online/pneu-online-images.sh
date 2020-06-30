#!/bin/bash
# Absolute path to this script.
# e.g. /home/ubuntu/workspaces/AOI_LinKou_Inference/dockerfile/dockerfile_aoi.sh
SCRIPT=$(readlink -f "$0")

# Absolute path this script is in.
# e.g. /home/ubuntu/workspaces/AOI_LinKou_Inference/dockerfile
HOST_AOI_PATH=$(dirname "$SCRIPT")
echo "HOST_AOI_PATH  = "$HOST_AOI_PATH

# AOI directory name
IFS='/' read -a array <<< "$HOST_AOI_PATH"
AOI_DIR_NAME="${array[-1]}"
echo "AOI_DIR_NAME   = "$AOI_DIR_NAME

CUSTOMER=""
VERSION=$2
if [ "$2" == "" ]
then
    VERSION="v2.1"
else
    VERSION=$2
fi
echo "VERSION        = "$VERSION

IMAGE_NAME="pneu_online:$VERSION"
CONTAINER_NAME="pneu_online_$VERSION"
echo "IMAGE_NAME     = "$IMAGE_NAME
echo "CONTAINER_NAME = "$CONTAINER_NAME


if [ "$1" == "build" ]
then
    if [ "$VERSION" == "v1.0" ]
    then
        IMAGE_ID=f459d94c2aa1
    elif [ "$VERSION" == "v2.0" ]
    then
        IMAGE_ID=c05f7c3cc59b
    elif [ "$VERSION" == "v2.1" ]
    then
        IMAGE_ID=fc3281ecb0ca
    fi

    echo "docker load --input pneu-online-images-$VERSION.tar"
    echo "docker tag $IMAGE_ID"

    docker load --input pneu-online-images-$VERSION.tar
    docker tag $IMAGE_ID $IMAGE_NAME

elif [ "$1" = "run" ]
then
    if [ "$CUSTOMER" == "NCKU" ]
    then
        DICOM_PATH=/mnt/datasets/pneu/dicom
        RESULT_PATH=/mnt/datasets/pneu/result

        echo "sudo mkdir -p $DICOM_PATH"
        echo "sudo mkdir -p $RESULT_PATH"
        echo "sudo chown -R $USER:$USER /mnt"

        sudo mkdir -p $DICOM_PATH
        sudo mkdir -p $RESULT_PATH
        sudo chown -R $USER:$USER /mnt
    else
        DICOM_PATH=$HOST_AOI_PATH/dicom
        RESULT_PATH=$HOST_AOI_PATH/result

        echo "mkdir -p $DICOM_PATH"
        echo "mkdir -p $RESULT_PATH"

        mkdir -p $DICOM_PATH
        mkdir -p $RESULT_PATH
    fi

    echo "docker run --gpus all -it --name $CONTAINER_NAME -v $DICOM_PATH:/tmp/data/dicom -v $RESULT_PATH:/tmp/data/result"
    echo "$IMAGE_NAME /bin/bash"

    # docker run --gpus all -it \
    # docker run --runtime=nvidia -it \
    docker run --gpus all -it \
        --name $CONTAINER_NAME \
        -v $DICOM_PATH:/tmp/data/dicom \
        -v $RESULT_PATH:/tmp/data/result \
        -p 5050:5050 \
        $IMAGE_NAME /bin/bash
        # --mount type=bind,source=$SCRIPT_PATH/.bashrc,target=/home/$USER/.bashrc \

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
