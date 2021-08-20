#!/bin/bash

#PIDFILE=/tmp/wfb.pid
#
#if [ -f "$PIDFILE" ]; then 
#  kill `cat $PIDFILE` > /dev/null 2>&1
#  rm $PIDFILE
#fi

DEVICES=/sys/class/net/wl*
FILES=/tmp/wfb_*.pid
WLS=()

if ls $DEVICES 1> /dev/null 2>&1; then

  for i in $(ls -la $DEVICES | grep usb | awk '{print $9}');do 
    wl=`basename $i`
    ty=`iw dev $wl info | grep "type" | awk '{print $2}'`
    if [ $ty == "monitor" ]; then
      WLS+=($wl)
    fi
  done
fi

if ls $FILES 1> /dev/null 2>&1; then

  for pidfile in $FILES; do 
    toberemove=true
    for wl in ${WLS[@]};do
      if [[ "$pidfile" == "/tmp/wfb_"*"$wl".pid ]]; then
        toberemove=false 
	break
      fi
    done
    if [ $toberemove == true ]; then
      kill `cat $pidfile` > /dev/null 2>&1
      rm $pidfile
    fi
  done
fi
