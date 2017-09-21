# install lava server on jessie
# stretch version does not work, as when you try to login in the dashboard you get a csrf error

echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
apt-get update
sudo apt -t jessie-backports -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install lava-server -y
# reboot


echo "set mouse-=a" >> ~/.vimrc
a2dissite 000-default
a2enmod proxy
a2enmod proxy_http
a2ensite lava-server.conf
service apache2 restart


lava-server manage createsuperuser --username cloudbase --email=adi@vla.ro



WORKER_HOSTNAME=`hostname -f`
lava-server manage pipeline-worker --hostname $WORKER_HOSTNAME


echo "{% extends 'qemu.jinja2' %}" >qemu_description
lava-server manage device-dictionary --hostname $WORKER_HOSTNAME --import qemu_description

lava-server manage add-device-type qemu
lava-server manage add-device $WORKER_HOSTNAME --device-type qemu --worker $WORKER_HOSTNAME
