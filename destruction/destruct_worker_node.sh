#!/bin/bash

echo "[1/9] Resetting kubeadm (if joined to cluster)..."
sudo kubeadm reset -f

echo "[2/9] Stopping and removing kubelet..."
sudo systemctl stop kubelet
sudo systemctl disable kubelet
sudo apt-mark unhold kubelet kubeadm kubectl
sudo apt-get purge -y kubelet kubeadm kubectl
sudo rm -rf /etc/systemd/system/kubelet.service.d
sudo rm -rf /etc/systemd/system/kubelet.service
sudo systemctl daemon-reload

echo "[3/9] Removing Kubernetes config and data..."
sudo rm -rf ~/.kube
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd

echo "[4/9] Removing containerd and runc..."
sudo systemctl stop containerd
sudo systemctl disable containerd
sudo rm -rf /usr/local/bin/containerd*
sudo rm -rf /usr/local/lib/systemd/system/containerd.service
sudo rm -rf /etc/containerd /var/lib/containerd
sudo rm -f /usr/local/sbin/runc

echo "[5/9] Removing CNI plugins..."
sudo rm -rf /opt/cni /etc/cni /var/lib/cni

echo "[6/9] Restoring swap..."
sudo sed -i '/ swap / s/^#//' /etc/fstab
sudo swapon -a

echo "[7/9] Cleaning sysctl and module settings..."
sudo rm -f /etc/sysctl.d/k8s.conf
sudo sysctl --system
sudo rm -f /etc/modules-load.d/k8s.conf

# Unload kernel modules (optional, may not work if in use)
sudo modprobe -r br_netfilter 2>/dev/null || true
sudo modprobe -r overlay 2>/dev/null || true

echo "[8/9] Cleaning up downloaded setup files..."
rm -f containerd-1.7.14-linux-amd64.tar.gz
rm -f containerd.service
rm -f runc.amd64
rm -f cni-plugins-linux-amd64-v1.5.0.tgz

echo "[9/9] Cleaning APT sources and cache..."
sudo rm -f /etc/apt/sources.list.d/kubernetes.list
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo rm -f /home/parth/join-config.yaml
sudo apt-get autoremove -y
sudo apt-get clean

echo "Worker node has been reset to a clean state."
