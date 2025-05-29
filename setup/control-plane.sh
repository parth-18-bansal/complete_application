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

# 