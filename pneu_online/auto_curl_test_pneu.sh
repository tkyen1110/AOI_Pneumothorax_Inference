#!/bin/bash

ls_result=`ls dicom`
ls_result=$(echo ${ls_result})
IFS=" " read -a images <<< $ls_result

total=0
pneu=0
no_pneu=0

echo "Total ${#images[@]} images"
for (( i=0; i<${#images[@]}; i+=1 ))
do
  echo $i, ${images[$i]}
  cmd="curl -X POST http://203.145.222.39:5050/ADV_pneu --header \"Content-Type: application/json\" --data '{\"dcm\": \"${images[$i]}\"}'"
  result=`eval $cmd`

  ((total+=1))
  if [[ $result == *"\"signal\":\"0\""* ]];
  then
    ((no_pneu+=1))
  elif [[ $result == *"\"signal\":\"1\""* ]];
  then
    ((pneu+=1))
  fi
  echo "pneu = $pneu ; no_pneu = $no_pneu ; total = $total"

  if [ "$i" = "0" ]
  then
    echo $result > pneu.txt
  else
    echo $result >> pneu.txt
  fi
done


# result="{\"errcode\":\"\",\"errmessage\":\"\",\"heatmap_json_path\":\"\",\"heatmap_path\":\"/mnt/datasets/pneu/result/vis/0001-B0013801_0_0.267.png\",\"image_path\":\"/mnt/datasets/pneu/result/png/0001-B0013801.png\",\"probability\":\"0.267\",\"signal\":\"1\",\"version\":\"v3.3\"}"
