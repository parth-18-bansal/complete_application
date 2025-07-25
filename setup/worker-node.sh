#!/bin/bash

# swap one
sudo swapoff -a



# Forwarding IPv4 and letting iptables see bridged traffic
# ----------------------------------------------------------------------------------------------------------------------------------------------
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
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




# Install container runtime
# ----------------------------------------------------------------------------------------------------------------------------------------------
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

# install runc
curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc




# install cni plugin
# -------------------------------------------------------------------------------------------------------------------------------------------------------
curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.0.tgz




# install kubeadm kubelet kubectl
# ---------------------------------------------------------------------------------------------------------------------------------------------------------
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=1.29.6-1.1 kubeadm=1.29.6-1.1 kubectl=1.29.6-1.1 --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version
kubelet --version
kubectl version --client

# *************************************************************************
# # 4. Get Tailscale IP
# TAILSCALE_IP=$(tailscale ip -4 | head -n 1)

# # 5. Configure kubelet to use Tailscale IP
# cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# [Service]
# Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml --node-ip=$TAILSCALE_IP"
# EOF

# # 6. Reload and restart kubelet
# sudo systemctl daemon-reexec
# sudo systemctl daemon-reload
# sudo systemctl restart kubelet

# # 7.Show IP confirmation
# echo "Tailscale IP set for kubelet: $TAILSCALE_IP"
# ****************************************************************************************************************

# Configure crictl to work with containerd
echo " Configuring the crictl... "
sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock


# joing the worker-node
# ---------------------------------------------------------------------------------------------------------------------------------------------------------

# touch join-config.yaml

# nano ./join-config.yaml

# apiVersion: kubeadm.k8s.io/v1beta4
# kind: JoinConfiguration
# discovery:
#   bootstrapToken:
#     token: nu4dec.mmm...<token from the join command>
#     apiServerEndpoint: <tailscale-ip-control-plane>:6443
#     caCertHashes:
#       - sha256:12344...<cert from the join command>
# nodeRegistration:
#   name: parth-vostro-3578
#   kubeletExtraArgs:
#     node-ip: <tailscale-ip-worker-node>




# ----------------------------------------------------------------------------------------------------------------------------------------------------------

# if token expiries (time is 24 hrs) or lost the token command to generate the join command
#kubeadm token create --print-join-command