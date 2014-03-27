#prepare-rdo
START_IP=$1
END_IP=$2
neutron_cmd=$3
key="~/.ssh/id_rsa"
#sudo apt-get install vim git -y
sudo yum install vim git -y

if [ -f $key ];
then
        ssh-keygen -f $key -t rsa -N ''
fi
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default ICMP -1 -1 0.0.0.0/0
nova secgroup-add-rule default ICMP 8 8 0.0.0.0/0

nova keypair-add userkey --pub_key $key".pub"

wget https://raw.githubusercontent.com/ader1990/configs/master/create-networks-openstack.sh --no-check-certificate
bash create-networks-openstack.sh $START_IP $END_IP $neutron_cmd

git clone https://github.com/cloudbase/ci-overcloud-init-scripts.git
glance image-create --property hypervisor_type=hyperv --name cirros-vhdx --disk-format vhd --container-format bare --file ci-overcloud-init-scripts/scripts/devstack_vm/cirros.vhdx
glance image-create --property hypervisor_type=hyperv --name cirros-vhd --disk-format vhd --container-format bare --file ci-overcloud-init-scripts/scripts/devstack_vm/cirros.vhd

wget http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img
glance image-create --property hypervisor_type=qemu --name cirros-qcow2 --disk-format qcow2 --container-format bare --file cirros-0.3.1-x86_64-disk.img

NET_ID=`$neutron_cmd net-list  | awk '{if (NR == 5) {print $2}}'`
nova boot --key-name userkey --flavor m1.small --image cirros-qcow2 --security-groups default --nic net-id=$NET_ID ader

sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
sudo iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited
sudo service iptables save
