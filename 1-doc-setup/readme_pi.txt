PI0/PI3/PI4 (OS 32bit)
wget https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip

PI4 (OS 64bit)
wget https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/2020-08-20-raspios-buster-arm64-lite.zip

Flash the RaspberryPi OS on a 16Gb minimum size SD
./balenaEtcher-1.5.79-x64.AppImage

Re-Plug SD
(automount)
cd /media/.../boot
sudo touch ssh

sudo vi wpa_supplicant.conf
"
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=FR
network={
   ssid="Androidxp"
   psk="pprzpprz"
}
network={
  ssid="pprz_router"
  key_mgmt=NONE
}
"

sudo vi /media/../rootfs/etc/dhcpcd.conf
"
# It is possible to fall back to a static IP if DHCP fails:
# define static profile
profile static_eth0
static ip_address=192.168.3.2/24
static routers=192.168.3.1
static domain_name_servers=8.8.8.8
# fallback to static profile on eth0
interface eth0
fallback static_eth0
"

Plug the SD on the PI, and power on

(nmap -sn 192.168.1.0/24)

ssh pi@...
password: raspberry

sudo raspi-config
 1) change user password
 5) P1) enable camera
    P6) login shell:disable
        serial interface:enable
 7) advanced options
   A1) expand filesystem

/etc/hosts
127.0.1.1       raspberrypi
to 127.0.1.1    airpi or groundpi

/etc/hostname
raspberrypi to airpi or groundpi


-------------------------------------------------------------------------------:w!
For PI3

/boot/config.txt
dtoverlay=pi3-disable-bt

sudo reboot

sudo systemctl stop serial-getty@ttyAMA0.service
sudo systemctl disable serial-getty@ttyAMA0.service

sudo systemctl stop hciuart
sudo systemctl disable hciuart

-------------------------------------------------------------------------
Share wireless internet with ethernet
(Ethernet should connected before wireless powerup)

Ubuntu
sudo sysctl net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o wlp59s0 -j MASQUERADE

-------------------------------------------------------------------------
sudo apt-get update
sudo apt-get upgrade

