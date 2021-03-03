sudo killall wpa_supplicant
sudo ifconfig wlan0 up
sudo iw dev wlan0 scan
sudo -i
wpa_supplicant -B -i wlan0 -c <(wpa_passphrase Androidxp pprzpprz)
wpa_supplicant -i wlan0 -c <(wpa_passphrase Androidxp pprzpprz)
sudo dhclient wlan0
