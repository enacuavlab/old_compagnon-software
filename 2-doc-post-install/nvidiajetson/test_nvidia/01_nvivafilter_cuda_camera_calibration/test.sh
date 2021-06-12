#!/bin/bash

export CAM_WIDTH="1280"
export CAM_HEIGHT="720"
export CAM_MAT="8.9712590160498451e+02 0. 5.9290793586019208e+02 0. 8.7139246526095974e+02 3.5323728389070351e+02 0. 0. 1."
export CAM_DIS="1.6729349667635585e-01 -1.8283939851950195e+00 -3.8236989961622351e-03 -1.7858415775001007e-02"
#export CAM_DIS="1.6729349667635585e-01 -1.8283939851950195e+00 -3.8236989961622351e-03 -1.7858415775001007e-02 3.9122153603756376e+00"
#export CAM_DIS="0. 0. 0. 0."

#export CAM_WIDTH="640"
#export CAM_HEIGHT="480"
#export CAM_MAT="528.53618582196384 0.0 314.01736116032430 0.0 532.01912214324500 231.43930864205211 0.0 0.0 1.0"
#export CAM_DIS="-0.11839989180635836 0.25425420873955445 0.0013269901775205413 0.0015787467748277866"

gst-launch-1.0 nvarguscamerasrc \
    ! 'video/x-raw(memory:NVMM)', format=NV12, width=$CAM_WIDTH, height=$CAM_HEIGHT, framerate=30/1 \
    ! tee name=streams \
    ! nvv4l2h264enc insert-sps-pps=true bitrate=2000000 \
    ! h264parse  \
    ! rtph264pay name=pay0 pt=96 config-interval=1 \
    ! queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 \
    ! udpsink host=192.168.3.1 port=5700 streams. \
    ! nvivafilter cuda-process=true customer-lib-name=lib-gst-custom-opencv_cudaprocess.so \
    ! 'video/x-raw(memory:NVMM), format=RGBA' \
    ! nvvidconv \
    ! nvv4l2h264enc insert-sps-pps=true bitrate=2000000 \
    ! h264parse  \
    ! rtph264pay name=pay1 pt=96 config-interval=1 \
    ! queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 \
    ! udpsink host=192.168.3.1 port=5600
