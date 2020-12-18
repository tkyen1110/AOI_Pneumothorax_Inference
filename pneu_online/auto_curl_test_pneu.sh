#!/bin/bash

echo "Please input log file name:"
read logfile

ls_result=`ls dicom`
ls_result=$(echo ${ls_result})
IFS=" " read -a images <<< $ls_result

total=0
pneu=0
no_pneu=0
error=0

echo "Total ${#images[@]} images"
for (( i=0; i<${#images[@]}; i+=1 ))
do
  # if [[ $i -ge 0 && $i -le 999 ]];
  # then
  #   echo $i, ${images[$i]}
  # else
  #   continue
  # fi
  echo $i, ${images[$i]}
  cmd="curl -X POST http://203.145.222.39:8080/ADV_pneu --header \"Content-Type: application/json\" --data '{\"dcm\": \"${images[$i]}\"}'"
  # cmd="curl -X POST http://localhost:8080/ADV_pneu --header \"Content-Type: application/json\" --data '{\"dcm\": \"${images[$i]}\"}'"
  result=`eval $cmd`

  ((total+=1))
  if [[ $result == *"\"signal\":\"0\""* ]];
  then
    ((no_pneu+=1))
  elif [[ $result == *"\"signal\":\"1\""* ]];
  then
    ((pneu+=1))
  else
    ((error+=1))
  fi

  echo "pneu = $pneu ; no_pneu = $no_pneu ; error = $error ; total = $total"

  if [ "$i" = "0" ]
  then
    if [ "$result" = "{}" ]
    then
      echo $i, ${images[$i]} > $logfile
    else
      echo $result > $logfile
    fi
  else
    if [ "$result" = "{}" ]
    then
      echo $i, ${images[$i]} >> $logfile
    else
      echo $result >> $logfile
    fi
  fi
done

echo "pneu = $pneu ; no_pneu = $no_pneu ; error = $error ; total = $total"

# result="{\"errcode\":\"\",\"errmessage\":\"\",\"heatmap_json_path\":\"\",\"heatmap_path\":\"/mnt/datasets/pneu/result/vis/0001-B0013801_0_0.267.png\",\"image_path\":\"/mnt/datasets/pneu/result/png/0001-B0013801.png\",\"probability\":\"0.267\",\"signal\":\"1\",\"version\":\"v3.3\"}"
