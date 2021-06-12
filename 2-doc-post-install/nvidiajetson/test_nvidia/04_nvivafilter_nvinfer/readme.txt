
------------------------------------------------------------------------
gst-launch-1.0  rtspsrc location=rtsp://192.168.3.2:8554/ds-test ! rtph264depay ! avdec_h264 ! xvimagesink sync=false

vlc rtsp://192.168.3.2:8554/ds-test

------------------------------------------------------------------------
gst-launch-1.0 udpsrc port=5600 ! application/x-rtp, encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

