# complete_application
complete application deployed using k8s

# Setup
1) Ubuntu Pc --> worker node
2) Ubuntu VM ( 4GB, 25GB, 4CPU) --> control plane node

# set the hostname of the machines
sudo hostnamectl set-hostname master-node/worker-node

# setup the tailscale
1) create the tailscale free account
2) install the tailnet on the
     ubuntu: curl -fsSL https://tailscale.com/install.sh | sh
     windows: From website
3) sudo tailscale up, connect the devices
4) Make sure the magicdns is enabled.

   ![image](https://github.com/user-attachments/assets/26e117e6-ee36-432a-9a01-84a45aece391)

# Disable the swap
1) to avoid the confusion for the kubernetes or scheduler of the k8s disable the swap temporary or permanently.
   sudo swapoff -a
   sudo sed -i '/ swap / s/^/#/' /etc/fstab   [for permanent disable]

   You can check whether swap is on or off, and if you off it then you can also start it again.

2) Load Required Kernel Modules "br_netfilter"
   cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
   br_netfilter
   EOF

   sudo modprobe br_netfilter

# kubernetes networking
     cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
     net.bridge.bridge-nf-call-ip6tables = 1
     net.bridge.bridge-nf-call-iptables = 1
     EOF

     sudo sysctl --system

# Install the containerd
sudo apt install containerd --> this will create and manage the containers

# Configuring the Containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# install these if not installed
sudo apt install -y apt-transport-https curl --> apt-transport-https, so that apt can connect to secure package repositories that uses https. curl to downlaod data from the internet.

# configuring apt things so that apt install official package only
This save a gpg key which apt used to verify that it is downloading a official kubernetes related packages.
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.asc > /dev/null

Here we are telling the apt from which repository (APT repositories) to download the k8s related packages.
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# now you can securly installs the k8s packages
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

It hold the upgradation of the packages, so now these packages will not be upgrade by apt-upgrade. this is because, sometimes things get break when new version of some package upgrade automatically.

sudo apt-mark hold kubelet kubeadm kubectl [use with caution]

we can remove the hold or check the hold packages

sudo apt-mark unhold kubelet kubeadm kubectl

apt-mark showhold

# add net.ipv4.ip_forward = 1 in k8.conf
This if for enabling the ip forwarding. add this in each node, this enable the node to route the request.

# sudo kubeadm init --pod-network-cidr=10.244.0.0/16
run this in the master node to start the control plane. Pods get ip according to the pod-network-cidr attribute

this command setup:
a) apiserver
b) scheduler
c) controller-manager
d) etcd
e) Generates the certificates and config files.

# To setup the kubectl, so that it know which cluster it is connected to.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Installation ssh on the vm ubuntu (Optional)
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# If you want to run kubectl commands from the other machines or ubuntu worker node (optional)
scp username@tailscale-ip-of-VM:/home/ubuntu/.kube/config ~/.kube/config-cluster

{if initially have the .kube folder in the machine from which you want to run the kubectl commands then merge all the config files in the .kube folder}

export KUBECONFIG=~/.kube/config:~/.kube/config-cluster

kubectl config view --flatten > ~/.kube/config-merged

mv ~/.kube/config-merged ~/.kube/config

# for doing ssh between the machines (optional)
ssh username@tailscale-ip-of-VM

















