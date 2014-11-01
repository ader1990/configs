FLAVOR_NAME="windows1"
INITRAMFS_IMAGE="ir-deploy.initramfs"
KERNEL_IMAGE="ir-deploy.kernel"

nova flavor-create $FLAVOR_NAME 12 8192 200 4
INITRAMFS_ID=`glance image-show $INITRAMFS_IMAGE |  awk '{if (NR == 9) {print $4}}'`
KERNEL_ID=`glance image-show $KERNEL_IMAGE |  awk '{if (NR == 9) {print $4}}'`
nova flavor-key $FLAVOR_NAME set "cpu_arch"="x86_64" "baremetal:deploy_kernel_id"="$KERNEL_ID" "baremetal:deploy_ramdisk_id"="$INITRAMFS_ID"


