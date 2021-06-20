-------------------------------------------------------------------------
Build and flash

option 1) Build and flash image from Jetpack SDK Manager environnment
Jumper the Force Recovery pins FRC (3 and 4) on J40 button header
=> APX
sudo ./flash.sh jetson-nano-qspi-sd mmcblk0p1


option 2) Build and flash SD image from Jetpack SDK Manager environnment
sudo ./jetson-disk-image-creator.sh -o sd-blob.img -b jetson-nano-2gb-devkit -r 100
=>
5.5 Gb

Copy images (partitions) to SD

sudo dd if=sd-blob.img of=/dev/mmcblk1 bs=1M oflag=direct
5683+0 records in
5683+0 records out
5959057408 bytes (6.0 GB, 5.5 GiB) copied, 399.339 s, 14.9 MB/s

-------------------------------------------------------------------------
Initial setup

Micro/USB (serial/storage/ethernet/power) 
(Jumper the Reset pins (5 and 6) on J40 button header)
screen /dev/ttyACM0 115200

Primary network interface:
eth0: Ethernet 
192.168.3.2/255.255.255.0/192.168.3.1/8.8.8.8,8.8.4.4

-------------------------------------------------------------------------
Usage and update

sudo sysctl net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o wlp59s0 -j MASQUERADE

Option 1) Default throught micro-USB interface
NVIDIA (usb) Ethernet connected
ifconfig
eth0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 192.168.3.2  netmask 255.255.255.0  broadcast 192.168.3.255
ssh pprz@192.168.55.1

Option 2) throught ethernet interface
Static Ethernet 192.168.3.1
ssh 192.168.3.2

wait few seconds for automatic update to be finished
E: Could not get lock /var/lib/apt/lists/lock - open (11: Resource temporarily unavailable)


sudo apt-get update
