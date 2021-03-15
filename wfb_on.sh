#!/bin/bash

HOME_PRJ=/home/pprz/Projects/compagnon-software
DEVICE=/sys/class/net/wl*

if ls $DEVICE 1> /dev/null 2>&1; then
  lo=`ls -la $DEVICE | grep usb | awk '{print $9}'`
  if [ ! -z $lo ];then
    wl=`basename $lo`
    ph=`iw dev $wl info | grep wiphy | awk '{print "phy"$2}'`
    nb=`rfkill --raw | grep $ph | awk '{print $1}'`
    st=`rfkill --raw | grep $ph | awk '{print $4}'`
    if [ $st == "blocked" ];then `rfkill unblock $nb`;fi
    $HOME_PRJ/wfb_off.sh

    ifconfig $wl down
    iw dev $wl set monitor otherbss 
    iw reg set DE 
    ifconfig $wl up
    iw dev $wl set channel 40

    #iw dev $wl set txpower fixed 4000
    #iw $wl info

    #$HOME_PRJ/air.sh $wl
    $HOME_PRJ/ground.sh $wl  
  fi
fi
