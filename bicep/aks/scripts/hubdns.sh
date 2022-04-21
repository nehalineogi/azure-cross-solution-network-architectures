sleep 10
sudo apt-get update
sleep 5 
sudo apt-get install bind9 bind9utils bind9-doc net-tools
sleep 5
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.orig
sudo rm /etc/bind/named.conf.options
echo "acl goodclients {" >> /etc/bind/named.conf.options
echo "    $1;" >> /etc/bind/named.conf.options
echo "    $2;" >> /etc/bind/named.conf.options
echo "    $3;" >> /etc/bind/named.conf.options
echo "    localhost;" >> /etc/bind/named.conf.options
echo "};" >> /etc/bind/named.conf.options
echo " " >> /etc/bind/named.conf.options
echo "options {" >> /etc/bind/named.conf.options
echo "directory "'"/var/cache/bind"'";" >> /etc/bind/named.conf.options
echo "dnssec-validation yes;" >> /etc/bind/named.conf.options
echo "recursion yes; " >> /etc/bind/named.conf.options
echo "        allow-query { goodclients; };" >> /etc/bind/named.conf.options
echo "forwarders {" >> /etc/bind/named.conf.options
echo "                168.63.129.16;" >> /etc/bind/named.conf.options
echo "        };" >> /etc/bind/named.conf.options
echo "};" >> /etc/bind/named.conf.options

sudo sed -i 's/nameserver 127.0.0.53/nameserver 127.0.0.1/' /etc/resolv.conf

sudo systemctl restart bind9
sudo systemctl status bind9