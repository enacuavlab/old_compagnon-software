
ssh pprz@192.168.55.1


https://developer.nvidia.com/embedded/linux-tegra

wget https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/t210/jetson-210_linux_r32.5.1_aarch64.tbz2
wget https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/sources/t210/public_sources.tbz2
wget https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/t210/tegra_linux_sample-root-filesystem_r32.5.1_aarch64.tbz2
(1.4Gb)
(
https://developer.nvidia.com/embedded/L4T/r32_Release_v5.0/sources/T210/public_sources.tbz2
)

git clone https://github.com/alliedvision/linux_nvidia_jetson.git
(without proxy)

mkdir /home/pprz/linux_nvidia_jetson/avt_build/resources/driverPackage
mkdir /home/pprz/linux_nvidia_jetson/avt_build/resources/gcc

cp jetson-210_linux_r32.5.1_aarch64.tbz2 ~/linux_nvidia_jetson/avt_build/ressources/driverPackage
cp public_sources.tbz2 ~/linux_nvidia_jetson/avt_build/ressources/public_sources
cp tegra_linux_sample-root-filesystem_r32.5.1_aarch64.tbz2 ~/linux_nvidia_jetson/avt_build/resources/rootf
cp gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz ~/linux_nvidia_jetson/avt_build/resources/gcc

setup.sh
FILE_DRIVER_PACKAGE_NANO="jetson-210_linux_r32.5.1_aarch64.tbz2"
FILE_ROOTFS_NANO="tegra_linux_sample-root-filesystem_r32.5.1_aarch64.tbz2"
FILE_PUBLICSOURCES_NANO="public_sources.tbz2"
FILE_GCC_64="gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz"

deploy.sh
DEDICATED_VERSION="32.5.1"
DEDICATED_VERSION="32.5"

./setup.sh workdir nano
=> workdir/Linux_for_Tegra
./build.sh workdir nano all all
./deploy.sh workdir nano tarball
=> AlliedVision_NVidia_nano_L4T_32.5.1_4.9.140-g84fcaed28.tar.gz (30Mb)


Copy the tarball to the target board. Extract the tarball.
scp AlliedVision_NVidia_nano_L4T_32.5_4.9.140-g28667a208-dirty.tar.gz pprz@192.168.55.1:/home/pprz
tar xfz AlliedVision_NVidia_nano_L4T_32.5_4.9.140-g28667a208-dirty.tar.gz

sudo cp tegra210-p3448-0000-p3449-0000-a02.dtb /boot/avt_tegra210-p3448-0000-p3449-0000-a02.dtb
sudo cp Image /boot/avt_Image
sudo tar zxf modules.tar.gz -C /

/boot/extlinux/extlinux.conf
      LINUX /boot/avt_Image
      FDT /boot/avt_tegra210-p3448-0000-p3449-0000-a02.dtb

Reboot the board.
(dtc -s -I fs /proc/device-tree -O dts > log)


-------------------------------------------------------------------------------------------------------
gst-launch-1.0 nvarguscamerasrc ! 'video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1,format=(string)NV12' \
>     ! nvvidconv ! 'video/x-raw(memory:NVMM),format=(string)I420' \
>     ! omxh264enc bitrate=2000000 ! 'video/x-h264, stream-format=byte-stream' \
>     ! h264parse ! rtph264pay config-interval=10 pt=96 ! udpsink host=192.168.55.100 port=5700

-------------------------------------------------------------------------------------------------------
v4l2-ctl -d /dev/video0 --set-ctrl red_balance=2000 --set-ctrl blue_balance=1700 --set-ctrl exposure=70000000
gst-launch-1.0 v4l2src ! video/x-raw,format=BGRx ! nvvidconv flip-method=rotate-180 ! 'video/x-raw(memory:NVMM),width=800,height=600' \
    ! omxh264enc bitrate=1000000 peak-bitrate=1500000 preset-level=0 ! video/x-h264, stream-format=byte-stream \
    ! rtph264pay mtu=1400 ! udpsink host=127.0.0.1 port=5700

-------------------------------------------------------------------------------------------------------
gst-launch-1.0 udpsrc port=5700 ! application/x-rtp, encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false


