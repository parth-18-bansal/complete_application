#!/bin/bash

# tailscale install for the networking between the nodes
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Open the required ports
sudo ufw enable

sudo ufw allow 22/tcp
sudo ufw allow 6643/tcp
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
# br_netfilter allows the kernel's netfilter to filter the traffic in pod networks but we have to set explictly the sysctl paramters so that traffic of the pod network pass through the iptables.

# here first two to pass the ipv4 and ipv6 to pass through the iptable
# last allow the node to act as router.
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1     
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF