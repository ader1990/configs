start=$1
end=$2

NETID1=`neutron net-create private --provider:network_type flat --provider:physical_network physnet1 | awk '{if (NR == 6) {print $4}}'`
SUBNETID1=`neutron subnet-create private 10.0.1.0/24 --dns_nameservers list=true 8.8.8.8 | awk '{if (NR == 11) {print $4}}'`

ROUTERID1=`neutron router-create router | awk '{if (NR == 7) {print $4}}'`

neutron router-interface-add $ROUTERID1 $SUBNETID1

EXTNETID1=`neutron net-create public --router:external=True | awk '{if (NR == 6) {print $4}}'`
neutron subnet-create public --allocation-pool start=$start,end=$end --gateway 10.7.1.1 10.7.0.0/16 --enable_dhcp=False

neutron router-gateway-set $ROUTERID1 $EXTNETID1
