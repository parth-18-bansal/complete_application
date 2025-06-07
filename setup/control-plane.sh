#!/bin/bash

# tailscale install for the networking between the nodes
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Open the required ports
sudo ufw enable

sudo ufw allow 22/tcp
sudo ufw allow 6443/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10259/tcp
sudo ufw allow 10257/tcp
sudo ufw allow 2379/tcp
sudo ufw allow 2380/tcp

# swap disabling
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Pods Network Filtering and Container Storage Setup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
<<comment
br_netfilter allows the kernel's netfilter to filter the traffic in pod networks but we have to set explictly the sysctl paramters so that traffic of the pod network pass through the iptables.

here first two to pass the ipv4 and ipv6 to pass through the iptable
 
last allow the node to act as router. By default ubuntu only accept those packets that has destination as it's ip. But now it can accept
those packet also and route it to the correct ip. Like if any pod sent a packet to a pod in the other node then it other node can accept
that packet and route to the pod that is running on it.
comment

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1     
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Verify that the br_netfilter, overlay modules are loaded by running the following commands:
lsmod | grep br_netfilter
lsmod | grep overlay

# Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward


# Installing containerd and configuring it.
curl -LO https://github.com/containerd/containerd/releases/download/v1.7.14/containerd-1.7.14-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.14-linux-amd64.tar.gz
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system/
sudo mv containerd.service /usr/local/lib/systemd/system/
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Check that containerd service is up and running
systemctl status containerd

# installing runc
curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# Install the CNI Plugins
<<comment
These plugins contain the bridges, loopback, host-local, portmap, firewall etc. And calico use these tool to create the pod network.
comment

curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.0.tgz

# Install the Kubeadm, kubectl, kubelet
sudo apt-get update

# this so that curl can request the https links also
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# This is the key, so that we can make sure that we are installing the official packages only
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=1.29.6-1.1 kubeadm=1.29.6-1.1 kubectl=1.29.6-1.1 --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version
kubelet --version
kubectl version --client

# configuring the crictl to work with the containerd
<<comments
it configured the crictl then when we ask it to inspect pods, containers, or images, it talk to containerd through its socket 
at /var/run/containerd/containerd.sock
comments

sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock

# Initialising the Control Plane
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=100.104.197.42 --node-name master-node

# Copy the kubeadm join command

# Setting up the kubectl through the kubeconfig file
<<comments
it tell the kubectl to how to access the apiserver
comments

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# installing the yaml and deploying the calico pods in the control plane
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml

curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml -O

kubectl apply -f custom-resources.yaml

