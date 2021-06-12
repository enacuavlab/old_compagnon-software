#!/usr/bin/env python3

import gi
gi.require_version('Gst', '1.0')
gi.require_version('GstApp', '1.0')
gi.require_version("GstVideo", "1.0")
from gi.repository import GObject, Gst, GstApp, GstVideo

import typing as typ

#def on_message(bus, message):
#  print(message)
#  t = message.type
#  if t == Gst.MessageType.EOS:
#    print('Received message type EOS')
#    self.player.set_state(Gst.State.NULL)
#  elif t == Gst.MessageType.ERROR:
#    err, debug = message.parse_error()
#    print("Error: %s" % err, debug)
#    self.player.set_state(Gst.State.NULL)

def on_buffer(sink: GstApp.AppSink, data: typ.Any) -> Gst.FlowReturn:
  sample = sink.emit("pull-sample")
  buffer = sample.get_buffer()
  caps_format = sample.get_caps().get_structure(0)
  frmt_str = caps_format.get_value('format')
  video_format = GstVideo.VideoFormat.from_string(frmt_str)
  w, h = caps_format.get_value('width'), caps_format.get_value('height')
  print(video_format)
  info = GstVideo.VideoFormat.get_info(video_format)
  print(info.n_planes)
#  c = Gst.utils.get_num_channels(video_format)
#  c = utils.get_num_channels(video_format)
#  array = np.ndarray(shape=(h, w, c), \
#    buffer=buffer.extract_dup(0, buffer.get_size()), \
#    dtype=utils.get_np_dtype(video_format))
#  array = np.squeeze(array)  # convert to grayscale 
  return Gst.FlowReturn.OK


if __name__ == "__main__":
  GObject.threads_init()
  Gst.init(None)
  loop = GObject.MainLoop()
  
  gst_str = "nvarguscamerasrc \
      ! video/x-raw(memory:NVMM),format=(string)NV12,width=(int)640,height=(int)480 \
      ! tee name=stream \
      ! queue \
      ! nvvidconv \
      ! nvv4l2h264enc bitrate=2000000 \
      ! h264parse  \
      ! rtph264pay name=pay0 pt=96 config-interval=1 \
      ! udpsink host=192.168.3.1 port=5700 stream. \
      ! queue \
      ! nvvidconv \
      ! video/x-raw,format=RGBA \
      ! appsink name=sink emit-signals=True"
  player = Gst.parse_launch (gst_str)

  appsink=player.get_by_name("sink")
  appsink.connect("new-sample", on_buffer, None)

  player.set_state(Gst.State.PLAYING)

#  bus = player.get_bus()
#  bus.add_signal_watch()
#  bus.enable_sync_message_emission()
#  bus.connect("message", on_message)
  
  player.set_state(Gst.State.PLAYING)
  try:
    loop.run()
  except:
    pass
  player.set_state(Gst.State.NULL)
