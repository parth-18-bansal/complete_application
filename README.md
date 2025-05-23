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




