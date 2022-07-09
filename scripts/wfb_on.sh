#!/bin/bash

HOME_PRJ=compagnonsoftwarepath

DEVICES=/sys/class/net/wl*
FILES=/tmp/wfb_*.pid

CHANNELS=(36 40 44 48)
WLS=()


if ls $DEVICES 1> /dev/null 2>&1; then

  if uname -a | grep -c "4.9.*tegra"> /dev/null 2>&1;then TEGRA=true;
  else TEGRA=false;fi;

  for i in $(ls -la $DEVICES | grep usb | awk '{print $9}');do
    wl=`basename $i`
    if $TEGRA;then
      ty=`iwconfig $wl | grep -c "Mode:Managed"`
      if [ $ty == '1' ];then WLS+=($wl);fi
    else
      ty=`iw dev $wl info | grep "type" | awk '{print $2}'`
      if [[ $ty = "managed" ]]; then
        WLS+=($wl)
      fi
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

    # AIRBORNE
    # Choose (uncomment) bypass id for air.sh
    #id=0
    #id=1
    #id=2

    if [ $id -ge 0 ]; then
	
      ph=`iw dev $wl info | grep wiphy | awk '{print "phy"$2}'`
      nb=`rfkill --raw | grep $ph | awk '{print $1}'`
      st=`rfkill --raw | grep $ph | awk '{print $4}'`
      if [ $st == "blocked" ];then `rfkill unblock $nb`;fi
  
      if $TEGRA;then
        systemctl stop wpa_supplicant.service
        systemctl stop NetworkManager.service
        ifconfig $wl down
        ifconfig $wl up
        iwconfig $wl mode monitor
        iw reg set DE
        iwconfig $wl channel ${CHANNELS[$id]}
      else
        ifconfig $wl down
        iw dev $wl set monitor otherbss
        iw reg set DE
        ifconfig $wl up
        iw dev $wl set channel ${CHANNELS[$id]}
      fi

      PIDFILE=/tmp/wfb_${id}_${wl}.pid
      touch $PIDFILE
      $HOME_PRJ/patched/ground.sh $wl $id  > /dev/null 2>&1 &
      #$HOME_PRJ/patched/air.sh $wl $id  > /dev/null 2>&1 &
      echo $! > $PIDFILE

    fi
  done
fi

$HOME_PRJ/scripts/wfb_off.sh
