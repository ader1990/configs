OLD_PRIVATE_NET="private"
OLD_PRIVATE_SUBNET="private-subnet"
OLD_PUBLIC_NET="public"
EXISTENT_ROUTER="router1"
EXISTENT_FLAT_SUBNET="flat-subnet"

PUBLIC_GATEWAY="10.7.1.1"
PUBLIC_NETWORK="10.7.0.0/16"
FROM_IP="10.7.5.60"
TO_IP="10.7.5.100"

PUBLIC_NETWORK_INTERFACE="eth1"

#DELETE
neutron router-interface-delete $EXISTENT_ROUTER $OLD_PRIVATE_SUBNET
neutron router-gateway-clear $EXISTENT_ROUTER
neutron net-delete $OLD_PRIVATE_NET

#CREATE
ROUTERID=`neutron router-show $EXISTENT_ROUTER | awk '{if (NR == 8) {print $4}}'`
PRIVATE_SUBNET_ID=`neutron subnet-show $EXISTENT_FLAT_SUBNET | awk '{if (NR == 10) {print $4}}'`
neutron router-interface-add $ROUTERID $PRIVATE_SUBNET_ID

neutron subnet-create $OLD_PUBLIC_NET --allocation-pool start=$FROM_IP,end=$TO_IP --gateway $PUBLIC_GATEWAY $PUBLIC_NETWORK --enable_dhcp=False
neutron router-gateway-set $ROUTERID $OLD_PUBLIC_NET

#ADD PORT TO PUBLIC NETOWRK
#sudo ovs-vsctl add-port br-ex $PUBLIC_NETWORK_INTERFACE

