IMAGE=$1
neutron_cmd='neutron'
key="~/.ssh/id_rsa"


NET_ID=`$neutron_cmd net-show private  | awk '{if (NR == 5) {print $4}}'`
ID=`nova boot --key-name userkey --flavor m1.small --image $IMAGE --security-groups default --nic net-id=$NET_ID ader | awk '{if (NR == 21) {print $4}}'`
echo $ID
FLOATING_IP=`nova floating-ip-create public | awk '{if (NR == 4) {print $2}}'`

sleep 2

echo $FLOATING_IP
nova add-floating-ip $ID $FLOATING_IP

