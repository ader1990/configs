### Initial document how-to, the starting point
https://wiki.gentoo.org/wiki/User:Dlan/RISC-V/TH1520#Host_Env_Setup

### Install Gentoo upstream on an AMD64 box was done using the script from this folder

### prepare the env - install the toolings
```bash
emerge dev-vcs/git
emerge app-misc/screen
```

### prepare the crossdev repos (instructions from @chewie)

```bash
mkdir -p /var/db/repos/crossdev/{metadata,profiles}
echo crossdev > /var/db/repos/crossdev/profiles/repo_name
cat > /var/db/repos/crossdev/metadata/layout.conf <<EOF
masters = gentoo
thin-manifests = true
cache-formats = md5-dict
EOF
cat > /etc/portage/repos.conf/crossdev.conf <<EOF
[crossdev]
priority = 1001
location = /var/db/repos/crossdev
sync-type =
EOF
```

### prepare the crossdev env

```
emerge --ask sys-devel/crossdev
crossdev --target riscv64-unknown-linux-gnu
```

### build uboot

```
git clone --depth=1 -b th1520 https://github.com/revyos/thead-u-boot u-boot
pushd u-boot
alias rvmake='make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j30 '
# use the 16g target for the 16GB RAM board
rvmake distclean && rvmake light_lpi4a_16g_defconfig && rvmake
ls -liath u-boot-with-spl.bin
popd
```

### build kernel

```
git clone --depth=1 -b lpi4a https://github.com/revyos/thead-kernel kernel
pushd kernel
rvmake revyos_defconfig
# to fix the pahole issue
emerge -av dev-util/pahole
rvmake Image
ls -liath ./arch/riscv/boot/Image
rvmake modules
ls -liath modules
rvmake dtbs
ls -liath ./arch/riscv/boot/dts/thead/light-lpi4a-16gb.dtb

git clone https://github.com/revyos/opensbi -b th1520-v1.4
pushd opensbi
rvmake PLATFORM=generic FW_PIC=y
ls build/platform/generic/firmware/fw_dynamic.bin
popd

# get the two closed source light_aon_fpga and light_c906_audio from
# https://git.beagleboard.org/beaglev-ahead/xuantie-ubuntu/-/tree/master/bins
# https://lore.kernel.org/buildroot/20230821234359.06008b73@windsurf/T/
# light_aon_fpga.bin: "aon" is an `Always On` fpga binary used for power
# management... If you don't have this, the board will boot, but things
# like cpufreq don't work..
# light_c906_audio.bin: Probably Audio, never really tested it too much...


# this is how a bootfs should look like
# Image           light-lpi4a-ddr2G.dtb  light_aon_fpga.bin
# fw_dynamic.bin  light-lpi4a.dtb        light_c906_audio.bin
# kernel-release  light-lpi4a_2Ghz.dtb   lost+found
popd
```

### get the stage 3 built image
https://mirror.bytemark.co.uk/gentoo/releases/riscv/autobuilds/current-stage3-rv64_lp64d-systemd/stage3-rv64_lp64d-systemd-20240621T170422Z.tar.xz

### how to get Gentoo booting on LicheePi4A


Use the uboot.bin/boot.ext4 from the official licheepi:

   * wget https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20240601/u-boot-with-spl-lpi4a-16g.bin
   * wget https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20240601/boot-lpi4a-20240601_180941.ext4.zst

Create the root.ext4 according to the requirements of the above boot-lpi4a-20240601_180941.ext4.zst:

```bash
dd if=/dev/zero of=root.ext4 bs=1M count=2048 && mkfs.ext4 -U 80a5a8e9-c744-491a-93c1-4f4194fd690a -b 4096 -L root root.ext
mount -o loop root.ext4 /mnt/gentoo/
tar Jxvf stage3-rv64_lp64d-systemd-20240621T170422Z.tar.xz -C /mnt/gentoo/
vim /mnt/gentoo//etc/fstab
#-> add 80a5a8e9-c744-491a-93c1-4f4194fd690a to /etc/fstab
vim /mnt/gentoo/etc/passwd
alias rvmake='make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j30 '
cd ../../kernel/
ls
rvmake modules_install INSTALL_MOD_PATH=/mnt/gentoo/
# flash and boot
# user root has no password

After flashing and rebooting (TBD before and not after):

  * resize2fs mmc block partition4
  * set ip / network using ifconfig
  * emerge-webrsync
  * emerge and enable net-misc/dhcpcd, enable ssh, set ssh root/pass auth, create users


