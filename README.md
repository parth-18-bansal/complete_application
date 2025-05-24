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







