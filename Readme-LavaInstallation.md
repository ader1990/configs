# LAVA Master on Linux

## Installation instructions on Hyper-V

### Environment preparation
Download and gunzip Debian Jessie image which runs on Hyper-V from:

  https://images.validation.linaro.org/kvm/standard/large-stable-6.img.gz

#### ![#f03c15](https://placehold.it/15/f03c15/000000?text=+) Do not run apt-get update before changing the sources list documented bellow! ![#f03c15](https://placehold.it/15/f03c15/000000?text=+)

Use qemu-img.exe to convert the image to a valid vhdx that can be used for Hyper-V using:
https://cloudbase.it/qemu-img-windows/

Create a VM with at least 4GB RAM and 4CPU, using as disk the previously obtained VHDX.

Note1: The current Debian stable versions are Jessie and Stretch.
Stretch version does not work, as when you try to login in the dashboard you get a CSRF error.

Note2: After you create and start the VM, connect in the console with user root (no password).
The image does not have SSH server installed. The SSH server installation is out of the scope of this tutorial.

Note3: On the Jessie version, the LAVA package version is 16.12 (16.12 is also the github repo tag)


### Installation instructions
Run the following commands:
```bash 
# DO NOT run apt-get update before changing the sources list!
# If you run it, it will set the Debian Stretch repos and the installation of LAVA will fail.
sed -i -e "s/stable/jessie/g" /etc/apt/sources.list
echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
apt-get update
# this command is interactive and needs user input. Select all the default values if prompted.
DEBIAN_FRONTEND=noninteractive apt -t jessie-backports --assume-yes -y install lava-server
reboot
```

After the reboot run the following commands:
```bash
echo "set mouse-=a" >> ~/.vimrc
a2dissite 000-default
a2enmod proxy
a2enmod proxy_http
a2ensite lava-server.conf
service apache2 restart
```
## Configuration instructions

```bash
# this command is interactive and requires to insert the password twice.
lava-server manage createsuperuser --username cloudbase --email=cloud@mail.com

WORKER_HOSTNAME=`hostname -f`

# this command will fail if the hostname of the worker is the same as the master hostname
# as the master is already added as a slave (is called the master worker).
# Continue to run the rest of the commands.
lava-server manage pipeline-worker --hostname $WORKER_HOSTNAME

echo "{% extends 'qemu.jinja2' %}" > qemu_dictionary
lava-server manage device-dictionary --hostname $WORKER_HOSTNAME --import qemu_dictionary

lava-server manage add-device-type qemu
lava-server manage add-device $WORKER_HOSTNAME --device-type qemu --worker $WORKER_HOSTNAME
```

## Run instructions

At the `http://<lava-master-ip>/`, you can login using the username and password defined above.

Submit a job from the Scheduler tab, using this yaml (you do not need to change anything for it work):

https://validation.linaro.org/static/docs/v2/examples/test-jobs/qemu-pipeline-first-job.yaml

## Public documentation
https://validation.linaro.org/static/docs/v2/installing_on_debian.html#installing-on-debian-stretch


## HACKING

## LAVA Slave running on Linux with Hyper-V booting method

### Requirements
  * Windows host: Hyper-V module installed.
  * Windows host: WinRM enabled and configured to use password authentication with SSL transport.
  * Windows host: Binaries required in the `${ENV:path}`.
    * ssh-keygen.exe (included if the Windows git client is installed: https://git-scm.com/download/win).
    * mkisofs.exe (can be downloaded from this repo).
  * Shared storage between the LAVA Slave and the Windows host. Given the shared storage address is `\\shared\storage\lava`:
    * On the LAVA Slave: `\\shared\storage\lava` should be already mounted to `/var/lib/lava/dispatcher/tmp`.
    * On the Windows host: `\\shared\storage\lava` will be mounted by the lis-pipeline scripts to a convenient location.

### Installation instructions

#### LAVA Windows Hyper-V node

Make sure you have WinRM https enabled. You can use this script to enable WinRM:
```powershell
https://github.com/ader1990/configs/blob/master/configure-winrm-http-https.ps1
```

Make sure you have downloaded the mkisofs.exe from https://github.com/ader1990/configs/blob/master/mkisofs.exe .

Make sure you have the latest lis pipeline scripts:

```powershell
git clone https://github.com/ader1990/lis-pipeline
cd lis-pipeline
git checkout dirty_winrm
```

Remember the paths where you have downloaded the mkisofs.exe and lis-pipeline scripts,
as you will need them to update the hyper-v device dictionary from the LAVA machine.

#### LAVA Slave

Get the Python sources:
```bash
apt-get -y install python-pip
pip install pywinrm

git clone https://github.com/ader1990/lava-dispatcher

cd lava-dispatcher
git checkout hyperv_booting_method

python setup.py install
service lava-slave restart
```

Create a Hyper-V device dictionary file at this path on the LAVA Master:
```bash
/etc/lava-server/dispatcher-config/device-types/hyperv.jinja2
```

The content of this file should be:
```yaml
{% extends 'base.jinja2' %}
{% block body %}
device_type: hyperv

actions:
  deploy:
    methods:
      image:
        parameters:
          guest:
            size: 1
            interface: 1
  boot:
    methods:
      hyperv:
        parameters:
          options:
            shared_storage_path: '\\shared\storage\path'
            mkisofs_path: 'C:\bin\mkisofs.exe'
            lis_pipeline_scripts_path: 'C:\lis-pipeline\scripts\lis_hyperv_platform\'
            winrm:
              user: "hyper-v-host-username"
              password: "hyper-v-host-user-password"
              ip: "hyper-v-host-ip"
{% endblock %}

```

Make sure you replace the hyperv parameters options with your specific data.

Update your worker dictionary:

```bash
lava-server manage add-device-type hyperv
echo "{% extends 'hyperv.jinja2' %}" > hyperv_dictionary
lava-server manage device-dictionary --hostname $WORKER_HOSTNAME --import ./hyperv_dictionary
```

Install and configure the SMB share:
```bash
apt-get -y install samba cifs-utils

# this configs of SAMBA are for testing purposes only
# as they are very, very loose
mkdir /var/www/html/samba
chmod -R 777 /var/www/html/samba/
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Add to /etc/samba/smb.conf the following lines
cat <<EOT >> /etc/samba/smb.conf
[lava]
   comment = LAVA shared storage
   path = /var/www/html/samba
   browseable = yes
   read only = no
   guest ok = yes
EOT
service smbd restart
mount //$(hostname)/lava /var/lib/lava/dispatcher/tmp
```

### Run instructions
To be added

## LAVA Slave on Windows (Obsolete)

### Installation instructions
Use a Python 2.7 bundle from cloudbase-init.

Install latest pexpect from github: https://github.com/pexpect/pexpect .

Install the lzma wheel: pip install -i https://pypi.anaconda.org/carlkl/simple backports.lzma .

### Run instructions
```powershell
python.exe .\lava\dispatcher\lava-dispatcher-slave --master tcp:/<lava-master-ip>:5556 `
    --socket-addr tcp://<lava-master-ip>:5555  --log-file ./lava.log
```
