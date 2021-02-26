# compagnon-software

-------------------------------------------------------------------------------
rtl8812au 

  Ubuntu/Debian
    cd rtl8812au
    sudo apt-get install dkms
    sudo make dkms_install
    sudo apt-get install ethtool
    ethtool -i wlx0013eff21898

  Raspbian
    RPI 1/2/3/ & 0/Zero
      sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
      sed -i 's/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g' Makefile
    RPI 3B+ & 4B
      sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
      sed -i 's/CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/g' Makefile
    make 
    make install

-------------------------------------------------------------------------------
wifibroadcast

  Ubuntu/Debian Raspbian
    cd wifibroadcast
    sudo apt-get install libpcap-dev libsodium-dev -y
    make all_bin gs.key

  wifibroadcast repositories must have the same gs.key and drone.key

-------------------------------------------------------------------------------
sudo cp wifibroadcast/scripts/wifibroadcast.service /etc/systemd/system
sudo cp 60-wifibroadcast.rules /etc/udev/rules.d
sudo udevadm control --reload-rules && udevadm trigger

systemctl status wifibroadcast.service

wl=`lshw -businfo 2>/dev/null | grep "^usb" | grep network | awk '{print $2}'`
ph=`iw dev $wl info | grep wiphy | awk '{print "phy"$2}'`
nb=`rfkill --raw | grep $ph | awk '{print $1}'`
rfkill unblock $nb


sudo ./air.sh
sudo ./ground.sh 

ping 10.0.1.1
remove su=pi, and check
ssh 10.0.1.1
ssh 10.0.1.2
