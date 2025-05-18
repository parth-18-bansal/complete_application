# complete_application
complete application deployed using k8s

# connect the free tier ec2, window pc, ubuntu pc, mac through wireguard
A) Installation
Windows: Install the wireguard on the windows pc
Ubuntu: Install the wireguard on the ubuntu pc

B) Generate Public Key and Private Key
Ubuntu : wg genkey | tee privatekey | wg pubkey > publickey
Windows : In GUI, click "Add Tunnel" -> "Add Empty Tunnel", it generate both types of keys.

C) Configuration file
a) Ubuntu
  1) create a file at /etc/wireguard/wg0.conf
  2) write this code :
     [Interface]
     PrivateKey = <Ubuntu_private_key>
     Address = 10.0.0.1/24
     ListenPort = 51820

     [Peer]
     PublicKey = <Windows_public_key>
     AllowedIPs = 10.0.0.2/32
     
b) Windows: In GUI
  [Interface]
  PrivateKey = <Windows_private_key>
  Address = 10.0.0.2/24
  DNS = 1.1.1.1

  [Peer]
  PublicKey = <Ubuntu_public_key>
  AllowedIPs = 10.0.0.1/32
  Endpoint = <Ubuntu_Public_IP>:51820
  PersistentKeepalive = 25


