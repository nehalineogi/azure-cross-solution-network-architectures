#!/bin/sh
# This is to install required components to stand up VPN and other services 
sleep 10
sudo apt-get update --yes
sleep 5 
sudo apt-get install strongswan --yes
sleep 5
sudo sed -i '/'net.ipv4.conf.all.accept_redirects'/s/^#//g' /etc/sysctl.conf 
sudo sed -i '/'net.ipv4.conf.all.send_redirects'/s/^#//g' /etc/sysctl.conf 
sudo sed -i '/'net.ipv4.ip_forward'/s/^#//g' /etc/sysctl.conf 

# configure ipsec.conf
rm /etc/ipsec.conf

echo "config setup" >> /etc/ipsec.conf
echo "        # strictcrlpolicy=yes" >> /etc/ipsec.conf
echo "        # uniqueids = no" >> /etc/ipsec.conf
echo " " >> /etc/ipsec.conf
echo "conn azure" >> /etc/ipsec.conf
echo "      type=tunnel" >> /etc/ipsec.conf
echo "      authby=secret" >> /etc/ipsec.conf
echo "      keyexchange=ikev2" >> /etc/ipsec.conf
echo "      ike=aes256-sha1-modp1024" >> /etc/ipsec.conf
echo "      esp=aes256-sha1-modp1024!" >> /etc/ipsec.conf
echo "      left=$1" >> /etc/ipsec.conf
echo "      leftsubnet=$6" >> /etc/ipsec.conf
echo "      right=$3" >> /etc/ipsec.conf
echo "      rightsubnet=$4,$7" >> /etc/ipsec.conf
echo "      auto=start" >> /etc/ipsec.conf

# Edit secrets file add psk
echo "$2 $3 : PSK \"$5\" " >> /etc/ipsec.secrets

# edit charon to increase retries (to allow time for Virtual Network Gateway to deploy)

sudo sed -i 's/    # retransmit_tries = 5/retransmit_tries = 100/' /etc/strongswan.d/charon.conf
sudo sed -i 's/    # install_routes = yes/install_routes = yes/' /etc/strongswan.d/charon.conf

# Add forwarding rule to iptables to allow forwarding of traffic , some of these rules may not be needed - be good to test which are needed
modprobe iptable_nat
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F

# start strongSwan 
sudo ipsec restart