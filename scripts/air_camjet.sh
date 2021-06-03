#!/bin/bash

PIDFILE=/tmp/wfb.pid

if v4l2-ctl -D | grep "Driver name" | grep "tegra-video" 1> /dev/null 2>&1;then
  gst-launch-1.0 nvarguscamerasrc \
    ! 'video/x-raw(memory:NVMM), format=NV12, width=1280, height=720, framerate=30/1' \
    ! tee name=streams \
    ! nvv4l2h264enc insert-sps-pps=true bitrate=2000000 \
    ! h264parse  \
    ! rtph264pay name=pay0 pt=96 config-interval=1 \
    ! queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 \
    ! udpsink host=127.0.0.1 port=5700 streams. \
    ! nvivafilter cuda-process=true customer-lib-name=libnvsample_cudaprocess.so  \
    ! nvv4l2h264enc insert-sps-pps=true bitrate=2000000 \
    ! h264parse  \
    ! rtph264pay name=pay1 pt=96 config-interval=1 \
    ! queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 \
    ! udpsink host=127.0.0.1 port=5600 > /dev/null 2>&1 &
  echo $! >> $PIDFILE

#  v4l2-ctl --device /dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=RG10 --stream-mmap
#  gst-launch-1.0 nvarguscamerasrc ! 'video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1,format=(string)NV12' \
#    ! nvvidconv ! 'video/x-raw(memory:NVMM),format=(string)I420' \
#    ! omxh264enc bitrate=2000000 ! 'video/x-h264, stream-format=byte-stream' \
#    ! h264parse ! rtph264pay config-interval=10 pt=96 ! udpsink host=127.0.0.1 port=5700 > /dev/null 2>&1 &
#   ! filesink location=$(date +"%Y_%m_%d_%T").h264" > /dev/null 2>&1 &
else  
  v4l2-ctl -d /dev/video0 --set-ctrl red_balance=2000 --set-ctrl blue_balance=1700 --set-ctrl exposure=70000000
  gst-launch-1.0 v4l2src ! video/x-raw,format=BGRx ! nvvidconv flip-method=rotate-180 ! 'video/x-raw(memory:NVMM),width=800,height=600' \
    ! omxh264enc bitrate=1000000 peak-bitrate=1500000 preset-level=0 ! video/x-h264, stream-format=byte-stream \
    ! rtph264pay mtu=1400 ! udpsink host=127.0.0.1 port=5700 > /dev/null 2>&1 &
#   ! filesink location=$(date +"%Y_%m_%d_%T").h264" > /dev/null 2>&1 &
  echo $! >> $PIDFILE
fi

#SPACE=`df "$HOME" | awk 'END{print $4}'`
#while [[ `df "$HOME" | awk 'END{print $4}'`-gt 100000000 ]];do sleep 1;done &
