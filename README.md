# compagnon-software

This project provides the wireless interface for ground and board systems.  
It can be run on Raspbian, Ubuntu/Debian and Nvidia Jetpack.  
It has been tested on Raspberry PI(0,3,4), PC386, Jetson Nano, Jetson Xavier NX  

mkdir ~/Projects  
cd ~/Projects  
git clone --recurse-submodules https://github.com/enacuavlab/compagnon-software.git  
cd compagnon-software  
./install.sh  

compagnon-software/patched/wfb_on.sh (set air or ground)  

copy compagnon-software/wifibroadcast drone.key gs.key  

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
Debian 11.3 (bulleyes) on Raspberry : Board and Ground

---------------------------------------------------------------------------------
1) SETTING RASPBERRY PI WITH PI OS Debian 11.3 (bullseye)
------------------------------------------------------

Get image file

https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-04-07/2022-04-04-raspios-bullseye-arm64-lite.img.xz
(283.5 MB)

Flash the SD

cd /media/pprz/../boot

echo 'pprz' | openssl passwd -6 -stdin >> userconf.txt  
vi userconf.txt   
'  
pprz:...  
'  

touch ssh  

vi wpa_supplicant.conf  
"  
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev  
update_config=1  
network={  
ssid="feiying"  
psk="pprzpprz"  
"  
(  
key_mgmt=WPA-PSK  
needed ?  
)  


First boot wait 75 sec, before trying to connect  

nmap -sn "HotSpotIP"/24  
=> rasp_IP  

ssh pprz@"rasp_IP"  


sudo bash -c 'echo "dtoverlay=disable-bt" >> /boot/config.txt'  
sudo systemctl disable hciuart.service  
sudo systemctl disable bluetooth.service  


Raspi-Config

3 Interface Options

I6 Serial Port 
- The serial login shell is disabled
- The serial interface is enabled

Reboot

date -s "..."  
sudo apt-get  update  
sudo apt-get upgrade 

export http_proxy=http://proxy.recherche.enac.fr:3128  
export https_proxy=http://proxy.recherche.enac.fr:3128  

---------------------------------------------------------------------------------
2) INSTALL COMPAGNON_SOFTWARE 
--------------------------
See above  

---------------------------------------------------------------------------------
3) COMPLETE INSTALLATION AND TEST CAMERA 
-------------------------------------

sudo apt-get install gstreamer1.0-plugins-base -y;\
sudo apt-get install gstreamer1.0-plugins-good -y;\
sudo apt-get install gstreamer1.0-plugins-bad -y;\
sudo apt-get install gstreamer1.0-plugins-ugly -y;\
sudo apt-get install gstreamer1.0-libav -y;\
sudo apt-get install gstreamer1.0-omx -y;\
sudo apt-get install gstreamer1.0-tools -y

gst-launch-1.0 -vvvv libcamerasrc ! video/x-raw,width=1280,height=720,format=NV12,colorimetry=bt601,framerate=30/1,interlace-mode=progressive ! v4l2h264enc extra-controls=controls,repeat_sequence_header=1,video_bitrate=3800000 ! 'video/x-h264,level=(string)4' ! rtph264pay name=pay0 pt=96 config-interval=1 ! udpsink host=10.42.0.1 port=5000

gst-launch-1.0 udpsrc port=5000 ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false


sudo raspi-config  
4 Performance Options  
P3 Overlay File System  
(overlay + read only boot)  

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
Ubuntu 20.04 on Raspberry PI4 : Ground with Paparazzi
  
https://cdimage.ubuntu.com/releases/20.04/release/ubuntu-20.04.4-preinstalled-server-arm64+raspi.img.xz  
  
------------------------------------------  
cd /media/pprz/system-boot  
  
touch ssh  
  
vi network-config  
  
ethernets:  
  eth0:  
    dhcp4: true  
    optional: true  
  
wifis:  
  wlan0:  
    dhcp4: true  
    optional: true  
    access-points:  
      "Livebox-3218":  
        password: "......."  
  
(remove from /etc/netplan/50-cloud-init.yaml after boot  
write to /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg "network: {config: disabled}"  
?? 
network: 
  version: 2 
  renderer: NetworkManager 
"  
sudo netplan generate  
sudo netplan apply  
?? 
reboot)  
  
------------------------------------------  
Plug and boot  
   
nmap -sn MyIP/24  
  
ssh ubuntu@RaspIp  
(password) ubuntu  
  
sudo passwd ubuntu  
  
sudo apt-get update  
sudo apt-get upgrade  
  
sudo adduser pprz  
...  
sudo adduser pprz sudo  
  
sudo deluser --remove-home ubuntu  
  
sudo apt install ubuntu-desktop  
  
  
sudo apt install pi-bluetooth  
/boot/firware/usercfg.txt  
"  
include btcfg.txt  
"  
  
sudo vi /boot/firmware/syscfg.txt   
"   
dtoverlay=vc4-fkms-v3d  
"  
  
------------------------------------------  
uname -a  
Linux groundpi 5.4.0-1052-raspi #58-Ubuntu SMP PREEMPT Mon Feb 7 16:52:35 UTC 2022 aarch64 aarch64 aarch64 GNU/Linux  
  
  
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
Raspi zero: (ARM port max: arm6hf 32b)  
Raspi 1: (ARM port max: arm6hf 32b)  
Raspi 2: ARMv7 CPU (ARM port max: armhf 32b)  
  
Raspi zero 2: Cortex-A53 quadcore ARMv8 CPU (ARM port max: arm64 64b)  
Raspi 3: Cortex-A53 quadcore ARMv8 CPU (ARM port max: arm64 64b)    
Raspi 4: Cortex-A72 quadcore ARMv8 CPU (ARM port max: arm64 64b)   

---------------------------------------------------------------------------------
TESTED  
------
Linux raspberrypi 5.15.32-v8+ #1538 SMP PREEMPT Thu Mar 31 19:40:39 BST 2022 aarch64 GNU/Linux

Raspi 4 (embedded)

Raspi Zero 2
- Talon 250

Raspi 3 B V1.2 (2005)
- Explorer 116

