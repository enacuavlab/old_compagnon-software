#!/bin/bash

VERSION="4.5"
#VERSION="4.5.1"
WORKFOLDER=/home/pprz/Projects/nvidiasandbox
MATERIAL=$WORKFOLDER/Material
APT=$MATERIAL/nvidia/sdkmanager_1.5.0-7774_amd64.deb

#------------------------------------------------------------------------------
case "$1" in
  nano|xaviernx)

    if [ "$1" = "nano" ]; then
      TARGET="P3448-0000"
      WORK=$WORKFOLDER/JetPack_4.5_Linux_JETSON_NANO_DEVKIT
      FLASH=flash.sh jetson-nano-devkit-emmc mmcblk0p1
    else 
      TARGET="P3668-0000"
      WORK=$WORKFOLDER/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT
      FLASH=flash.sh cti/xavier-nx/quark-avt mmcblk0p1
    fi

    OS_SDK=$MATERIAL/nvidia/Downloads/$VERSION/os_sdkm_downloads
    CMP_SDK=$MATERIAL/nvidia/Downloads/$VERSION/cmp_sdkm_downloads
    L4T=$WORK/Linux_for_Tegra

    CMD="sdkmanager --logintype devzone --targetos Linux --product Jetson --license accept --version $VERSION --target=$TARGET --targetimagefolder $WORKFOLDER"

    #------------------------------------------------------------------------------
    case "$2" in
    
      "0")
        echo "sudo rm -R ~/.nvsdkm $WORK"
        sudo apt-get install $APT
        exit 1;;
    
      "1")
        $CMD --cli downloadonly --select 'Jetson OS' --deselect 'Jetson SDK Components' --downloadfolder $OS_SDK
        exit 1;;
    
      "2")
        $CMD --cli install --select 'Jetson OS' --deselect 'Jetson SDK Components' --downloadfolder $OS_SDK
        exit 1;;
    
      "3")
        tar xvf $MATERIAL/connettech/CTI-L4T-XAVIER-NX-AVT-32.5-V002.tgz -C $L4T
        cd $L4T/CTI-L4T
        sudo ./install.sh
        exit 1;;
    
      "4")
        #lo=`lsusb | grep "NVidia Corp"`
        #echo $lo
        cd $L4T
        sudo $FLASH
        exit 1;;
    
      "5")
        #ls /dev/ttyUSB0
        screen /dev/ttyUSB0 115200
        exit 1;;
    
      "6")
        $CMD --cli downloadonly --deselect 'Jetson OS' --select 'Jetson SDK Components' --downloadfolder $CMP_SDK
        exit 1;;
    
      "7")
        #ssh pprz@192.168.3.2 ping www.google.com
        $CMD --cli install --deselect 'Jetson OS' --select 'Jetson SDK Components' --downloadfolder $CMP_SDK
        exit 1;;
    
    esac
    exit 1;;

  *)
    echo "nano/xaviernx 0-7"
    exit 1;;
esac


: '
#------------------------------------------------------------------------------
/etc/NetworkManager/system-connections/...
192.168.3.2
192.168.3.1
255.255.255.0
dns=8.8.8.8,8.8.4.4

------------------------------------------------------------------------------
unset http_proxy
unset https_proxy
sudo sysctl net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o wlp59s0 -j MASQUERADE

ssh pprz@192.168.3.2
sudo apt-get update

------------------------------------------------------------------------------
sudo fdisk -l |grep GiB
=>
Disk /dev/mmcblk1: 29.7 GiB, 31914983424 bytes, 62333952 sectors
Disk /dev/mmcblk0: 14.7 GiB, 15758000128 bytes, 30777344 sectors

sudo blkid
=>
/dev/mmcblk1p1: UUID="cb377b7d-54dd-4e02-95d6-2fb06ca806c5" TYPE="ext4" PARTUUID="3be52ecb-01"

/etc/fstab
UUID=cb377b7d-54dd-4e02-95d6-2fb06ca806c5       /alt    ext4    defaults        0 2

sudo mkdir /alt
sudo mount -a
cd /usr
sudo mv local share src /alt
sudo ln -s /alt/* .
sudo sync
sudo reboot
df

------------------------------------------------------------------------------
Install compagnon-software

sudo apt-get install v4l-utils socat git
mkdir /home/pprz/Projects
cd Projects
git clone --recurse-submodules https://github.com/enacuavlab/compagnon-software.git
...

------------------------------------------------------------------------------
/boot/extlinux/extlinux.conf
      FDT /boot/tegra194-xavier-nx-cti-NGX004-IMX219-2CAM.dtb

------------------------------------------------------------------------------
sudo apt install python3-pip
sudo apt-get install libhdf5-serial-dev hdf5-tools libhdf5-dev zlib1g-dev zip libjpeg8-dev liblapack-dev libblas-dev gfortran

sudo pip3 install -U pip testresources setuptools==49.6.0
sudo pip3 install -U numpy==1.19.4 future==0.18.2 mock==3.0.5 h5py==2.10.0 keras_preprocessing==1.1.1 keras_applications==1.0.8 gast==0.2.2 futures protobuf pybind11
sudo pip3 install --pre --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v45 tensorflow
pip3 install torch
pip3 install torchvision
#pip3 install torchaudio
pip3 install serial

'
