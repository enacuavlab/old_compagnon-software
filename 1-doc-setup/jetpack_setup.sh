#!/bin/bash

: '
-------------------------------------------------------------------------------
SDKManager only available on ubuntu1804 (not 20.04 ...) => vm needed !
(*)

-------------------------------------------------------------------------------
Jetson Nano Developer Kit = Jetson module (P3448-0000) + carrier board (P3449-0000)
Jetson Nano Developer Kit (part number 945-13450-0000-000), which includes carrier board revision A02)

 1.Jumper the Force Recovery pins (3 and 4) on J40 button header
 2.Connect microUSB alone
 3.Flash (10min)
 4.Remove the Force Recovery pins
 5.Run screen /dev/ttyACM1 115200
 6.Jumper the Reset pins (5 and 6) on J40 button header
 7.Initial oem-config (set default configuration)
 8.Active Ethernet USB: DHCP

-------------------------------------------------------------------------------
Jetson Xavier NX + Quark (Connecttech carrier board)

 1.Connect USB-C
 2.PowerOn
 3.Press Recovery Button (>10sec) (sudo dmesg -w ...  Product: APX)
 4.Flash 
 5.PowerOff
 6.Plug UART/USB(FTDI) adapter
 7.PowerOn
 8.Wait 30sec firstboot and Run screen /dev/ttyUSB0 115200
 9.escape
10.Initial oem-config (set network static IP configuration 192.168.3.2/255.255.255.0/192.168.3.1/8.8.8.8,8.8.4,4)

'

#------------------------------------------------------------------------------
VERSION="4.5"
#VERSION="4.5.1"

INPUT=/mnt/hgfs/vmshare
OUTPUT=/home/pprz

MATERIAL=$INPUT/Material
APT=$MATERIAL/nvidia/sdkmanager_1.5.0-7774_amd64.deb


#------------------------------------------------------------------------------
case "$1" in
  nano|xaviernx)

    if [ "$1" = "nano" ]; then
      TARGET="P3448-0000"
      WORK=$OUTPUT/JetPack_4.5_Linux_JETSON_NANO_DEVKIT
      WORK_1=$OUTPUT/JetPack_4.5_Linux_JETSON_NANO_DEVKIT_1
      WORK_2=$OUTPUT/JetPack_4.5_Linux_JETSON_NANO_DEVKIT_2
      PARALLIED=$MATERIAL/allied
      PARFLASH_1="jetson-nano-qspi-sd mmcblk0p1"
      PARFLASH_2="jetson-nano-avt mmcblk0p1"
      CFGDEV="/dev/ttyACM1"
    else 
      if [ "$1" = "xaviernx" ]; then
        TARGET="P3668-0000" # xaviernx
        CFGDEV="/dev/ttyUSB0"
        WORK=$OUTPUT/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT
        WORK_1=$OUTPUT/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT_1
        PARCTI_1=$MATERIAL/connecttech/CTI-L4T-XAVIER-NX-32.5-V004.tgz
        PARFLASH_1="cti/xavier-nx/quark-imx219 mmcblk0p1"
        PARCTI_2=$MATERIAL/connecttech/CTI-L4T-XAVIER-NX-AVT-32.5-V002.tgz
        PARFLASH_2="cti/xavier-nx/quark-avt mmcblk0p1"
        WORK_2=$OUTPUT/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT_2
      fi
    fi      

    OS_SDK=$MATERIAL/nvidia/Downloads/$VERSION/os_sdkm_downloads
    CMP_SDK=$MATERIAL/nvidia/Downloads/$VERSION/cmp_sdkm_downloads

    OPT="--version $VERSION --target=$TARGET --targetimagefolder $OUTPUT"
    CMDSDK="sdkmanager --logintype devzone --targetos Linux --product Jetson --license accept $OPT"

    #------------------------------------------------------------------------------
    case "$2" in
    
      "0")
        echo "sudo rm -R ~/.nvsdkm $WORK"
        sudo apt-get install $APT
        exit 1;;
    
      "1")
        $CMDSDK --cli downloadonly --select 'Jetson OS' --deselect 'Jetson SDK Components' --downloadfolder $OS_SDK
        exit 1;;
    
      "2")
        if [ ! -d $WORK_1 ] || [ ! -d $WORK_2 ] && [ -d $OS_SDK ]; then
          sudo rm -Rf $WORK_1 $WORK_2 &>/dev/null
          $CMDSDK --cli install --select 'Jetson OS' --deselect 'Jetson SDK Components' --downloadfolder $OS_SDK
	  sudo cp -rp $WORK $WORK_1
	  sudo mv $WORK $WORK_2
        fi
        exit 1;;
    
      "3")
        if [ -d $WORK_1 ] && [ -d $WORK_2 ]; then
          if [ "$1" = "nano" ]; then
            if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
              if [[ "$3" == "2" ]]; then 
  	        #FILE=$PARCTI_1; ln -s $WORK_1 $WORK
                #tar xvf $CTIFILE_1 -C $L4T; cd $L4T/CTI-L4T; sudo ./install.sh
  	        echo "youpi"
              fi
            fi
          elif [ "$1" = "xaviernx" ]; then
            if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
              if [[ "$3" == "1" ]]; then FILE=$PARCTI_1; ln -s $WORK_1 $WORK
              else FILE=$PARCTI_2; ln -s $WORK_2 $WORK; fi
	      if  [ ! -d $WORK/Linux_for_Tegra/CTI-L4T ]; then 
  	        tar -xvf $FILE -C $WORK/Linux_for_Tegra
  	        cd $WORK/Linux_for_Tegra/CTI-L4T; sudo ./install.sh
              fi
	      rm $WORK
            fi
          fi
        fi
        exit 1;;
    
      "4")
	if [ -d $WORK_1 ] && [ -d $WORK_2 ];  then
          if [ "$4" == "0" ]; then NOFLASH="--no-flash"
          elif [ `lsusb | grep "NVidia Corp" | wc -l` == 1 ]; then NOFLASH=" "; fi
	  if [ -n "$NOFLASH" ]; then
            if [ "$1" = "nano" ]; then
              if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
                if [[ "$3" == "1" ]]; then PARAM=$PARFLASH_1; ln -s $WORK_1 $WORK
    	      else PARAM=$PARFLASH_2; ln -s $WORK_2 $WORK; fi
                cd $WORK/Linux_for_Tegra; sudo ./flash.sh $NOFLASH $PARAM
    	      rm $WORK
              fi
            elif [ "$1" = "xaviernx" ]; then
              if [[ -n "$3" ]]; then
    	      if  ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
                  if [[ "$3" == "1" ]]; then PARAM=$PARFLASH_1; ln -s $WORK_1 $WORK
    	        else PARAM=$PARFLASH_2; ln -s $WORK_2 $WORK; fi
                  cd $WORK/Linux_for_Tegra; sudo ./flash.sh $NOFLASH $PARAM
    	        rm $WORK
                fi
              fi
            fi
	  fi
        fi
        exit 1;;
    
      "5")
	if [ `ls $CFGDEV | wc -l` == 1 ];  then
          sudo screen $CFGDEV 115200
	  # press escape
        fi
        exit 1;;
    
      "6")
        if [ -d $WORK_1 ] && [ -d $WORK_2 ]; then
          if [ "$1" = "nano" ]; then
            if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
              if [[ "$3" == "1" ]]; then ln -s $WORK_1 $WORK; else ln -s $WORK_2 $WORK; fi
	      cd $WORK/Linux_for_Tegra/rootfs/boot
              scp image tegra194-xavier-nx-cti-NGX004-AVT-2CAM.dtb pprz:@192.168.3.2:/home/pprz
              rm $WORK
            fi
          elif [ "$1" = "xaviernx" ]; then
            if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
              if [[ "$3" == "1" ]]; then FILE="tegra194-xavier-nx-cti-NGX004-AVT-2CAM.dtb"; ln -s $WORK_1 $WORK
              else FILE="tegra194-xavier-nx-cti-NGX004-IMX219-2CAM.dtb"; ln -s $WORK_2 $WORK; fi
	      cd $WORK/Linux_for_Tegra/rootfs/boot
	      sudo cp Image $3_Image
	      sudo cp $FILE "$3_$FILE"
              scp $3_Image "$3_$FILE" pprz@192.168.3.2:/home/pprz
	      sudo rm $3_Image "$3_$FILE"
	      rm $WORK
            fi
          fi
        fi
        exit 1;;

      "7")
        $CMDSDK --cli downloadonly --deselect 'Jetson OS' --select 'Jetson SDK Components' --downloadfolder $CMP_SDK
        exit 1;;
    
      "8")
        if [ -d $WORK_1 ] || [ -d $WORK_2 ] && [ -d $CMP_SDK ]; then
          if [ "$1" = "nano" ]; then
            if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
              if [[ "$3" == "1" ]]; then ln -s $WORK_1 $WORK; else ln -s $WORK_2 $WORK; fi
	      if ssh pprz@192.168.55.1 timeout 1.0 ping -c 1 www.google.com >/dev/null; then
                $CMDSDK --cli install --deselect 'Jetson OS' --select 'Jetson SDK Components' --downloadfolder $CMP_SDK
	      fi
	      rm $WORK
            fi
          elif [ "$1" = "xaviernx" ]; then
            if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
              if [[ "$3" == "1" ]]; then ln -s $WORK_1 $WORK; else ln -s WORK_2 $WORK; fi
	      if ssh pprz@192.168.3.2 timeout 1.0 ping -c 1 www.google.com >/dev/null; then
                $CMDSDK --cli install --deselect 'Jetson OS' --select 'Jetson SDK Components' --downloadfolder $CMP_SDK
	      fi
	      rm $WORK
	    fi
	  fi
	fi
        exit 1;;

    #------------------------------------------------------------------------------
    esac
    exit 1;;

  *)
    echo "nano/xaviernx 0-7"
    exit 1;;
esac


: '

------------------------------------------------------------------------------
sudo dmesg -w
=> sdb
sudo sgdisk -Z -o -n 1 -t 8300 -c 1:"PARTLABEL" /dev/sdx
sudo mkfs.ext4 /dev/sdx1

blkid -o value -s PARTUUID /dev/sdb1
=> 
PARTUUID
=>
cd Linux_for_Tegra/
bootloader/l4t-rootfs-uuid.txt_ext 
bootloader/l4t-rootfs-uuid.txt

sudo mount /dev/sdx1 /mnt
cd Linux_for_Tegra/rootfs/
sudo tar -cpf - * | ( cd /mnt/ ; sudo tar -xpf - )
(6.78Gb / 15 min)
sync
sudo umount /mnt


sudo ./flash.sh cti/xavier-nx/quark-imx219 external


Initial setup:
APP Partition size
=> Leave blank 

df .
Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/mmcblk1p1  30545312 6762876  22207756  24% /

------------------------------------------------------------------------------
Install compagnon-software

sudo apt-get install v4l-utils socat git
mkdir /home/pprz/Projects
cd Projects
git clone --recurse-submodules https://github.com/enacuavlab/compagnon-software.git
...

------------------------------------------------------------------------------
/boot/extlinux/extlinux.conf

      #LINUX /boot/Image
      LINUX /boot/2_Image
      FDT /boot/2_tegra194-xavier-nx-cti-NGX004-AVT-2CAM.dtb

------------------------------------------------------------------------------
wget https://nvidia.box.com/shared/static/p57jwntv436lfrd78inwl7iml6p13fzh.whl -O torch-1.8.0-cp36-cp36m-linux_aarch64.whl

sudo apt-get install python3-pip libopenblas-base libopenmpi-dev
pip3 install Cython
pip3 install numpy
pip3 install torch-1.8.0-cp36-cp36m-linux_aarch64.whl

sudo apt-get install libjpeg-dev zlib1g-dev libpython3-dev libavcodec-dev libavformat-dev libswscale-dev
cd Projects
git clone https://github.com/pytorch/vision torchvisiona
cd torchvision
git checkout -b v0.9.1
export BUILD_VERSION=0.9.1
python3 setup.py install --user

#!/usr/bin/env python3
import torch
print(torch.cuda.is_available())
print(torch.cuda.current_device())
print(torch.cuda.device(0))
print(torch.cuda.device_count())
print(torch.cuda.get_device_name(0))

------------------------------------------------------------------------------
------------------------------------------------------------------------------
(*)

VMware Ubuntu1804 100Gb 2Gb  2 CPU USB-3 NAT (one single file)
(ubuntu-18.04.5-live-server-amd64.iso)
Network,French (keyboard), Open-ssh server, no proxy

Options after setup: Shared folders (read & write)

(sudo mkdir /mnt/hgfs
sudo vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other)

(sudo dhcpclient ens33)

ip address
ssh pprz@
sudo apt-get update
sudo apt-get upgrade

sudo lvm
lvm> lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
lvm> exit
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

sudo apt-get install binutils

------------------------------------------------------------------------------
unset http_proxy
unset https_proxy

------------------------------------------------------------------------------
sudo sysctl net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o wlp59s0 -j MASQUERADE

ssh pprz@192.168.55.1
(ssh pprz@192.168.3.2)
sudo apt-get update

------------------------------------------------------------------------------
gst-launch-1.0 nvarguscamerasrc ! 'video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1,format=(string)NV12' \
    ! nvvidconv ! 'video/x-raw(memory:NVMM),format=(string)I420' \
    ! omxh264enc bitrate=2000000 ! 'video/x-h264, stream-format=byte-stream' \
    ! h264parse ! rtph264pay config-interval=10 pt=96 ! udpsink host=192.168.3.1 port=5700

sudo apt-get install v4l-utils
v4l2-ctl -d /dev/video0 --set-ctrl red_balance=2000 --set-ctrl blue_balance=1700 --set-ctrl exposure=70000000
gst-launch-1.0 v4l2src ! video/x-raw,format=BGRx ! nvvidconv flip-method=rotate-180 ! 'video/x-raw(memory:NVMM),width=800,height=600' \
    ! omxh264enc bitrate=1000000 peak-bitrate=1500000 preset-level=0 ! video/x-h264, stream-format=byte-stream \
    ! rtph264pay mtu=1400 ! udpsink host=192.168.3.1 port=5700

sudo apt-get install gstreamer1.0-plugins-bad
gst-launch-1.0 udpsrc port=5700 ! application/x-rtp, encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false
'
