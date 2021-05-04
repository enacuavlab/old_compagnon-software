#!/bin/bash

WORKFOLDER=/home/pprz/Projects/nvidiasandbox

MATERIAL=$WORKFOLDER/Material
DOWNLOADFOLDER=$MATERIAL/nvidia/Downloads/nvidia/os_sdkm_downloads

APT=$MATERIAL/nvidia/sdkmanager_1.5.0-7774_amd64.deb

L4T=$WORKFOLDER/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT/Linux_for_Tegra

#------------------------------------------------------------------------------
case "$1" in

  "1")
    sudo rm -R ~/.nvsdkm $WORKFOLDER/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT
    sudo apt-get install $APT
    sdkmanager --cli downloadonly --logintype devzone --targetos Linux --product Jetson --version 4.5 --target=P3668-0000 --select 'Jetson OS' --deselect 'Jetson SDK Components' --license accept --targetimagefolder $WORKFOLDER --downloadfolder $DOWNLOADFOLDER
    exit 1;;

  "2")
    sdkmanager --cli install --logintype devzone --targetos Linux --product Jetson --version 4.5 --target=P3668-0000 --select 'Jetson OS' --deselect 'Jetson SDK Components' --license accept --targetimagefolder $WORKFOLDER --downloadfolder $DOWNLOADFOLDER
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
    sudo ./flash.sh cti/xavier-nx/quark-avt mmcblk0p1
    exit 1;;

  "5")
    #ls /dev/ttyUSB0
    screen /dev/ttyUSB0 115200
    exit 1;;

esac


#------------------------------------------------------------------------------
#dns=8.8.8.8,8.8.4.4

#sudo sysctl net.ipv4.ip_forward=1
#sudo iptables -t nat -A POSTROUTING -o wlp2s0 -j MASQUERADE

#------------------------------------------------------------------------------
#sudo apt-get update


#------------------------------------------------------------------------------
#/boot/extlinux/extlinux.conf
#      FDT /boot/tegra194-xavier-nx-cti-NGX004-IMX219-2CAM.dtb

: '
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
'
