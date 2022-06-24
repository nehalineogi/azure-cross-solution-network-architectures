# Introduction

Linux network namespace is logically another copy of the network stack with it own routes, arp table, firewall rules. It is similiar to VRFs in the traditional networking. This concept of creating namespaces or VRFs is foundational to container networking. In the linux-bridge article we only had one namespace - the default naemspace. In this article we will explore creating namespaces other than the default namespace.

# Reference Architecture (Coming Soon)

# Documentation Links

# Challenge#1:Create linux namespace

```
sudo -s
ip netns add red
ip netns add green
ip netns add blue

# Validations
ip netns ls

# View host networking

ip link
arp

root@linux-host-1:/home/nehali# ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
link/ether 00:0d:3a:1f:31:53 brd ff:ff:ff:ff:ff:ff
3: enP30916s1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master eth0 state UP mode DEFAULT group default qlen 1000
link/ether 00:0d:3a:1f:31:53 brd ff:ff:ff:ff:ff:ff
altname enP30916p0s2
root@linux-host-1:/home/nehali# arp
Address HWtype HWaddress Flags Mask Iface
\_gateway ether 12:34:56:78:9a:bc C

#
# view namespace networking
#

ip netns exec red ip link
ip netns exec arp
ip -n red link



root@linux-host-1:/home/nehali# ip netns exec red ip link
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
root@linux-host-1:/home/nehali# ip netns exec red arp
```

# Challenge#2 Create a linux bridge (switch) and connect veth pairs (cables)

veth interfaces are virtual Ethernet devices and are always created a pairs.

```
#
#Create linux bridge (network switch)
#
ip link add linux-bridge type bridge
ip link set dev linux-bridge up

root@linux-host-1:/home/nehali# ip link add linux-bridge type bridge
root@linux-host-1:/home/nehali# ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 00:0d:3a:1f:31:53 brd ff:ff:ff:ff:ff:ff
3: enP30916s1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master eth0 state UP mode DEFAULT group default qlen 1000
    link/ether 00:0d:3a:1f:31:53 brd ff:ff:ff:ff:ff:ff
    altname enP30916p0s2
4: linux-bridge: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether c2:b7:68:b1:a1:f9 brd ff:ff:ff:ff:ff:ff

#
# connect namespace to linux bridge using veth-pair
# (cable)
#
ip link add veth-red type veth peer name veth-red-br
ip link add veth-green type veth peer name veth-green-br
# connect the ends to the corresponding ns
ip link set veth-red netns red
ip link set veth-green netns green
# connect the bridge ned to the linux-bridge

ip link set veth-red-br master linux-bridge
ip link set veth-green-br master linux-bridge

ip link set veth-red-br up
ip link set veth-green-br up


#
# Bridge validations
#
brctl show

root@linux-host-1:/home/nehali# brctl showmacs linux-bridge
port no mac addr is local? ageing timer
1 4e:36:05:c3:04:62 no 96.58
1 52:48:30:10:51:28 yes 0.00
1 52:48:30:10:51:28 yes 0.00
2 56:a8:2f:22:e6:b5 no 126.02
2 8e:34:2d:f7:74:34 yes 0.00
2 8e:34:2d:f7:74:34 yes 0.00
root@linux-host-1:/home/nehali# ip netns exec red ip link
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
8: veth-red@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
link/ether 56:a8:2f:22:e6:b5 brd ff:ff:ff:ff:ff:ff link-netnsid 0
root@linux-host-1:/home/nehali# ip netns exec green ip link
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
10: veth-green@if9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
link/ether 4e:36:05:c3:04:62 brd ff:ff:ff:ff:ff:ff link-netnsid 0
root@linux-host-1:/home/nehali#


```

# Challenge#3 Layer 3 Connectivity

Assign IP address to the interfaces

```
ip -n red add add 192.168.24.10/24 dev veth-red
ip -n green add add 192.168.24.11/24 dev veth-green
ip -n red link set veth-red up
ip -n green link set veth-green up
ip netns exec red ip add
ip netns exec green ip add

ip netns exec red ping 192.168.24.11

root@linux-host-1:/home/nehali# ip netns exec red ping 192.168.24.11
PING 192.168.24.11 (192.168.24.11) 56(84) bytes of data.
64 bytes from 192.168.24.11: icmp_seq=1 ttl=64 time=0.048 ms
64 bytes from 192.168.24.11: icmp_seq=2 ttl=64 time=0.051 ms
^C
--- 192.168.24.11 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1032ms
rtt min/avg/max/mdev = 0.048/0.049/0.051/0.001 ms
root@linux-host-1:/home/nehali# ip netns exec red arp
Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.24.11            ether   4e:36:05:c3:04:62   C                     veth-red

```

# Challenge#4 (Default gateway - For Outbound Connectivity)

```
ip add add 192.168.24.1/24 dev linux-bridge

root@linux-host-1:/home/nehali# ip add add 192.168.24.1/24 dev linux-bridge
root@linux-host-1:/home/nehali# ping 192.168.24.10
PING 192.168.24.10 (192.168.24.10) 56(84) bytes of data.
64 bytes from 192.168.24.10: icmp_seq=1 ttl=64 time=0.077 ms
64 bytes from 192.168.24.10: icmp_seq=2 ttl=64 time=0.051 ms

#
#
#
ip netns exec red ip route add 0.0.0.0/0 via 192.168.24.1
ip netns exec red ip route show

iptables -t nat -A POSTROUTING -s 192.168.24.0/24 -j MASQUERADE

root@linux-host-1:/home/nehali# echo 1 > /proc/sys/net/ipv4/ip_forward
root@linux-host-1:/home/nehali# ip netns exec red ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=55 time=1.57 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=55 time=1.54 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=55 time=1.54 ms
```

# Challenge#5 (Inbound Connectivity - Port fowarding)

```
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.24.10:80

#
curl <public_ip>:8080
```

# Cleanup

```
ip link delete veth-red
ip link delete veth-green
```
