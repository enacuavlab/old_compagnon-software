#!/bin/bash

HOME_PRJ=/home/pprz/Projects/compagnon-software

DEVICES=/sys/class/net/wl*
FILES=/tmp/wfb_*.pid

CHANNELS=(36 40 44 48)
WLS=()
AIR_CHAN_ID=0


if ls $DEVICES 1> /dev/null 2>&1; then

  for i in $(ls -la $DEVICES | grep usb | awk '{print $9}');do 
    wl=`basename $i`
    ty=`iw dev $wl info | grep "type" | awk '{print $2}'`
    if [[ $ty = "managed" ]]; then
      WLS+=($wl)
    fi
  done

  id=-1
  for wl in ${WLS[@]};do
    for index in ${!CHANNELS[@]}; do
      if ! ls /tmp/wfb_${index}_*.pid 1> /dev/null 2>&1; then
        id=$index
        break
      fi
    done
   
    if [ $id -ge 0 ]; then
	
      ph=`iw dev $wl info | grep wiphy | awk '{print "phy"$2}'`
      nb=`rfkill --raw | grep $ph | awk '{print $1}'`
      st=`rfkill --raw | grep $ph | awk '{print $4}'`
      if [ $st == "blocked" ];then `rfkill unblock $nb`;fi
  
      if uname -a | grep -cs "4.9.201-tegra"> /dev/null 2>&1;then
        systemctl stop wpa_supplicant.service;systemctl stop NetworkManager.service;fi
  
      ifconfig $wl down
      iw dev $wl set monitor otherbss
      iw reg set DE
      ifconfig $wl up
      iw dev $wl set channel ${CHANNELS[$id]}

      PIDFILE=/tmp/wfb_${id}_${wl}.pid
      touch $PIDFILE
      $HOME_PRJ/scripts/ground.sh $wl $id  > /dev/null 2>&1 &
      #$HOME_PRJ/scripts/air.sh $wl $AIR_CHAN_ID  > /dev/null 2>&1 &
      echo $! > $PIDFILE

    fi
  done
fi

$HOME_PRJ/scripts/wfb_off.sh
