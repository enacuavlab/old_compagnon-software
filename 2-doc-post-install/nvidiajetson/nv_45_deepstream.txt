Deepstream

-----------------------------------------------------------------------------
sudo apt install \
libssl1.0.0 \
libgstreamer1.0-0 \
gstreamer1.0-tools \
gstreamer1.0-plugins-good \
gstreamer1.0-plugins-bad \
gstreamer1.0-plugins-ugly \
gstreamer1.0-libav \
libgstrtspserver-1.0-0 \
libjansson4=2.11-1

cd ~/Projects
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka
git reset --hard 7101c2310341ab3f4675fc565f64f0967e135a6a
./configure
make
sudo make install

sudo mkdir -p /opt/nvidia/deepstream/deepstream-5.1/lib
sudo cp /usr/local/lib/librdkafka* /opt/nvidia/deepstream/deepstream-5.1/lib


-----------------------------------------------------------------------------
/etc/apt/sources.list.d/nvidia-l4t-apt-source.list
deb https://repo.download.nvidia.com/jetson/common r32.5 main

sudo apt update
sudo apt install deepstream-5.1


-----------------------------------------------------------------------------
source30_1080p_dec_infer-resnet_tiled_display_int8.txt
source4_1080p_dec_infer-resnet_tracker_sgie_tiled_display_int8.txt

[sink0]
enable=0
[sink2]
enable=1

deepstream-app -c /opt/nvidia/deepstream/deepstream/samples/configs/deepstream-app/source30_1080p_dec_infer-resnet_tiled_display_int8.txt
ERROR: Deserialize engine failed because file path: /opt/nvidia/deepstream/deepstream-5.1/samples/configs/deepstream-app/../../models/Primary_Detector/resnet10.caffemodel_b30_gpu0_int8.engine open error

deepstream-app -c /opt/nvidia/deepstream/deepstream/samples/configs/deepstream-app/source4_1080p_dec_infer-resnet_tracker_sgie_tiled_display_int8.txt
ERROR: Deserialize engine failed because file path: /opt/nvidia/deepstream/deepstream-5.1/samples/configs/deepstream-app/../../models/Secondary_CarMake/resnet18.caffemodel_b16_gpu0_int8.engine open error


-----------------------------------------------------------------------------
sudo rm -rf ~/.cache/gstreamer-1.0/


-----------------------------------------------------------------------------
unset http_proxy
unset https_proxy
gst-launch-1.0 rtspsrc location=rtsp://192.168.3.2:8554/ds-test ! rtph264depay ! avdec_h264 ! xvimagesink sync=false

rtsp-port=8554
udp-port=5400

