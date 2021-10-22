# compagnon-software

This project provides the wireless interface for ground and board systems. 
It can be run on Raspbian, Ubuntu/Debian and Nvidia Jetpack.
It has been tested on Raspberry PI(0,3,4), PC386, Jetson Nano, Jetson Xavier NX

mkdir ~/Projects
cd ~/Projects
git clone --recurse-submodules https://github.com/enacuavlab/compagnon-software.git
cd compagnon-software
./install.sh

compagnon-software/patchedwfb_on.sh (set air or ground)

copy compagnon-software/wifibroadcast drone.key gs.key


----------------------------------------------------
Previous Raspberry PI get and flash firmware
-----------------------------------

wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/2021-05-07-raspios-buster-armhf-lite.zip

SD plug
unzip -p raspios_lite_armhf-2021-05-28/2021-05-07-raspios-buster-armhf-lite.zip | dd of=/dev/sdX bs=4M conv=fsync status=progress

SD unplug / plug
/media/.../root
touch ssh
sudo vi wpa_supplicant.conf
"
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
	ssid="feiying"
	psk="pprzpprz"
}
"

PowerOn hotspot
Boot
ifconfig (get my_ip)
nmap -sn my_ip/24 (get rasp_ip)

ssh rasp_ip
pwd raspberry

/home/pi/.bashrc
"
export http_proxy=http://proxy.recherche.enac.fr:3128
export https_proxy=$http_proxy
"

/etc/apt/apt.conf.d/10proxy
"
Acquire::http::Proxy "http://proxy.recherche.enac.fr:3128" ;
Acquire::http::Proxy::debian DIRECT ;
Acquire::Ftp::Passive "false";
"

raspi-config
"
1 System Options
- S3 Password
- S4 Hostname

3 Interface Options
- P1 Camera
- P6 Serial Port

4 Performance Options
- P3 Overlay File System

5 Localisation Options
- L2 Timezone
"

Reboot

sudo apt-get update
sudo apt-get upgrade

sudo apt-get install gstreamer1.0-plugins-base -y;\
sudo apt-get install gstreamer1.0-plugins-good -y;\
sudo apt-get install gstreamer1.0-plugins-bad -y;\
sudo apt-get install gstreamer1.0-plugins-ugly -y;\
sudo apt-get install gstreamer1.0-libav -y;\
sudo apt-get install gstreamer1.0-omx -y;\
sudo apt-get install gstreamer1.0-tools -y

----------------------------------------------------
Previous NVIDIA Jetson nano and Nx get and flash firmware
-----------------------------------

To be continue
