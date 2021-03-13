#!/bin/bash

PIDFILE=/tmp/wfb.pid

#v4l2-ctl --device /dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=RG10 --stream-mmap

gst-launch-1.0 nvarguscamerasrc ! 'video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1,format=(string)NV12' ! nvvidconv ! 'video/x-raw(memory:NVMM),format=(string)I420' \
  ! omxh264enc bitrate=2000000 ! 'video/x-h264, stream-format=byte-stream' ! h264parse ! rtph264pay config-interval=10 pt=96 ! udpsink host=127.0.0.1 port=5700 > /dev/null 2>&1 &
echo $! >> $PIDFILE
