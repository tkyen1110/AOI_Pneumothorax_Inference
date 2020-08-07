#!/bin/bash

echo "Please input no_pneu log file name:"
read logfile

echo "Please input no_pneu folder name:"
read no_pneu_folder

IFS="." read -a filename <<< $logfile
fp_folder="${filename[0]}_fp"
if [ ! -d $fp_folder ]
then
  mkdir $fp_folder
fi

total=0
pneu=0
no_pneu=0
error=0

while IFS= read -r line
do
  ((total+=1))
  if [[ $line == *"\"signal\":\"0\""* ]];
  then
    ((no_pneu+=1))
  elif [[ $line == *"\"signal\":\"1\""* ]];
  then
    ((pneu+=1))
    line=`echo $line | sed 's/{//g' | sed 's/}//g' | sed 's/'\"'//g'`
    IFS="," read -a element <<< $line
    IFS="/" read -a element <<< ${element[3]}
    IFS="_" read -a element <<< ${element[-1]}
    file="${element[0]}.png"
    cp $no_pneu_folder/$file $fp_folder
  else
    ((error+=1))
  fi
  
done < "$logfile"

echo "pneu = $pneu ; no_pneu = $no_pneu ; error = $error ; total = $total"
