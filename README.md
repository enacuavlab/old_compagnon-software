# compagnon-software

This project provides the software for ground and board systems. 
It can be run on Raspbian, Ubuntu/Debian and Jetpack.
It has been tested on Raspberry PI(0,3,4), PC386, Jetson Xavier NX

-------------------------------------------------------------------------------
cd Projects
git clone --recurse-submodules https://github.com/enacuavlab/compagnon-software.git

-------------------------------------------------------------------------------
sudo apt-get install v4l-utils socat

-------------------------------------------------------------------------------
Ubuntu/Debian :
  Internal wifi should be poweroff
  Service should be restart after boot (plugging the dongle will start the service)
  External USB wifi dongle can be plugged and unplugged

-------------------------------------------------------------------------------
rtl8812au 

  Ubuntu/Debian, Jetpack(xavierNX)(*)
    cd rtl8812au
    sudo apt-get install dkms
    sudo make dkms_install
    sudo apt-get install ethtool
    ethtool -i wlx0013eff21898

  Raspbian, JetPack
    RPI 1/2/3/ & 0/Zero
      sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
      sed -i 's/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g' Makefile
    RPI 3B+ & 4B
      sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
      sed -i 's/CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/g' Makefile
    make 
    (sudo)make install

(*)
/etc/modprobe.d/blacklist.conf
blacklist rtl8812au

-------------------------------------------------------------------------------
wifibroadcast

  Ubuntu/Debian Raspbian
    cd wifibroadcast
    sudo apt-get install libpcap-dev libsodium-dev -y
    make all_bin gs.key

  wifibroadcast repositories must have the same gs.key and drone.key

-------------------------------------------------------------------------------
Update HOME in air.sh,ground.sh,wfb_on.sh
Update "air.sh or ground.sh" in wfb_on.sh
Update ExecStart,ExecStop in wifibroadcast.service
Update "air_campi.sh or air_camjet.sh" in air.sh

-------------------------------------------------------------------------------
sudo cp wifibroadcast.service /etc/systemd/system
sudo cp 60-wifibroadcast.rules /etc/udev/rules.d
sudo udevadm control --reload-rules
sudo udevadm trigger

systemctl start wifibroadcast.service
systemctl stop wifibroadcast.service
systemctl status wifibroadcast.service
systemctl disable wifibroadcast.service

-------------------------------------------------------------------------------
ISSUES:
  
  Ubuntu/Debian 
    ping and ssh not working

ping 10.0.1.1
remove su=pi, and check
ssh 10.0.1.1
ssh 10.0.1.2
