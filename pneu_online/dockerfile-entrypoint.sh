#!/bin/sh

'/home/webService/out/run_service.bin' &
PID=`echo $!`
STOP_WHILE=0

while true
do
   trap "kill -9 $PID; STOP_WHILE=1" INT
   if [ "$STOP_WHILE" = "1" ]
   then
     kill -9 $PID
     break
   fi

   pro=$(ps -ef | awk '{print $2}' | grep "$PID")

   echo $PID $pro

   if [ "$pro" = "$PID" ]
   then
     echo "$PID is running"
   else
     echo "$PID is stopped"
     sleep 5
     '/home/webService/out/run_service.bin' &
     PID=`echo $!`
   fi

   sleep 2
done

wait
