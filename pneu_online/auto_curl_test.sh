#!/bin/bash

ls_result=`ls dicom`
ls_result=$(echo ${ls_result})
IFS=" " read -a images <<< $ls_result

total=0
echo "Total ${#images[@]} images"

while true
do
  for (( i=0; i<${#images[@]}; i+=1 ))
  do
    echo $i, ${images[$i]}
    cmd="curl -X POST http://203.145.222.39:8080/ADV_pneu --header \"Content-Type: application/json\" --data '{\"dcm\": \"${images[$i]}\"}'"
    result=`eval $cmd`

    if [ "$i" = "0" ]
    then
      echo $result > no_pneu_1.txt
    else
      echo $result >> no_pneu_1.txt
    fi
  done
done