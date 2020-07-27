#!/bin/bash

ls_result=`ls dicom`
ls_result=$(echo ${ls_result})
IFS=" " read -a images <<< $ls_result

echo "Total ${#images[@]} images"
for (( i=0; i<${#images[@]}; i+=1 ))
do
  total=${#images[@]}
  (( j = total - i - 1))
  echo $j, ${images[$j]}
  cmd="curl -X POST http://203.145.222.39:5050/ADV_pneu --header \"Content-Type: application/json\" --data '{\"dcm\": \"${images[$j]}\"}'"
  eval $cmd
  echo ""
done