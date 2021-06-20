#!/usr/bin/env python3
import numpy as np
import cv2

width=640
height=480
fps=30

# -----------------------------------------------------
# QUESTION ?
# HOW TO REMOVE videoconvert ! video/x-raw, format=BGR
# -----------------------------------------------------

def gstreamer_pipeline_in(
    capture_width=width,
    capture_height=height,
    capture_framerate=fps,
    flip_method=0):
  return (
    "nvarguscamerasrc "
    "! video/x-raw(memory:NVMM),width=%d,height=%d,format=NV12,framerate=%d/1 "
    "! nvvidconv flip-method=%d "
    "! queue max-size-buffers=1 leaky=downstream "
    "! video/x-raw,format=I420 "
    "! appsink sync=false"
    % (capture_width,capture_height,capture_framerate,flip_method))


def gstreamer_pipeline_out(
    bitrate=2000000,
   # ip="127.0.0.1",
    ip="192.168.3.1",
    port=5700):
  return (
      "appsrc "
      "! nvvidconv "
      "! nvv4l2h264enc bitrate=%d "
      "! h264parse "
      "! rtph264pay name=pay0 pt=96 config-interval=1 "
      "! udpsink host=%s port=%d"
      % (bitrate,ip,port))

#def gstreamer_pipeline_in(
#    capture_width=width,
#    capture_height=height,
#    capture_framerate=fps,
#    flip_method=0):
#  return (
#    "nvarguscamerasrc"
#    "! video/x-raw(memory:NVMM),width=%d,height=%d,format=NV12,framerate=%d/1"
#    "! nvvidconv flip-method=%d"
#    "! videoconvert ! video/x-raw, format=BGR"
#    "! queue"
#    "! appsink sync=0"
#    % (capture_width,capture_height,capture_framerate,flip_method))
#
#
#def gstreamer_pipeline_out(
#    bitrate=2000000,
#   # ip="127.0.0.1",
#    ip="192.168.3.1",
#    port=5700):
#  return (
#      "appsrc "
#      "! video/x-raw, format=BGR ! videoconvert "
#      "! nvvidconv "
#      "! nvv4l2h264enc bitrate=%d "
#      "! h264parse "
#      "! rtph264pay name=pay0 pt=96 config-interval=1 "
#      "! udpsink host=%s port=%d"
#      % (bitrate,ip,port))
 
def camera_capture():
  cap = cv2.VideoCapture(gstreamer_pipeline_in(),cv2.CAP_GSTREAMER)
  out = cv2.VideoWriter(gstreamer_pipeline_out(),cv2.CAP_GSTREAMER,0, fps, (width,height), True)
  if not cap.isOpened() or not out.isOpened():
    print("not opened")
    quit()
  img_gpu_src = cv2.cuda_GpuMat() 
  img_gpu_dst = cv2.cuda_GpuMat()
  try:
    while True:
      ret, img = cap.read()
      if ret:
        print("OK")
        #img_gpu_src.upload(img)
        #img_gpu_dst = cv2.cuda.cvtColor(img_gpu_src, cv2.COLOR_BGR2GRAY)
        #img_dst = img_gpu_dst.download()
        img=cv2.cvtColor(img, cv2.COLOR_YUV2BGR_I420)
        img=cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        out.write(img)
            
            
  except KeyboardInterrupt:
    cap.release()
    cv2.destroyAllWindows()
    print("Press Ctrl-C to terminate while statement")
    pass

if __name__ == "__main__":
    camera_capture()
