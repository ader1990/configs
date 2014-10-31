VM_NAME="ader"

FLAT_NET="flat-net"
FLAT_SUBNET="flat-subnet"
GATEWAY="10.1.0.1"
START_IP="10.1.0.100"
END_IP="10.1.0.250"
NETWORK="10.1.0.0/24"

#CREATE PORTS
sudo ovs-vsctl add-port br-eth1 eth1
sudo ovs-vsctl del-port br-int ovs-tap1
sudo ovs-vsctl add-port br-eth1 ovs-tap1

#CREATE FLAT NET
NETID=`neutron net-create $FLAT_NET --shared  --provider:network_type flat --provider:physical_network physnet1 | awk '{if (NR == 6) {print $4}}'`
SUBNETID=`neutron subnet-create --name $FLAT_SUBNET --gateway $GATEWAY --dns-nameserver $GATEWAY --allocation-pool start=$START_IP,end=$END_IP  $FLAT_NET $NETWORK | awk '{if (NR == 11) {print $4}}'`

#BOOT
nova boot --flavor baremetal --image cirros-0.3.2-x86_64-uec --nic net-id=$NETID $VM_NAME

#change /etc/ironic/ironic.conf
#enabled_drivers = fake,pxe_lego,pxe_ssh,pxe_ipmitool

#python /usr/local/bin/neutron-openvswitch-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini &
#python /usr/local/bin/neutron-dhcp-agent --config-file /etc/neutron/neutron.conf --config-file=/etc/neutron/dhcp_agent.ini &
#python /usr/local/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini &

#/usr/bin/python /usr/local/bin/nova-compute --config-file /etc/nova/nova.conf

#/usr/bin/python /usr/local/bin/ironic-conductor --config-file=/etc/ironic/ironic.conf
#/usr/bin/python /usr/local/bin/ironic-api --config-file=/etc/ironic/ironic.conf
