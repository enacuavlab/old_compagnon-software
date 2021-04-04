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
    $HOME_PRJ/scripts/wfb_off.sh

    if uname -a | grep -cs "4.9.201-tegra"> /dev/null 2>&1;then
      systemctl stop wpa_supplicant.service;systemctl stop NetworkManager.service;fi

    ifconfig $wl down
    iw dev $wl set monitor otherbss
    iw reg set DE
    ifconfig $wl up
    iw dev $wl set channel 40

    if uname -a | grep -cs "4.9.201-tegra"> /dev/null 2>&1;then
      systemctl start NetworkManager.service;systemctl start wpa_supplicant.service;fi

    #iw dev $wl set txpower fixed 4000
    #iw $wl info

    #$HOME_PRJ/scripts/air.sh $wl
    $HOME_PRJ/scripts/ground.sh $wl  

  fi
fi
