#added pxe_lego driver
#changed in /etc/ironic/ironic.conf : enabled_drivers = pxe_lego

#how to add a node:

driver="pxe_lego"
lego_ev3_ip="10.0.1.1"
lego_ev3_port="A"

IRONIC_VM_SPECS_CPU="4"
IRONIC_VM_SPECS_RAM="8192"
IRONIC_VM_SPECS_DISK="200" 

MAC="C0:3F:D5:64:C9:94"
#MAC="C9:3F:D5:64:C9:94"

kernel_full_id=`nova flavor-show baremetal | awk '{if (NR == 7) {print $7}}'`
pxe_deploy_kernel=`echo ${kernel_full_id:1:36}`

ramdisk_full=`nova flavor-show baremetal | awk '{if (NR == 7) {print $9}}'`
pxe_deploy_ramdisk=`echo ${ramdisk_full:1:36}`

CHASSIS_ID=`ironic chassis-list | awk '{if (NR == 4) {print $2}}'`

NODE=$(ironic node-create --chassis_uuid $CHASSIS_ID -d $driver -i lego_ev3_address=$lego_ev3_ip -i lego_ev3_port=$lego_ev3_port -p cpus=$IRONIC_VM_SPECS_CPU -p memory_mb=$IRONIC_VM_SPECS_RAM -p local_gb=$IRONIC_VM_SPECS_DISK -p cpu_arch=x86_64| grep ' uuid ' | awk '{print $4}')

ironic port-create -n $NODE -a $MAC

ironic node-update $NODE add driver_info/pxe_deploy_kernel=$pxe_deploy_kernel
ironic node-update $NODE add driver_info/pxe_deploy_ramdisk=$pxe_deploy_ramdisk

ironic node-show $NODE


