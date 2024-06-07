## Automated script to install Gentoo on  a disk device

Base how-to: https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation

### How to use

Note that currently the scripts supports only NVME devices and ARM64 environments.

The script needs to be run from a Gentoo instance that has access to the NVME device. Could be run from any Linux, as long as it has the following binaries available:

  * chroot
  * sgdisk
  * blkdiscard
  * mkfs.vfat
  * mkfs.xfs

```bash
bash install_gentoo.sh /dev/nvme1n1
```

### What the script does:

* erase the disk
* create the /efi and / partitions
* xfs format the / partition
* downloads STAGE_3_URL="https://distfiles.gentoo.org/releases/arm64/autobuilds/20240602T232249Z/stage3-arm64-desktop-systemd-20240602T232249Z.tar.xz"
* mounts the / partition to /mnt/gentoo
* decompresses the STAGE_3 image in /mnt/gentoo
* chroot into /mnt/gentoo and installs:
  * Linux Kernel
  * systemd
  * dracut
  * systemd-boot
  * sshd
* Creates a systemd-boot boot entry
* Enables SSH and sets root's password to: P@ssw0rd1gentoo

