#!/bin/bash
HOME_CMP=/home/pi/wifibroadcast-svpcom
WLAN_CMP=wlan1
ifconfig $WLAN_CMP down 
sleep 1
iw dev $WLAN_CMP set monitor otherbss 
iw reg set DE 
ifconfig $WLAN_CMP up 
iw dev $WLAN_CMP set channel 40
#iw dev $WLAN_CMP set txpower fixed 4000
#iw $WLAN_CMP info

#$HOME_CMP/wfb_rx -K $HOME_CMP/drone.key -p 1 -u 5600 -c 127.0.0.1 $WLAN_CMP &
#$HOME_CMP/wfb_rx -K $HOME_CMP/drone.key -p 2 -u 4242 -c $GCS_IP -k 1 -n 2 $WLAN_CMP &
#$HOME_CMP/wfb_tx -K $HOME_CMP/drone.key -p 3 -u 4243 -k 1 -n 2 $WLAN_CMP &

#$HOME_CMP/wfb_tx -K $HOME_CMP/drone.key -p 4 -u 14800 -k 1 -n 2 $WLAN_CMP &
#$HOME_CMP/wfb_rx -K $HOME_CMP/drone.key -p 5 -u 14801 -c 127.0.0.1 -k 1 -n 2 $WLAN_CMP &
#
#gst-launch-1.0 udpsrc port=5600 ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink &

#socat TUN:10.0.1.1/24,tun-name=groundtuntx,iff-no-pi,tun-type=tun,iff-up udp-sendto:127.0.0.1:14800 &
#socat udp-listen:14801,reuseaddr,fork TUN:10.0.1.1/24,tun-name=groundtunrx,iff-no-pi,tun-type=tun,iff-up &
#sleep 1
#ifconfig groundtuntx mtu 1400 up &
