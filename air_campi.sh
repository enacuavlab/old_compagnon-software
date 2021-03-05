#!/bin/bash

PIDFILE=/tmp/wfb.pid

#gst-launch-1.0 videotestsrc ! video/x-raw,width=1280,height=720,framerate=30/1 ! x264enc ! rtph264pay ! udpsink host=127.0.0.1 port=5700 &

#rm /tmp/fromimu
#rm /tmp/camera*
#rBITRATE_VIDEO1=1000000
#rBITRATE_VIDEO2=2000000
#r/home/pi/RaspiCV/build/raspicv -t 0 -w 640 -h 480 -fps 30/1 -b $BITRATE_VIDEO1 -vf -hf -cd H264 -n -a ENAC -ae 22 -x /dev/null -r /dev/null -rf gray -o - \
#   | gst-launch-1.0 fdsrc \
#    ! h264parse \
#    ! video/x-h264,stream-format=byte-stream,alignment=au \
#    ! rtph264pay name=pay0 pt=96 config-interval=1 \
#    ! udpsink host=127.0.0.1 port=5700 &

v4l2-ctl --device /dev/video0 \
  --set-fmt-video=width=640,height=480,pixelformat=4 \
  --set-ctrl video_bitrate=2000000 \
  --set-parm=30 \
  --set-ctrl vertical_flip=1 \
  --stream-mmap=0 --stream-to=- \
  | gst-launch-1.0 fdsrc \
    ! h264parse \
    ! video/x-h264,stream-format=byte-stream,alignment=au \
    ! rtph264pay name=pay0 pt=96 config-interval=1 \
    ! udpsink host=127.0.0.1 port=5700  > /dev/null 2>&1 &
  echo $! > $PIDFILE

 
#v4l2-ctl --device /dev/video0 --set-ctrl video_bitrate=$BITRATE_VIDEO2 
