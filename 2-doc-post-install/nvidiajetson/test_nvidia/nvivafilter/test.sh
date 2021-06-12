#!/bin/bash

gst-launch-1.0 nvarguscamerasrc \
    ! 'video/x-raw(memory:NVMM), format=NV12, width=640, height=480, framerate=30/1' \
    ! tee name=streams \
    ! nvv4l2h264enc insert-sps-pps=true bitrate=2000000 \
    ! h264parse  \
    ! rtph264pay name=pay0 pt=96 config-interval=1 \
    ! queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 \
    ! udpsink host=192.168.3.1 port=5700 streams. \
    ! nvivafilter cuda-process=true customer-lib-name=libnvsample_cudaprocess.so \
    ! nvv4l2h264enc insert-sps-pps=true bitrate=2000000 \
    ! h264parse  \
    ! rtph264pay name=pay1 pt=96 config-interval=1 \
    ! queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 \
    ! udpsink host=192.168.3.1 port=5600
