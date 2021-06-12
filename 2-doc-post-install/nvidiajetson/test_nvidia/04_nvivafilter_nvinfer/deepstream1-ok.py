#!/usr/bin/env python3

import gi
gi.require_version('Gst', '1.0')
from gi.repository import GObject, Gst

import sys
sys.path.append('/opt/nvidia/deepstream/deepstream/sources/deepstream_python_apps/apps')

'''
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
'''

if __name__ == '__main__':

  GObject.threads_init()
  Gst.init(None)

  pipeline = Gst.Pipeline()
  source = Gst.ElementFactory.make("nvarguscamerasrc", "nv-arguscamerasrc")
  pipeline.add(source)
  caps_nvargussrc = Gst.ElementFactory.make("capsfilter", "nvargussrc_caps")
  caps_nvargussrc.set_property('caps', Gst.Caps.from_string("video/x-raw(memory:NVMM),format=NV12,width=1280,height=720,framerate=30/1"))  
  pipeline.add(caps_nvargussrc)
  source.link(caps_nvargussrc)

  encoder = Gst.ElementFactory.make("nvv4l2h264enc", "encoder")
  encoder.set_property('bitrate',2000000)
  pipeline.add(encoder)
  caps_nvargussrc.link(encoder)

  h264parser = Gst.ElementFactory.make("h264parse", "h264-parser")
  pipeline.add(h264parser)
  encoder.link(h264parser)
  rtppay = Gst.ElementFactory.make("rtph264pay", "rtppay")
  rtppay.set_property('pt', 96)
  rtppay.set_property('config-interval', 1)
  pipeline.add(rtppay)
  h264parser.link(rtppay)
  sink = Gst.ElementFactory.make("udpsink", "udpsink")
  sink.set_property('host', "192.168.3.1")
  sink.set_property('port', 5600)
  pipeline.add(sink)
  rtppay.link(sink)

  loop = GObject.MainLoop()
  pipeline.set_state(Gst.State.PLAYING)

  try:
    loop.run()
  except:
     sys.stderr.write("\n\n\n*** ERROR: main event loop exited!\n\n\n")

  pipeline.set_state(Gst.State.NULL)
