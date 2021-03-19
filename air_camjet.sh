#!/bin/bash

PIDFILE=/tmp/wfb.pid

#v4l2-ctl --device /dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=RG10 --stream-mmap

#gst-launch-1.0 nvarguscamerasrc ! 'video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1,format=(string)NV12' ! nvvidconv ! 'video/x-raw(memory:NVMM),format=(string)I420' \
#  ! omxh264enc bitrate=2000000 ! 'video/x-h264, stream-format=byte-stream' ! h264parse ! rtph264pay config-interval=10 pt=96 ! udpsink host=127.0.0.1 port=5700 > /dev/null 2>&1 &

gst-launch-1.0 v4l2src ! video/x-raw,format=BGRx ! nvvidconv flip-method=rotate-180 ! 'video/x-raw(memory:NVMM),width=800,height=600' ! omxh264enc bitrate=1000000 peak-bitrate=1500000 preset-level=0 ! video/x-h264, stream-format=byte-stream ! rtph264pay mtu=1400 ! udpsink host=192.168.3.1 port=5700 > /dev/null 2>&1 &œ
echo $! >> $PIDFILE
