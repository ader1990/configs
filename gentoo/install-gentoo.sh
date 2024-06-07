#!/bin/bash

set -xe -o pipefail
BASEDIR=$(dirname $0)
BASEDIR=$(readlink -f $BASEDIR)

MOUNT_POINT="/mnt/gentoo"

function install_deps() {
  # for git
  emerge dev-vcs/git -n
  # for blkdiscard
  emerge sys-apps/util-linux -n
  # for sgdisk
  emerge sys-apps/gptfdisk -n
  # mkfs.vfat
  emerge sys-fs/dosfstools -n
  # mksfs.xfs
  emerge sys-fs/xfsprogs -n
}


function cleanup_disk () {
  disk=$1
  echo "Cleaning up disk $disk"
  umount_fs $disk
  sgdisk --zap-all $disk
  blkdiscard $disk
  sync
}

function create_partitions() {
  disk=$1
  echo "Create partitions on $disk"

fdisk $disk <<\EndOfAnswers
g
w
q
EndOfAnswers

fdisk $disk <<\EndOfAnswers
n
1
2048
+1G
t
1
x
u
c12a7328-f81f-11d2-ba4b-00a0c93ec93b
r
w
q
EndOfAnswers

fdisk $disk <<\EndOfAnswers
n
2
2099200

t
2
27
x
u
2
4f68bce3-e8cd-4db1-96e7-fbcaf984b709
r
w
q
EndOfAnswers
}

function create_filesystems() {
  disk=$1
  mkfs.vfat -F 32 "${disk}p1"
  mkfs.xfs "${disk}p2"
}

function mount_fs() {
  disk=$1
  mkdir --parents $MOUNT_POINT
  mkdir --parents "${MOUNT_POINT}/efi"
  umount $MOUNT_POINT || true
  mount "${disk}p2" $MOUNT_POINT

  pushd $MOUNT_POINT
    wget https://distfiles.gentoo.org/releases/arm64/autobuilds/20240602T232249Z/stage3-arm64-desktop-systemd-20240602T232249Z.tar.xz
    tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
  popd

  mount --types proc /proc "${MOUNT_POINT}/proc"
  mount --rbind /sys "${MOUNT_POINT}/sys"
  mount --make-rslave "${MOUNT_POINT}/sys"
  mount --rbind /dev "${MOUNT_POINT}/dev"
  mount --make-rslave "${MOUNT_POINT}/dev"
  mount --bind /run "${MOUNT_POINT}/run"
  mount --make-slave "${MOUNT_POINT}/run"
}

function run_chroot () {
  disk=$1
  echo "DISK=${disk}" >> "${MOUNT_POINT}/etc/profile"
  cp "${BASEDIR}/install-gentoo-chroot.sh" "${MOUNT_POINT}/"
  chroot "${MOUNT_POINT}" "/install-gentoo-chroot.sh"
}

function create_fstab() {
  disk=$1
  partuuid_efi=$(blkid | grep "${disk}p1" | awk '{print $NF}')
  partuuid_root=$(blkid | grep "${disk}p2" | awk '{print $NF}')
  echo "${partuuid_efi}   /efi        vfat    umask=0077     0 2" >> "${MOUNT_POINT}/etc/fstab"
  echo "${partuuid_root}   /            xfs    defaults,noatime              0 1" >> "${MOUNT_POINT}/etc/fstab"
}

function umount_fs() {
  disk=$1
  (grep "${MOUNT_POINT}/sys" /proc/mounts | cut -f2 -d" " | sort -r | xargs umount) || true
  (grep "${MOUNT_POINT}/dev" /proc/mounts | cut -f2 -d" " | sort -r | xargs umount) || true

  umount "${MOUNT_POINT}/proc" || true
  umount "${MOUNT_POINT}/sys" || true
  umount "${MOUNT_POINT}/dev" || true
  umount "${MOUNT_POINT}/run" || true

  umount $MOUNT_POINT || true
  umount "${disk}p1" || true
  umount "${disk}p2" || true
}


function main () {
  disk=$1
  echo "Started installing Gentoo on disk $disk"
  cleanup_disk $disk
  create_partitions $disk
  create_filesystems $disk
  mount_fs $disk
  run_chroot $disk
  create_fstab $disk
  umount_fs $disk
}

disk=$1

if [[ "$disk" == "" ]];then
  echo "Please set the disk device where gentoo should be installed"
  exit 1
fi

#install_deps
main $disk

