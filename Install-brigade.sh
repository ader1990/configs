#!/bin/bash
#this script should be run as a non root user
# install docker:
exec_with_retry2 () {
    MAX_RETRIES=$1
    INTERVAL=$2

    COUNTER=0
    while [ $COUNTER -lt $MAX_RETRIES ]; do
        EXIT=0
        eval '${@:3}' || EXIT=$?
        if [ $EXIT -eq 0 ]; then
            return 0
        fi
        let COUNTER=COUNTER+1

        if [ -n "$INTERVAL" ]; then
            sleep $INTERVAL
        fi
    done
    return $EXIT
}
exec_with_retry () {
    CMD=$1
    MAX_RETRIES=${2-10}
    INTERVAL=${3-0}

    exec_with_retry2 $MAX_RETRIES $INTERVAL $CMD
}
exec_with_retry 'sudo apt-get update' 3 2
exec_with_retry 'sudo apt-get install -y docker.io' 3 2

# configure kubernetes apt repo:

exec_with_retry 'sudo apt-get install -y apt-transport-https' 3 2
exec_with_retry 'curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg' 3 2 | sudo apt-key add -
sudo touch /etc/apt/sources.list.d/kubernetes.list
sudo chmod 777 /etc/apt/sources.list.d/kubernetes.list
sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
exec_with_retry 'sudo apt-get update' 3 2

# install kubernetes:

exec_with_retry 'sudo apt-get install -y kubelet kubeadm kubernetes-cni' 3 2

# disable swap if exists (check: cat /proc/swaps)

swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# initiate kubeadm (replace --apiserver-advertise-address with the IP of your host):

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(ifconfig eth0 | grep 'inet addr:' | cut -d ':' -f2 | cut -d ' ' -f1)

# configure environment variables:

sudo cp /etc/kubernetes/admin.conf $HOME/
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
echo "export KUBECONFIG=$HOME/admin.conf" | tee -a ~/.bashrc

# configure pod network:

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml

# taint master (so that containers can run on master):

kubectl taint nodes --all node-role.kubernetes.io/master-

# install helm:
# download desired version from https://github.com/kubernetes/helm/releases:

exec_with_retry 'wget https://storage.googleapis.com/kubernetes-helm/helm-v2.7.0-linux-amd64.tar.gz' 3 2
tar -zxf helm-v2.7.0-linux-amd64.tar.gz

# copy binaries into PATH:

sudo cp linux-amd64/helm /usr/bin/

# initiate helm:

helm init

# create the binaries for brigade

exec_with_retry 'sudo apt-get update' 3 2
exec_with_retry 'sudo apt-get -y upgrade' 3 2
wget https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz
tar -xvf go1.9.2.linux-amd64.tar.gz
sudo mv go /usr/local
export GOROOT=/usr/local/go
echo "export GOROOT=/usr/local/go" | tee -a ~/.bashrc
mkdir $HOME/work
sudo cp -r /usr/local/go $HOME/work
export GOPATH=$HOME/work
echo "export GOPATH=$HOME/work" | tee -a ~/.bashrc
export PATH=$GOPATH/bin:$GOPATH/go/bin:$GOROOT/bin:$PATH
mkdir -p $(go env GOPATH)/src/github.com/Azure 
git clone https://github.com/Azure/brigade $(go env GOPATH)/src/github.com/Azure/brigade
pushd $(go env GOPATH)/src/github.com/Azure/brigade
sudo apt install -y npm
sudo env PATH=$PATH GOROOT=$GOROOT GOPATH=$GOPATH make bootstrap build
sudo cp $HOME/work/src/github.com/Azure/brigade/bin/* /usr/bin
popd
# install brigade:
# clone the repo:

git clone https://github.com/Azure/brigade.git
pushd ./brigade

# install brigade:

kubectl create clusterrolebinding --user system:serviceaccount:kube-system:default kube-system-cluster-admin --clusterrole cluster-admin
kubectl create clusterrolebinding --user system:serviceaccount:default:brigade-brigade-ctrl kube-system-cluster-admin1 --clusterrole cluster-admin
kubectl create clusterrolebinding --user system:serviceaccount:default:brigade-brigade-ctrl kube-system-cluster-admin11 --clusterrole cluster-admin
kubectl create clusterrolebinding --user system:serviceaccount:default:default kube-system-cluster-admin111 --clusterrole cluster-admin

helm install --name brigade ./charts/brigade
popd

#add brigade project
#helm install --name my-project ./charts/brigade-project -f myvalues.yaml