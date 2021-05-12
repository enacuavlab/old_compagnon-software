#!/bin/bash

: '
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

#ln -s /mnt/extssd /home/pprz/Projects/nvidiasandbox/workspace
WORKFOLDER=/home/pprz/Projects/nvidiasandbox

MATERIAL=$WORKFOLDER/Material
APT=$MATERIAL/nvidia/sdkmanager_1.5.0-7774_amd64.deb


#------------------------------------------------------------------------------
case "$1" in
  nano|xaviernx)

    if [ "$1" = "nano" ]; then
      TARGET="P3448-0000"
      WORK=$WORKFOLDER/JetPack_4.5_Linux_JETSON_NANO_DEVKIT
      CMDFLASH="./flash.sh jetson-nano-qspi-sd mmcblk0p1"
      CFGDEV="/dev/ttyACM1"
    else 
      if [ "$1" = "xaviernx" ]; then
        TARGET="P3668-0000" # xaviernx
        CFGDEV="/dev/ttyUSB0"
        WORK=$WORKFOLDER/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT
        PARCTI_1=$MATERIAL/connecttech/CTI-L4T-XAVIER-NX-32.5-V004.tgz
        PARFLASH_1="cti/xavier-nx/quark-imx219 mmcblk0p1"
        PARCTI_2=$MATERIAL/connecttech/CTI-L4T-XAVIER-NX-AVT-32.5-V002.tgz
        PARFLASH_2="cti/xavier-nx/quark-avt mmcblk0p1"
        #sudo ./flash.sh -r -k kernel-dtb cti/Xavier-NX/quark-imx219 mmcblk0p1
        #sudo ./flash.sh -r -k kernel cti/Xavier-NX/quark-imx219 mmcblk0p1
      fi
    fi      

    OS_SDK=$MATERIAL/nvidia/Downloads/$VERSION/os_sdkm_downloads
    CMP_SDK=$MATERIAL/nvidia/Downloads/$VERSION/cmp_sdkm_downloads
    L4T=$WORK/Linux_for_Tegra

    OPT="--version $VERSION --target=$TARGET --targetimagefolder $WORKFOLDER"
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
        $CMDSDK --cli install --select 'Jetson OS' --deselect 'Jetson SDK Components' --downloadfolder $OS_SDK
	#cd /home/pprz/Projects/nvidiasandbox
	#sudo tar cvf JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT.tar JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT
	#sudo mv /home/pprz/Projects/nvidiasandbox/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT.tar /mnt/extssd
	#sudo tar xvf /mnt/extssd/JetPack_4.5_Linux_JETSON_XAVIER_NX_DEVKIT.tar -C /mnt/extssd

	#sudo cp -rp $L4T $WORK/Linux_for_Tegra_1
	#sudo mv $L4T $WORK/Linux_for_Tegra_2
        exit 1;;
    
      "3")
        if [ "$1" = "nano" ]; then
          tar xvf $CTIFILE_1 -C $L4T;cd $L4T/CTI-L4T;sudo ./install.sh
        elif [ "$1" = "xaviernx" ]; then
          if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
            if [[ "$3" == "1" ]]; then FILE=$PARCTI_1; else FILE=$PARCTI_2; fi
            mv $WORK/Linux_for_Tegra_$3 $L4T
	    tar -xvf $FILE -C $L4T
	    cd $L4T/CTI-L4T;sudo ./install.sh
	    mv $L4T  $WORK/Linux_for_Tegra_$3
          fi
        fi
        exit 1;;
    
      "4")
        #lo=`lsusb | grep "NVidia Corp"`
        #echo $lo
        if [ "$1" = "nano" ]; then
          sudo $CMDFLASH
        elif [ "$1" = "xaviernx" ]; then
          if [[ -n "$3" ]] && ([[ "$3" == "1" ]] || [[ "$3" == "2" ]]); then
            if [[ "$3" == "1" ]]; then PARAM=$PARFLASH_1; else PARAM=$PARFLASH_2; fi
            mv $WORK/Linux_for_Tegra_$3 $L4T
            cd $L4T;sudo ./flash.sh --no-flash $PARAM # --no-flash
	    mv $L4T $WORK/Linux_for_Tegra_$3
          fi
        fi
        exit 1;;
    
      "5")
        #ls $CFGDEV
        screen $CFGDEV 115200
	# press escape
        exit 1;;
    
      "6")
        $CMDSDK --cli downloadonly --deselect 'Jetson OS' --select 'Jetson SDK Components' --downloadfolder $CMP_SDK
        exit 1;;
    
      "7")
        #ssh pprz@192.168.55.1 ping www.google.com
        $CMDSDK --cli install --deselect 'Jetson OS' --select 'Jetson SDK Components' --downloadfolder $CMP_SDK
        exit 1;;
    
    esac
    exit 1;;

  *)
    echo "nano/xaviernx 0-7"
    exit 1;;
esac


: '
------------------------------------------------------------------------------
ssd ext4
sudo mkdir /mnt/extssd
sudo mount /dev/mmcblk0p1 /mnt/extssd

------------------------------------------------------------------------------
unset http_proxy
unset https_proxy

------------------------------------------------------------------------------
sudo sysctl net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o wlp59s0 -j MASQUERADE

ssh pprz@192.168.55.1
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