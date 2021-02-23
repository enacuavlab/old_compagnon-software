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

$HOME_CMP/wfb_tx -K $HOME_CMP/drone.key -p 1 -u 5700 $WLAN_CMP &
#$HOME_CMP/wfb_tx -K $HOME_CMP/drone.key -p 2 -u 4244 -k 1 -n 2 $WLAN_CMP &
#$HOME_CMP/wfb_rx -K $HOME_CMP/drone.key -p 3 -u 4245 -c 127.0.0.1 -k 1 -n 2 $WLAN_CMP &
#$HOME_CMP/wfb_rx -K $HOME_CMP/drone.key -p 4 -u 14901 -c 127.0.0.1 -k 1 -n 2 $WLAN_CMP &
#$HOME_CMP/wfb_tx -K $HOME_CMP/drone.key -p 5 -u 14900 -k 1 -n 2 $WLAN_CMP &
#
#gst-launch-1.0 videotestsrc ! video/x-raw,width=1280,height=720,framerate=30/1 ! x264enc ! rtph264pay ! udpsink host=127.0.0.1 port=5700 &
#rm /tmp/fromimu
#rm /tmp/camera*
#BITRATE_VIDEO1=500000
#/home/pi/RaspiCV/build/raspicv -t 0 -w 640 -h 480 -fps 30/1 -b $BITRATE_VIDEO1 -vf -hf -cd H264 -n -a ENAC -ae 22 -x /dev/null -r /dev/null -rf gray -o - \
#  | gst-launch-1.0 fdsrc \
#    ! h264parse \
#    ! video/x-h264,stream-format=byte-stream,alignment=au \
#    ! rtph264pay name=pay0 pt=96 config-interval=1 \
#    ! udpsink host=127.0.0.1 port=5700 &

v4l2-ctl --device /dev/video0 --set-fmt-video=width=640,height=480,pixelformat=4 
v4l2-ctl --device /dev/video0 --set-ctrl video_bitrate=1000000
v4l2-ctl --device /dev/video0 --set-parm=30 
v4l2-ctl --device /dev/video0 --stream-mmap=0 --stream-to=- \
  | gst-launch-1.0 fdsrc \
    ! h264parse \
    ! video/x-h264,stream-format=byte-stream,alignment=au \
    ! rtph264pay name=pay0 pt=96 config-interval=1 \
    ! udpsink host=127.0.0.1 port=5700 &

#v4l2-ctl –stream-mmap=0 –stream-to=- | sudo ./tx -b 8 -r 4 -f 1024 wlan0

#
#socat -u /dev/ttyAMA0,raw,echo=0,b115200 udp-sendto:127.0.0.1:4244 > /dev/null 2>&1 &
#socat -u udp-listen:4245,reuseaddr,fork /dev/ttyAMA0,raw,echo=0,b115200 &
#
#socat TUN:10.0.1.2/24,tun-name=airtuntx,iff-no-pi,tun-type=tun,iff-up udp-sendto:127.0.0.1:14900 &
#socat udp-listen:14901,reuseaddr,fork TUN:10.0.1.2/24,tun-name=airtunrx,iff-no-pi,tun-type=tun,iff-up &
#sleep 1
#ifconfig airtuntx mtu 1400 up &
