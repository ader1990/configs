## Install Debian on Sipeed Lichee Pi4A

### Prerequisites:

  * Sipeed Lichee Pi4A
  * AMD64 box
  * USB-C to USB compatible for AMD64 box

Read docs:

  * https://wiki.sipeed.com/hardware/en/lichee/th1520/lpi4a/1_intro.html
  * https://www.armbian.com/licheepi-4a/
  * https://dl.sipeed.com/shareURL/LICHEE/licheepi4a/07_Tools or https://github.com/chainsx/thead-u-boot/releases

### How to install the Sipeed Debian based on Bookworm:

 * Connect the LicheePi 4A via the USB-C cable to the AMD64 box
 * Install and download requirements on the AMD64 box
   * fastboot -> download burn_tools.zip from https://dl.sipeed.com/shareURL/LICHEE/licheepi4a/07_Tools manually
     as it needs captcha, copy it to the amd64 box and then unzip it
     ```bash
     cd burn_tools/linux
     chmod 777 fastboot
     ./fastboot devices -> should show nothing
     ```
 * Connect the LicheePi 4A via the USB-C cable to the AMD64 box by pressing the BOOT button
   ```bash
   sudo lsusb | grep -i t-head # Bus 001 Device 009: ID 2345:7654 T-HEAD USB download gadget
   sudo ./fastboot devices -> should show `????????????    Android Fastboot`
    ```
 * download https://github.com/chainsx/thead-u-boot/releases/download/20231121-1721/lpi4a-16gb-u-boot-with-spl.bin
   wont be used, as there is a newer one: wget https://github.com/chainsx/thead-u-boot/releases/download/20231121-1721/lpi4a-16gb-u-boot-with-spl.bin
 * get the latest image from https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20240601/
   ```bash
   mkdir -p images && cd images
   wget https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20240601/u-boot-with-spl-lpi4a-16g.bin
   wget https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20240601/boot-lpi4a-20240601_180941.ext4.zst
   wget https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20240601/root-lpi4a-20240601_180941.ext4.zst
   unzstd boot-lpi4a-20240601_180941.ext4.zst
   unzstd root-lpi4a-20240601_180941.ext4.zst
   cd ..
   sudo ./fastboot devices
   sudo ./fastboot flash ram ./images/u-boot-with-spl-lpi4a-16g.bin
   sudo ./fastboot reboot
   sleep 10
   sudo ./fastboot devices
   sudo ./fastboot flash uboot ./images/u-boot-with-spl-lpi4a-16g.bin
   sudo ./fastboot flash boot ./images/boot-lpi4a-20240601_180941.ext4
   sudo ./fastboot flash root ./images/root-lpi4a-20240601_180941.ext4
   ```
  * press RESET key and you should be able to login with sipeed:licheepi

Apt repos:

```
deb https://mirror.iscas.ac.cn/revyos/revyos-gles-21/ revyos-gles-21 main
deb https://mirror.iscas.ac.cn/revyos/revyos-base/ sid main contrib non-free non-free-firmware
deb https://mirror.iscas.ac.cn/revyos/revyos-kernels/ revyos-kernels main
deb https://mirror.iscas.ac.cn/revyos/revyos-addons/ revyos-addons main

Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble noble-updates noble-backports
Components: main universe restricted multiverse
#Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

## Ubuntu security updates. Aside from URIs and Suites,
## this should mirror your choices in the previous section.
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble-security
Components: main universe restricted multiverse
#Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

deb http://deb.debian.org/debian trixie main non-free-firmware
deb http://deb.debian.org/debian-security/ trixi-security main non-free-firmware
deb http://deb.debian.org/debian trixie-updates main non-free-firmware

```

Install Docker and others:
  * sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 871920D1991BC93
  * sudo apt update
  * sudo apt upgrade
  * sudo apt dist-upgrade
  * sudo apt autoremove
  * sudo apt install docker.io docker-compose-v2

Enjoy!
