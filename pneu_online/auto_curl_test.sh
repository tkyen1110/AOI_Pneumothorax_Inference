#!/bin/bash

ls_result=`ls dicom`
ls_result=$(echo ${ls_result})
IFS=" " read -a images <<< $ls_result

echo "Total ${#images[@]} images"

while true
do
  for (( i=0; i<${#images[@]}; i+=1 ))
  do
    echo $i, ${images[$i]}
    cmd="curl -X POST http://103.124.73.114:8082/ADV_pneu --header \"Content-Type: application/json\" --data '{\"dcm\": \"${images[$i]}\"}'"
    eval $cmd
    echo ""
  done
done