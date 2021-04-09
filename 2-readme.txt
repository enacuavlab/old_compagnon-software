compagnon-software

-------------------------------------------------------------------------------
sudo apt-get install v4l-utils socat git

-------------------------------------------------------------------------------
mkdir /home/.../Projects
cd Projects
git clone --recurse-submodules https://github.com/enacuavlab/compagnon-software.git

-------------------------------------------------------------------------------
Ubuntu/Debian :
  Internal wifi should be poweroff
  Service should be restart after boot (plugging the dongle will start the service)
  External USB wifi dongle can be plugged and unplugged

-------------------------------------------------------------------------------
rtl8812au 

  cd compagnon-software
  sudo cp material/rtl8812au.conf /etc/modprobe.d
  (cat /sys/module/88XXau/parameters/rtw_monitor_disable_1m 1) 

  cd rtl8812au
  patch -p1 < ../material/rtl8812au_v5.6.4.2.patch
  (patch -R -p1 < ../material/rtl8812au_v5.6.4.2.patch)

  Ubuntu/Debian, Jetpack(nano,xavierNX)(*)
    cd rtl8812au
    sudo apt-get install dkms
    sudo make dkms_install
    (dkms status;dkms remove ... --all)
    sudo cp ../material/rtl8812au.conf /etc/modprobe.d
    sudo apt-get install ethtool
    ethtool -i wlx0013eff21898

  Raspbian
    RPI 0 & 3 & 4 (with OS 32)
      sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
      sed -i 's/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g' Makefile
    RPI 3B+ & 4 (with OS 64b)
      sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
      sed -i 's/CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/g' Makefile
    sudo apt-get install linux-headers
    make 
    sudo make install

(*)
/etc/modprobe.d/blacklist.conf
blacklist rtl8812au

-------------------------------------------------------------------------------
wifibroadcast

  Ubuntu/Debian, Jetpack, Raspbian
    cd wifibroadcast
    sudo apt-get install libpcap-dev libsodium-dev -y
    make all_bin gs.key

  wifibroadcast repositories must have the same gs.key and drone.key

-------------------------------------------------------------------------------
Update HOME in air.sh,ground.sh,wfb_on.sh,wifibroadcast.service
Update "air.sh or ground.sh" in wfb_on.sh

-------------------------------------------------------------------------------
Raspberry PI

/etc/dhcpcd.conf

#denyinterfaces wlan0
denyinterfaces wlan1

-------------------------------------------------------------------------------
sudo cp material/wifibroadcast.service /etc/systemd/system
sudo cp material/60-wifibroadcast.rules /etc/udev/rules.d
sudo udevadm control --reload-rules
sudo udevadm trigger

systemctl enable wifibroadcast.service
systemctl start wifibroadcast.service
systemctl stop wifibroadcast.service
systemctl status wifibroadcast.service
systemctl disable wifibroadcast.service
systemctl daemon-reload

