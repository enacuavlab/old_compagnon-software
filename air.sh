#!/bin/bash

HOME_WFB=/home/pprz/Projects/compagnon-software/wifibroadcast
PIDFILE=/tmp/wfb.pid

if [ -n "$1" ]; then

  wl=$1

  $HOME_WFB/wfb_tx -K $HOME_WFB/drone.key -p 1 -u 5700 $wl > /dev/null 2>&1 &
  echo $! > $PIDFILE
#  $HOME_WFB/wfb_tx -K $HOME_WFB/drone.key -p 2 -u 4244 -k 1 -n 2 $wl > /dev/null 2>&1 &
#  echo $! >> $PIDFILE
#  $HOME_WFB/wfb_rx -K $HOME_WFB/drone.key -p 3 -u 4245 -c 127.0.0.1 -k 1 -n 2 $wl > /dev/null 2>&1 &
#  echo $! >> $PIDFILE
#  $HOME_WFB/wfb_rx -K $HOME_WFB/drone.key -p 4 -u 14901 -c 127.0.0.1 -k 1 -n 2 $wl > /dev/null 2>&1 &
#  echo $! >> $PIDFILE
#  $HOME_WFB/wfb_tx -K $HOME_WFB/drone.key -p 5 -u 14900 -k 1 -n 2 $wl > /dev/null 2>&1 &
#  echo $! >> $PIDFILE
#
#gst-launch-1.0 videotestsrc ! video/x-raw,width=1280,height=720,framerate=30/1 ! x264enc ! rtph264pay ! udpsink host=127.0.0.1 port=5700 &
#rm /tmp/fromimu
#rm /tmp/camera*
#BITRATE_VIDEO1=1000000
#BITRATE_VIDEO2=2000000
#/home/pi/RaspiCV/build/raspicv -t 0 -w 640 -h 480 -fps 30/1 -b $BITRATE_VIDEO1 -vf -hf -cd H264 -n -a ENAC -ae 22 -x /dev/null -r /dev/null -rf gray -o - \
#  | gst-launch-1.0 fdsrc \
#    ! h264parse \
#    ! video/x-h264,stream-format=byte-stream,alignment=au \
#    ! rtph264pay name=pay0 pt=96 config-interval=1 \
#    ! udpsink host=127.0.0.1 port=5700 &

#RaspberryPI
#v4l2-ctl --device /dev/video0 \
#  --set-fmt-video=width=640,height=480,pixelformat=4 \
#  --set-ctrl video_bitrate=2000000 \
#  --set-parm=30 \
#  --set-ctrl vertical_flip=1 \
#  --stream-mmap=0 --stream-to=- \
#  | gst-launch-1.0 fdsrc \
#    ! h264parse \
#    ! video/x-h264,stream-format=byte-stream,alignment=au \
#    ! rtph264pay name=pay0 pt=96 config-interval=1 \
#    ! udpsink host=127.0.0.1 port=5700 &
 
#v4l2-ctl --device /dev/video0 --set-ctrl video_bitrate=$BITRATE_VIDEO2 

#XavierNX
#v4l2-ctl --device /dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=RG10 --stream-mmap

  gst-launch-1.0 nvarguscamerasrc ! 'video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1,format=(string)NV12' ! nvvidconv ! 'video/x-raw(memory:NVMM),format=(string)I420' \
    ! omxh264enc bitrate=2000000 ! 'video/x-h264, stream-format=byte-stream' ! h264parse ! rtph264pay config-interval=10 pt=96 ! udpsink host=127.0.0.1 port=5700 > /dev/null 2>&1 &
  echo $! >> $PIDFILE

#  gst-launch-1.0 v4l2src do-timestamp=true ! "video/x-raw,format=I420, width=1920, height=1080, framerate=60/1" ! omxh264enc insert-sps-pps=true bitrate=16000000 ! rtph264pay ! udpsink host=127.0.0.1 port=5700 sync=true > /dev/null 2>&1 &
#  echo $! > /tmp/wfb.pid

#  socat -u /dev/ttyAMA0,raw,echo=0,b115200 udp-sendto:127.0.0.1:4244 > /dev/null 2>&1 &
#  echo $! > /tmp/wfb.pid
#  socat -u udp-listen:4245,reuseaddr,fork /dev/ttyAMA0,raw,echo=0,b115200 > /dev/null 2>&1 &
#  echo $! > $PIDFILE
#
#  socat TUN:10.0.1.2/24,tun-name=airtuntx,iff-no-pi,tun-type=tun,iff-up udp-sendto:127.0.0.1:14900 > /dev/null 2>&1 &
#  echo $! > /tmp/wfb.pid
#  socat udp-listen:14901,reuseaddr,fork TUN:10.0.1.2/24,tun-name=airtunrx,iff-no-pi,tun-type=tun,iff-up > /dev/null 2>&1 &
#  echo $! > $PIDFILE
#  sleep 1
#  ifconfig airtuntx mtu 1400 up &

fi
