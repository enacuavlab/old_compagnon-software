#!/usr/bin/env python3

import sys
sys.path.append('/opt/nvidia/deepstream/deepstream/sources/deepstream_python_apps/apps')

import gi
gi.require_version('Gst', '1.0')
from gi.repository import GObject, Gst
from common.is_aarch_64 import is_aarch64

import pyds

WIDTH=1280
HEIGHT=720
FPS=30

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

    pipeline = Gst.Pipeline()
    
    source = Gst.ElementFactory.make("nvarguscamerasrc", "nv-arguscamerasrc")
    source.set_property('bufapi-version', 1)
    pipeline.add(source)

    caps_nvargussrc = Gst.ElementFactory.make("capsfilter", "nvargussrc_caps")
    caps_nvargussrc.set_property('caps', Gst.Caps.from_string("video/x-raw(memory:NVMM),width="+str(WIDTH)+",height="+str(HEIGHT)+",framerate="+str(FPS)+"/1"))  
    srcpad = caps_nvargussrc.get_static_pad("src")
    pipeline.add(caps_nvargussrc)
    source.link(caps_nvargussrc)

    streammux = Gst.ElementFactory.make("nvstreammux", "Stream-muxer")
    streammux.set_property('width', WIDTH)
    streammux.set_property('height', HEIGHT)
    streammux.set_property('batch-size', 1)
    streammux.set_property('batched-push-timeout', 4000000)
    sinkpad = streammux.get_request_pad("sink_0")
    pipeline.add(streammux)
    srcpad.link(sinkpad)
    
    pgie = Gst.ElementFactory.make("nvinfer", "primary-inference")
    pgie.set_property('config-file-path', "deepstream-rtsp.cfg")
    pipeline.add(pgie)
    streammux.link(pgie)
    
    nvvidconv = Gst.ElementFactory.make("nvvideoconvert", "convertor")
    pipeline.add(nvvidconv)
    pgie.link(nvvidconv)
    
    nvosd = Gst.ElementFactory.make("nvdsosd", "onscreendisplay")
    osdsinkpad = nvosd.get_static_pad("sink")
    osdsinkpad.add_probe(Gst.PadProbeType.BUFFER, osd_sink_pad_buffer_probe, 0)
    pipeline.add(nvosd)
    nvvidconv.link(nvosd)

    nvvidconv_postosd = Gst.ElementFactory.make("nvvideoconvert", "convertor_postosd")
    pipeline.add(nvvidconv_postosd)
    nvosd.link(nvvidconv_postosd)
    
    caps = Gst.ElementFactory.make("capsfilter", "filter")
    caps.set_property("caps", Gst.Caps.from_string("video/x-raw(memory:NVMM), format=I420"))
    pipeline.add(caps)
    nvvidconv_postosd.link(caps)
    
    encoder = Gst.ElementFactory.make("nvv4l2h264enc", "encoder")
    encoder.set_property('bitrate', 4000000)
    encoder.set_property('preset-level', 1)
    encoder.set_property('insert-sps-pps', 1)
    encoder.set_property('bufapi-version', 1)
    pipeline.add(encoder)
    caps.link(encoder)
    
    rtppay = Gst.ElementFactory.make("rtph264pay", "rtppay")
    pipeline.add(rtppay)
    encoder.link(rtppay)
    
    sink = Gst.ElementFactory.make("udpsink", "udpsink")
    sink.set_property('host', "192.168.3.1")
    sink.set_property('port', 5600)
    sink.set_property('async', False)
    sink.set_property('sync', 1)
    pipeline.add(sink)
    rtppay.link(sink)
   
    loop = GObject.MainLoop()
    pipeline.set_state(Gst.State.PLAYING)
    try:
        loop.run()
    except:
        pass
    pipeline.set_state(Gst.State.NULL)
