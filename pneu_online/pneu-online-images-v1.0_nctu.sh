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

VERSION=$2
if [ "$2" == "" ]
then
    VERSION="v1.0"
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
    echo "docker load --input pneu-online-images-v1.0.tar"
    echo "docker tag f459d94c2aa1 $IMAGE_NAME"
    docker load --input pneu-online-images-v1.0.tar
    docker tag f459d94c2aa1 $IMAGE_NAME
elif [ "$1" = "run" ]
then
    echo "docker run --gpus all -it --name $CONTAINER_NAME -v $HOST_AOI_PATH/dicom:/tmp/data/dicom -v $HOST_AOI_PATH/result:/tmp/data/result"
    echo "$IMAGE_NAME /bin/bash"

    DICOM_PATH=/mnt/datasets/pneu/dicom
    RESULT_PATH=/mnt/datasets/pneu/result
    echo "mkdir $DICOM_PATH"
    echo "mkdir $RESULT_PATH"
    sudo mkdir $DICOM_PATH
    sudo mkdir $RESULT_PATH
    
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
    echo "docker start $CONTAINER_NAME"
    echo "docker exec -it $CONTAINER_NAME /bin/bash"
    docker start $CONTAINER_NAME
    docker exec -it $CONTAINER_NAME /bin/bash
elif [ "$1" = "stop" ]
then
    echo "docker stop $CONTAINER_NAME"
    docker stop $CONTAINER_NAME
elif [ "$1" = "rm" ]
then
    echo "docker stop $CONTAINER_NAME"
    echo "docker rm $CONTAINER_NAME"
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
elif [ "$1" = "rmi" ]
then
    echo "docker rmi $IMAGE_NAME"
    docker rmi $IMAGE_NAME
fi
