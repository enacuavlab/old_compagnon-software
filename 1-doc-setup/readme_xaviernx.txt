

------------------------------------------------------------------------------
Install new NX board

- Install and oem configure JetPack OS in board memory (EMMC) using NVIDIA JETPACK SDK MANAGER via USB-C and UART console
  (remove SD-Card before installation)

  sudo ./flash.sh cti/xavier-nx/quark-avt mmcblk0p1
  or
  sudo ./flash.sh cti/xavier-nx/quark-imx219 mmcblk0p1

  oem-config: static eth 192.168.3.2/255.255.255.0/192.168.3.1/8.8.8.8,8.8.4.4    


- Set next boot to SD-Card 
    
    /boot/extlinux/extlinux.conf
    
    DEFAULT sd
    
    LABEL primary
      ...
      APPEND ${cbootargs} quiet root=/dev/mmcblk0p1 ...
    
    LABEL sd
      MENU LABEL sd kernel
      ...
      APPEND ${cbootargs} quiet root=/dev/mmcblk1p1 ...
      

- Install backup image (JetPack OS + Components + PyTorch + Others) to SD-Card via USB/SD adpater

  sudo dd if=backup_image.img of=/dev/sdX bs=1024K
  (change X from your environment)
  =>
  16239+1 records in
  16239+1 records out
  17027842560 bytes (17 GB, 16 GiB) copied, 880,58 s, 19,3 MB/s
  =>

  sudo gparted
  =>
    Not all of the space available to /dev/sdb appears to be used, you can fix the GPT to use all of the space (an extra 29076447 blocks) or continue with the current setting? 
  Fix
  Expand APP partition to the end of the SD-Card

- Boot 
  (insert SD-Card before boot)  

  If using ethernet : ssh pprz@192.168.3.2
  If wifibroadcat : ssh pprz@10.0.1.2

  df .
  Filesystem     1K-blocks     Used Available Use% Mounted on
  /dev/mmcblk1p1  30189868 15571196  13340380  54% /


------------------------------------------------------------------------------
Install NVIDIA JETPACK SDK MANAGER
----------------------------------
VMware Ubuntu1804 100Gb 2Gb  2 CPU USB-3 NAT (one single file)
(ubuntu-18.04.5-live-server-amd64.iso)
Network,French (keyboard), Open-ssh server, no proxy

Options: after setup: Shared folders (read & write)

(sudo mkdir /mnt/hgfs
sudo vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other)

(sudo dhcpclient ens33)

Get IP address from console, and open terminal for ssh
ssh pprz@
sudo apt-get update
sudo apt-get upgrade

sudo lvm
lvm> lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
lvm> exit
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

sudo apt-get install binutils

...


------------------------------------------------------------------------------
------------------------------------------------------------------------------
unset http_proxy
unset https_proxy

export http_proxy=recherche.enac.fr
export https_proxy=recherche.enac.fr

------------------------------------------------------------------------------
sudo sysctl net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o wlp59s0 -j MASQUERADE
