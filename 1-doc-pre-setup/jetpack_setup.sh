#!/bin/bash

: '
-------------------------------------------------------------------------------
SDKManager only available on ubuntu1804 (not 20.04 ...) => vm needed !

VMware Ubuntu1804 100Gb 2Gb  2 CPU USB-3 NAT (one single file)
(ubuntu-18.04.5-live-server-amd64.iso)
Network,French (keyboard), Open-ssh server, no proxy

sudo apt-get update
sudo apt-get upgrade

sudo lvm
lvm> lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
lvm> exit
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

Options after setup: Shared folders (read & write)
sudo mkdir /mnt/hgfs
sudo vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other

-------------------------------------------------------------------------------
unset http_proxy
unset https_proxy

sudo sysctl net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o wlp59s0 -j MASQUERADE

-------------------------------------------------------------------------------
/mnt/hgfs/vmshare/Material/
  nvidia/sdkmanager_1.5.0-7774_amd64.deb
  nvidia/Downloads/4.5/
    os_sdkm_downloads/
    cmp_sdkm_downloads/
  connecttech/CTI-L4T-XAVIER-NX-32.5-V004.tgz
  allied/

-------------------------------------------------------------------------------
Jetson Nano Developer Kit = Jetson module (P3448-0000) + carrier board (P3449-0000)
Jetson Nano Developer Kit (part number 945-13450-0000-000), which includes carrier board revision A02)

 1.Jumper the Force Recovery pins FRC (3 and 4) on J40 button header
 2.Connect microUSB alone
 3.Flash (10min)
 4.Remove the Force Recovery pins
 5.Run screen /dev/ttyACM0 115200
 6.Jumper the Reset pins (5 and 6) on J40 button header
 7.Initial oem-config (set default configuration)
 8.Active Ethernet USB: DHCP
   ssh pprz@192.168.55.1

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
