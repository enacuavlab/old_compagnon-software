# compagnon-software

rtl8812au 
  Ubuntu/Debian
    cd rtl8812au
    sudo apt-get install dkms
    sudo make dkms_install
    sudo apt-get install ethtool
    ethtool -i wlx0013eff21898

wifibroadcast
  Ubuntu/Debian
    cd wifibroadcast
    sudo apt-get install libpcap-dev libsodium-dev -y
    make all_bin gs.key

    wifibroadcast repositories must have the same gs.key and drone.key

run air.sh and ground.sh 
  ping 10.0.1.1
  remove su=pi, and check
  ssh 10.0.1.1
  ssh 10.0.1.2
