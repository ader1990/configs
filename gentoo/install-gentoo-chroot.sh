#!/bin/bash

set -xe

source /etc/profile
export PS1="(chroot) ${PS1}"

# Mount EFI
mkdir -p /efi
umount "${DISK}p1" || true
mount "${DISK}p1" /efi/

# Sync emerge and select profile
emerge-webrsync
# eselect profile list
eselect profile set 21

#emerge --info | grep ^USE
emerge --oneshot app-portage/cpuid2cpuflags
# cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
emerge --depclean
# locale-gen

# uncomment if you want a daily update
# emerge --update --deep --newuse @world

echo "sys-kernel/installkernel dracut systemd systemd-boot" > /etc/portage/package.use/installkernel

echo "sys-apps/systemd boot" > /etc/portage/package.use/systemd

emerge --oneshot sys-kernel/gentoo-kernel-bin
emerge --oneshot sys-kernel/dracut
emerge --oneshot sys-apps/systemd

emerge --oneshot net-misc/dhcpcd

systemctl preset-all --preset-mode=enable-only

systemctl enable dhcpcd
systemctl enable sshd
systemctl enable getty@tty1.service

bootctl install
bootctl list

# set root / root user/pass
echo "root:P@ssw0rd1gentoo" | chpasswd

umount "${DISK}p1" || true
