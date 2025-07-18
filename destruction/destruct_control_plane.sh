# Reset the kuberenetes cluster
sudo kubeadm reset -f
sudo systemctl stop kubelet
sudo systemctl disable kubelet
sudo apt-get purge -y kubelet kubeadm kubectl
sudo apt-mark unhold kubelet kubeadm kubectl
sudo rm -rf ~/.kube
sudo rm -rf /etc/kubernetes /var/lib/etcd /etc/cni /opt/cni /var/lib/cni /var/lib/kubelet

# Revert the containerd
sudo systemctl stop containerd
sudo systemctl disable containerd
sudo rm -rf /usr/local/bin/containerd*
sudo rm -rf /usr/local/lib/systemd/system/containerd.service
sudo rm -rf /etc/containerd
sudo rm -rf /var/lib/containerd

# Remove runc
sudo rm -f /usr/local/sbin/runc

# Remove the CNI plugins
sudo rm -rf /opt/cni/bin
sudo rm -rf /etc/cni

# Remove the Sysctl and kernet modules config
sudo rm -f /etc/sysctl.d/k8s.conf
sudo rm -f /etc/modules-load.d/k8s.conf
sudo sysctl --system

sudo modprobe -r br_netfilter
sudo modprobe -r overlay

# ON the swap
sudo swapon -a

# reset the ufw
sudo ufw disable
sudo ufw reset

# Remove the downloaded files
rm -f containerd-1.7.14-linux-amd64.tar.gz
rm -f containerd.service
rm -f runc.amd64
rm -f cni-plugins-linux-amd64-v1.5.0.tgz
rm -f custom-resources.yaml


# reboot the system
sudo reboot




