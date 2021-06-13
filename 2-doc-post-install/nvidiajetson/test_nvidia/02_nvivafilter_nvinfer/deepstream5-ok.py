#!/usr/bin/env python3

import sys
sys.path.append('/opt/nvidia/deepstream/deepstream/sources/deepstream_python_apps/apps')

import gi
gi.require_version('Gst', '1.0')
from gi.repository import GObject, Gst
from common.is_aarch_64 import is_aarch64

import pyds

INFERCONF="/home/pprz/test_nvidia/02_nvivafilter_nvinfer/deepstream-rtsp.cfg" 
WIDTH=1280
HEIGHT=720
FPS=30
#IP="192.168.3.1"
IP="127.0.0.1"
PORT1=5600
PORT2=5700
BITRATE1=2000000
BITRATE2=2000000


PGIE_CLASS_ID_VEHICLE = 0
PGIE_CLASS_ID_BICYCLE = 1
PGIE_CLASS_ID_PERSON = 2
PGIE_CLASS_ID_ROADSIGN = 3

def osd_sink_pad_buffer_probe(pad,info,u_data):
  frame_number=0
  obj_counter = {
    PGIE_CLASS_ID_VEHICLE:0,
    PGIE_CLASS_ID_PERSON:0,
    PGIE_CLASS_ID_BICYCLE:0,
    PGIE_CLASS_ID_ROADSIGN:0
  }
  num_rects=0

  gst_buffer = info.get_buffer()
  if not gst_buffer:
    print("Unable to get GstBuffer ")
    return

  batch_meta = pyds.gst_buffer_get_nvds_batch_meta(hash(gst_buffer))
  l_frame = batch_meta.frame_meta_list
  while l_frame is not None:
    try:
      frame_meta = pyds.NvDsFrameMeta.cast(l_frame.data)
    except StopIteration:
      break

    frame_number=frame_meta.frame_num
    num_rects = frame_meta.num_obj_meta
    l_obj=frame_meta.obj_meta_list
    while l_obj is not None:
      try:
        obj_meta=pyds.NvDsObjectMeta.cast(l_obj.data)
      except StopIteration:
        break
      obj_counter[obj_meta.class_id] += 1
      try: 
        l_obj=l_obj.next
      except StopIteration:
        break

    display_meta=pyds.nvds_acquire_display_meta_from_pool(batch_meta)
    display_meta.num_labels = 1
    py_nvosd_text_params = display_meta.text_params[0]
    py_nvosd_text_params.display_text = "Frame Number={} Number of Objects={} Vehicle_count={} Person_count={}".format(frame_number, num_rects, obj_counter[PGIE_CLASS_ID_VEHICLE], obj_counter[PGIE_CLASS_ID_PERSON])
    py_nvosd_text_params.x_offset = 10
    py_nvosd_text_params.y_offset = 12
    py_nvosd_text_params.font_params.font_name = "Serif"
    py_nvosd_text_params.font_params.font_size = 10
    py_nvosd_text_params.font_params.font_color.set(1.0, 1.0, 1.0, 1.0)
    py_nvosd_text_params.set_bg_clr = 1
    py_nvosd_text_params.text_bg_clr.set(0.0, 0.0, 0.0, 1.0)
    print(pyds.get_string(py_nvosd_text_params.display_text))
    pyds.nvds_add_display_meta_to_frame(frame_meta, display_meta)
    try:
      l_frame=l_frame.next
    except StopIteration:
      break
			
  return Gst.PadProbeReturn.OK	


if __name__ == '__main__':
  GObject.threads_init()
  Gst.init(None)

  pipeline = Gst.parse_launch("nvarguscamerasrc bufapi-version=1  \
    ! tee name=streams \
    ! queue \
    ! nvv4l2h264enc insert-sps-pps=true bitrate="+str(BITRATE1)+" \
    ! h264parse  \
    ! rtph264pay \
    ! udpsink host="+str(IP)+" port="+str(PORT1)+" streams. \
    ! queue \
    ! video/x-raw(memory:NVMM),width="+str(WIDTH)+",height="+str(HEIGHT)+",framerate="+str(FPS)+"/1 \
    ! mx.sink_0 nvstreammux width="+str(WIDTH)+" height="+str(HEIGHT)+" batch-size=1  batched-push-timeout=4000000  name=mx \
    ! nvinfer config-file-path="+str(INFERCONF)+" \
    ! nvvideoconvert \
    ! nvdsosd name=osd \
    ! nvvideoconvert \
    ! video/x-raw(memory:NVMM), format=I420 \
    ! nvv4l2h264enc bitrate="+str(BITRATE2)+" preset-level=1 insert-sps-pps=1 bufapi-version=1 \
    ! rtph264pay \
    ! udpsink host="+str(IP)+" port="+str(PORT2)+" async=False sync=1")

  pipeline.get_by_name("osd").get_static_pad("sink").add_probe(Gst.PadProbeType.BUFFER, osd_sink_pad_buffer_probe, 0)
   
  loop = GObject.MainLoop()
  pipeline.set_state(Gst.State.PLAYING)
  try:
    loop.run()
  except:
    pass
  pipeline.set_state(Gst.State.NULL)
