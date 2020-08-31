#!/bin/bash
# https://www.cyberciti.biz/faq/unix-howto-read-line-by-line-from-file/
echo "Please input pneu log file name: (ex: 775_pneu.txt)"
read logfile

echo "Please input pneu folder name: (ex: 775_pneu)"
read pneu_folder

IFS="." read -a filename <<< $logfile
fn_png_folder="${filename[0]}_fn_png"
fn_vis_folder="${filename[0]}_fn_vis"
tp_file="${filename[0]}_tp.txt"
fn_file="${filename[0]}_fn.txt"

if [ ! -d $fn_png_folder ]
then
  mkdir $fn_png_folder
fi

if [ ! -d $fn_vis_folder ]
then
  mkdir $fn_vis_folder
fi

if [ -f $tp_file ]
then
  rm $tp_file
fi

if [ -f $fn_file ]
then
  rm $fn_file
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
    line=`echo $line | sed 's/{//g' | sed 's/}//g' | sed 's/'\"'//g'`

    IFS="," read -a elements <<< $line

    # I00291013740.png
    IFS="/" read -a element <<< ${elements[4]}
    file_png=${element[-1]}

    # I00291013740_1_0.729.png
    IFS="/" read -a element <<< ${elements[3]}
    file_vis=${element[-3]}/${element[-2]}/${element[-1]}

    # cp $pneu_folder/$file_png $fn_png_folder
    # cp $file_vis $fn_vis_folder
    echo $file_png >> $fn_file
  elif [[ $line == *"\"signal\":\"1\""* ]];
  then
    ((pneu+=1))
    line=`echo $line | sed 's/{//g' | sed 's/}//g' | sed 's/'\"'//g'`

    IFS="," read -a elements <<< $line

    # I00291013740.png
    IFS="/" read -a element <<< ${elements[4]}
    file_png=${element[-1]}

    echo $file_png >> $tp_file
  else
    ((error+=1))
  fi
  
done < "$logfile"

echo "pneu = $pneu ; no_pneu = $no_pneu ; error = $error ; total = $total"
