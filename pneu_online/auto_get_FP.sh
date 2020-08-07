#!/bin/bash

echo "Please input no_pneu log file name: (ex: 775_no_pneu.txt)"
read logfile

echo "Please input no_pneu folder name: (ex: 775_no_pneu)"
read no_pneu_folder

IFS="." read -a filename <<< $logfile
fp_png_folder="${filename[0]}_fp_png"
fp_vis_folder="${filename[0]}_fp_vis"

if [ ! -d $fp_png_folder ]
then
  mkdir $fp_png_folder
fi

if [ ! -d $fp_vis_folder ]
then
  mkdir $fp_vis_folder
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

    IFS="," read -a elements <<< $line

    # I00291013740.png
    IFS="/" read -a element <<< ${elements[4]}
    file_png=${element[-1]}

    # I00291013740_1_0.729.png
    IFS="/" read -a element <<< ${elements[3]}
    file_vis=${element[-3]}/${element[-2]}/${element[-1]}

    cp $no_pneu_folder/$file_png $fp_png_folder
    cp $file_vis $fp_vis_folder
  else
    ((error+=1))
  fi
  
done < "$logfile"

echo "pneu = $pneu ; no_pneu = $no_pneu ; error = $error ; total = $total"
