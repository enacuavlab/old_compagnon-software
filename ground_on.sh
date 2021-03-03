#!/bin/bash

# example (prelimanary add PermitRootLogin in sshd_config and ssh-copy-id -i root@groundpi_112)
#  /usr/bin/ssh  root@groundpi_112 "/home/pi/groundpi.sh 192.168.1.236 > /dev/null 2>&1 &"
if [ -z "$1" ];then GCS_IP="127.0.0.1";else GCS_IP=$1;fi

HOME_CMP=/home/pprz/Projects/compagnon-software/wifibroadcast

lo=`ls -la /sys/class/net/wl* | grep usb | awk '{print $9}'`
if [ ! -z "$lo" ];then 
  wl=`basename $lo`
  ph=`iw dev $wl info | grep wiphy | awk '{print "phy"$2}'`
  nb=`rfkill --raw | grep $ph | awk '{print $1}'`
  st=`rfkill --raw | grep $ph | awk '{print $4}'`
  if [ $st == "blocked" ];then `rfkill unblock $nb`;fi
 
  WLAN_CMP=$wl
  
  ifconfig $WLAN_CMP down 
  iw dev $WLAN_CMP set monitor otherbss 
  iw reg set DE 
  ifconfig $WLAN_CMP up 
  iw dev $WLAN_CMP set channel 40
  ##iw dev $WLAN_CMP set txpower fixed 4000
  ##iw $WLAN_CMP info
  
#  $HOME_CMP/wfb_rx -K $HOME_CMP/drone.key -p 1 -u 5600 -c 127.0.0.1 $WLAN_CMP > /dev/null 2>&1 &
#  echo $! > /tmp/ground.pid
#  $HOME_CMP/wfb_rx -K $HOME_CMP/drone.key -p 2 -u 4242 -c $GCS_IP -k 1 -n 2 $WLAN_CMP > /dev/null 2>&1 & 
#  echo $! >> /tmp/ground.pid
#  $HOME_CMP/wfb_tx -K $HOME_CMP/drone.key -p 3 -u 4243 -k 1 -n 2 $WLAN_CMP > /dev/null 2>&1 & 
#  echo $! >> /tmp/ground.pid

  $HOME_CMP/wfb_tx -K $HOME_CMP/drone.key -p 4 -u 14800 -k 1 -n 2 $WLAN_CMP &
  echo $! > /tmp/ground.pid
  $HOME_CMP/wfb_rx -K $HOME_CMP/drone.key -p 5 -u 14801 -c 127.0.0.1 -k 1 -n 2 $WLAN_CMP &
  echo $! > /tmp/ground.pid
  #
  #gst-launch-1.0 udpsrc port=5600 ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink &
  #
  socat TUN:10.0.1.1/24,tun-name=groundtuntx,iff-no-pi,tun-type=tun,iff-up udp-sendto:127.0.0.1:14800 &
  echo $! > /tmp/ground.pid
  socat udp-listen:14801,reuseaddr,fork TUN:10.0.1.1/24,tun-name=groundtunrx,iff-no-pi,tun-type=tun,iff-up &
#  socat udp-listen:14801,bind=10.0.1.1 TUN:10.0.1.1/24,tun-name=groundtunrx,iff-no-pi,tun-type=tun,iff-up &
  echo $! > /tmp/ground.pid
  sleep 1
  ifconfig groundtuntx mtu 1400 up &
fi
