#!/bin/bash
# https://www.cyberciti.biz/faq/unix-howto-read-line-by-line-from-file/
echo "Please input log file name: (ex: 775_pneu.txt or 775_no_pneu.txt)"
read logfile
echo "Please input actual label: (ex: Y or N)"
read actual

IFS="." read -a filename <<< $logfile
csv_file="${filename[0]}.csv"

echo "Actual,Image Name,Signal,Probability,Version" > $csv_file
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
  else
    ((error+=1))
  fi

  line=`echo $line | sed 's/{//g' | sed 's/}//g' | sed 's/'\"'//g'`

  IFS="," read -a elements <<< $line
  image_path=${elements[4]}
  probability=${elements[5]}
  signal=${elements[6]}
  version=${elements[7]}

  IFS="/" read -a image_path_el <<< ${image_path}
  image_name=${image_path_el[6]}

  IFS=":" read -a prob_el <<< ${probability}
  probability=${prob_el[1]}

  IFS=":" read -a signal_el <<< ${signal}
  if [ "${signal_el[1]}" = "0" ]
  then
    signal="N"
  elif [ "${signal_el[1]}" = "1" ]
  then
    signal="Y"
  fi

  IFS=":" read -a version_el <<< ${version}
  version=${version_el[1]}

  echo "$actual,$image_name,$signal,$probability,$version" >> $csv_file
done < "$logfile"

echo "pneu = $pneu ; no_pneu = $no_pneu ; error = $error ; total = $total"
