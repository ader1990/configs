FROM_IP=$1
TO_IP=$2
neutron_cmd="neutron"
if [ -n $3 ]; then
    neutron_cmd=$3
fi
NETID1=`$neutron_cmd net-create private --provider:network_type flat --provider:physical_network physnet1 | awk '{if (NR == 6) {print $4}}'`
SUBNETID1=`$neutron_cmd subnet-create private 10.0.1.0/24 --dns_nameservers list=true 8.8.8.8 | awk '{if (NR == 11) {print $4}}'`

ROUTERID1=`$neutron_cmd router-create router | awk '{if (NR == 7) {print $4}}'`

$neutron_cmd router-interface-add $ROUTERID1 $SUBNETID1

EXTNETID1=`$neutron_cmd net-create public --router:external=True | awk '{if (NR == 6) {print $4}}'`
$neutron_cmd subnet-create public --allocation-pool start=$FROM_IP,end=$TO_IP --gateway 10.7.1.1 10.7.0.0/16 --enable_dhcp=False

$neutron_cmd router-gateway-set $ROUTERID1 $EXTNETID1
