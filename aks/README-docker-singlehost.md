## Docker Single host Networking

This architecture demonstrates single docker host and networking with the docker host, custom bridge networks, dual homing containers. Note: Containers connected to the bridge network on one docker host cannot talk to the container on the other host. Bridge networks are scoped locally and don't span multiple hosts.

The quickstart deployment will provision two Azure VMs acting as docker hosts, each has an out-the-box installation of docker. Azure bastion is also deployed and enabled for the VMs and you can connect to the docker VMs using this method immediately. For direct SSH connection, please see below.

## Reference Architecture

#### Single Host Docker networking

![Docker Swarm Cluster](images/docker-single-host.png)

Download Visio link here.
## Quickstart deployment

The username for the deployed VMs is ```localadmin```

The passwords are stored in a keyvault deployed to the same resource group.
### Task 1 - Start Deployment

1. Open Cloud Shell and retrieve your signed-in user ID below (this is used to apply access to Keyvault).

``` 
az ad signed-in-user show --query objectId -o tsv
```

2. Click Deploy to Azure and supply the signed-in user ID.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnehalineogi%2Fazure-cross-solution-network-architectures%2Fmain%2Faks%2Fjson%2Fdockerhost.json)

3. Using Azure Bastion, log in to the VMs using the username ```localadmin``` and passwords from keyvault.

### Task 2 (optional) - SSH to the docker VMs.

1. Find NSG called "Allow-tunnel-traffic" and amend rule "allow-ssh-inbound" - change 127.0.0.1 to your current public IP address and change rule from Deny to Allow

2. Retrieve the public IP address (or DNS label) for each VM 

3. Retrieve the VM passwords from the keyvault.

4. SSH to your VMs 

```
ssh localadmin@[VM Public IP or DNS]
```

## Documentation links

1. [Docker Network Tutorial](https://docs.docker.com/network/network-tutorial-standalone/)
2. [Docker Network Bridge](https://docs.docker.com/network/bridge/)
3. [Container networking](https://docs.docker.com/config/containers/container-networking/)

## Design Components

The above architecture diagram contains a few key components

- Two Ubuntu Linux VM acting as docker hosts. In this design VM reside on the same azure subnet but it can be deployed in environments where they have layer 3 connectivity.
- Default docker bridge (docker0)
- Custom docker bridge red-bridge and green-bridge
- Two docker hosts are connected to the same subnet. Containers connected to the bridge network on one docker host cannot talk to the container on the other host. Note: Bridge network are scoped locally and don't span multiple hosts.
- Bridge networks are like two isolated layer two switches.
- Inbound and oubound connectivity to and from container via host port (eth0)

### Docker Host Default Networks

List the default networks

```
root@docker-host-1:~# docker network ls
NETWORK ID NAME DRIVER SCOPE
617215cfa2bf bridge bridge local
e40cd249ca0f host host local
bbc4a629e148 none null local

```

Bridge Network: Layer2 broadcast domain. All containers connected to the bridge can talk to each other.

### Create containers on the default bridge network (docker0)

```
# Clean any existing containers
#
root@docker-host-1:~# docker rm $(docker ps -aq)
1c6ea3bd9a20

# Run nginx container
root@docker-host-1:~# docker run -dit --name blue-c1 nginxdemos/hello
460eb69b0fbdc3ecff703364b45b0b7fcdf9f11be0ad45a79a4b89fe6c73690c

# List the container and exec/login to the container and observe networking components
#
root@docker-host-1:~# docker ps
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
460eb69b0fbd nginxdemos/hello "/docker-entrypoint.…" 2 seconds ago Up 1 second 80/tcp blue-c1
root@docker-host-1:~# docker exec -it blue-c1 sh
/ # ifconfig
eth0 Link encap:Ethernet HWaddr 02:42:AC:11:00:02
inet addr:172.17.0.2 Bcast:172.17.255.255 Mask:255.255.0.0
UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1
RX packets:9 errors:0 dropped:0 overruns:0 frame:0
TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:0
RX bytes:806 (806.0 B) TX bytes:0 (0.0 B)

lo Link encap:Local Loopback
inet addr:127.0.0.1 Mask:255.0.0.0
UP LOOPBACK RUNNING MTU:65536 Metric:1
RX packets:0 errors:0 dropped:0 overruns:0 frame:0
TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:1000
RX bytes:0 (0.0 B) TX bytes:0 (0.0 B)

# Observe outbout IP of the container is the PIP of the docker hosts
/ # curl ifconfig.me
/ # curl ifconfig.io
40.114.86.154
/ # exit
root@docker-host-1:~#

# Create another container in the default bridge network and ping the first container
#
root@docker-host-1:~# docker run -dit --name blue-c2 nginxdemos/hello
2535fc3f3ec0df7f516f1ebc978d297425351069a0bc3d246783678073ad8116
root@docker-host-1:~# docker exec -it blue-c2 sh
/ # ifconfig
eth0 Link encap:Ethernet HWaddr 02:42:AC:11:00:03
inet addr:172.17.0.3 Bcast:172.17.255.255 Mask:255.255.0.0
UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1
RX packets:7 errors:0 dropped:0 overruns:0 frame:0
TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:0
RX bytes:586 (586.0 B) TX bytes:0 (0.0 B)

lo Link encap:Local Loopback
inet addr:127.0.0.1 Mask:255.0.0.0
UP LOOPBACK RUNNING MTU:65536 Metric:1
RX packets:0 errors:0 dropped:0 overruns:0 frame:0
TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:1000
RX bytes:0 (0.0 B) TX bytes:0 (0.0 B)

/ # ping 172.17.0.2
PING 172.17.0.2 (172.17.0.2): 56 data bytes
64 bytes from 172.17.0.2: seq=0 ttl=64 time=0.101 ms
64 bytes from 172.17.0.2: seq=1 ttl=64 time=0.087 ms
^C
--- 172.17.0.2 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.087/0.094/0.101 ms
/ # curl -I 172.17.0.2
HTTP/1.1 200 OK
Server: nginx/1.21.1
Date: Wed, 28 Jul 2021 12:28:49 GMT
Content-Type: text/html
Connection: keep-alive
Expires: Wed, 28 Jul 2021 12:28:48 GMT
Cache-Control: no-cache

```

### Inspect the Docker network bridge

Observer subnet, gateway and container IPs

```
root@docker-host-1:~# docker network inspect bridge
[
    {
        "Name": "bridge",
        "Id": "617215cfa2bf458e925bc884a09003a8987def724bc477ee638eddd868746a3f",
        "Created": "2021-07-26T00:14:10.037399306Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "2535fc3f3ec0df7f516f1ebc978d297425351069a0bc3d246783678073ad8116": {
                "Name": "blue-c2",
                "EndpointID": "fafc1c99ae0bc7badd174e99c39faf83d955bd0ccea4372ea5acabb45e21cfe8",
                "MacAddress": "02:42:ac:11:00:03",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            },
            "460eb69b0fbdc3ecff703364b45b0b7fcdf9f11be0ad45a79a4b89fe6c73690c": {
                "Name": "blue-c1",
                "EndpointID": "d13ba65fd958d2374df84e72ac2f8855dabaccb55da6cad47f3a028b0f76c43a",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]
root@docker-host-1:~#
```

### DNS Resolution

Inherits the DNS configuration from the Docker host

```

root@docker-host-1:~# docker exec -it blue-c1 sh
/ #
/ # more /etc/resolv.conf
<snip>

nameserver 168.63.129.16
search 1grit5g0qs5exa0hhgg2i425ng.bx.internal.cloudapp.net
/ # curl ifconfig.io
40.114.86.154
/ # ping www.google.com
PING www.google.com (142.250.188.36): 56 data bytes
64 bytes from 142.250.188.36: seq=0 ttl=113 time=1.654 ms
64 bytes from 142.250.188.36: seq=1 ttl=113 time=1.993 ms
^C
--- www.google.com ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 1.654/1.823/1.993 ms
/ # hostname
460eb69b0fbd
/ # ping blue-c2
ping: bad address 'blue-c2'
/ #
```

### Create custom bridge (red-bridge and green-bridge)

```
root@docker-host-1:~# docker network create --driver bridge red-bridge
ac20cf5095d295a868da2728b9ebf933a632c495b6d766b46c929008816ba0c5

root@docker-host-1:~# docker network inspect red-bridge
[
    {
        "Name": "red-bridge",
        "Id": "ac20cf5095d295a868da2728b9ebf933a632c495b6d766b46c929008816ba0c5",
        "Created": "2021-07-28T13:04:09.277786582Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.20.0.0/16",
                    "Gateway": "172.20.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
root@docker-host-1:~#

root@docker-host-1:~# docker network create --driver bridge green-bridge
6555ae5cadacc199e8d30177997711690f18a44a71aaa59323e9ae6b42a92a66
root@docker-host-1:~# docker network ls
NETWORK ID     NAME           DRIVER    SCOPE
617215cfa2bf   bridge         bridge    local
6555ae5cadac   green-bridge   bridge    local
e40cd249ca0f   host           host      local
bbc4a629e148   none           null      local
ac20cf5095d2   red-bridge     bridge    local
root@docker-host-1:~#
```

### Attach container to a bridge

```
root@docker-host-1:~# docker run -dit --name green-c1 --network green-bridge nginxdemos/hello
ce124fc1a83c9aa7b6ccc6f95464a7026c4de573e02db7a51474704fd0d0593b

root@docker-host-1:~# docker exec -it green-c1 sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
50: eth0@if51: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:15:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.21.0.2/16 brd 172.21.255.255 scope global eth0
       valid_lft forever preferred_lft forever

```

### DNS Resolution for Custom Bridge

```
#Note: In Custom bridge you can ping one green-c2 using the name.
#
root@docker-host-1:~# docker run -dit --name green-c1 --network green-bridge nginxdemos/hello
86a13eb35477e3a89eb5377bb96492d0bdafe88b3337a1363a6cf39c9020f63f
root@docker-host-1:~# docker run -dit --name green-c2 --network green-bridge nginxdemos/hello
33f4ef617df4c7e4b16dd341e25971b27017d4d8d2ebfa79fb93132a2673c3e9
root@docker-host-1:~# docker exec -it green-c1 sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
56: eth0@if57: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:15:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.21.0.2/16 brd 172.21.255.255 scope global eth0
       valid_lft forever preferred_lft forever
/ # curl ifconfig.io
40.114.86.154
/ # more /etc/resolv.conf
search 1grit5g0qs5exa0hhgg2i425ng.bx.internal.cloudapp.net
nameserver 127.0.0.11
options edns0 ndots:0
/ # ping green-c2
PING green-c2 (172.21.0.3): 56 data bytes
64 bytes from 172.21.0.3: seq=0 ttl=64 time=0.095 ms
64 bytes from 172.21.0.3: seq=1 ttl=64 time=0.091 ms
^C
--- green-c2 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.091/0.093/0.095 ms
/ #


```

### Dual Home a Container

```

root@docker-host-1:~# docker network connect red-bridge red-c1
root@docker-host-1:~# docker exec -it red-c1 sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
44: eth0@if45: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:11:00:04 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.4/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
60: eth1@if61: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:14:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.20.0.2/16 brd 172.20.255.255 scope global eth1
       valid_lft forever preferred_lft forever
/ #
```

### Expose the Container to the outside world

```
root@docker-host-1:~# docker run -dit -p 8080:80 --name web nginxdemos/hello
33e1f6c6a271a9e336290b4fc8c64ddc1c53dc3103dcc531df46e0cc790e1f45

root@docker-host-1:~# docker ps | grep web
33e1f6c6a271 nginxdemos/hello "/docker-entrypoint.…" 33 seconds ago Up 32 seconds 0.0.0.0:8080->80/tcp, :::8080->80/tcp web

root@docker-host-1:~# curl -I localhost:8080
HTTP/1.1 200 OK
Server: nginx/1.21.1
Date: Wed, 28 Jul 2021 15:54:25 GMT
Content-Type: text/html
Connection: keep-alive
Expires: Wed, 28 Jul 2021 15:54:24 GMT
Cache-Control: no-cache

```

### Final Docker Host view

Note Docker0 interface and veth pairs, iptables and port forwarding.

```
root@docker-host-1:~# ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:22:48:1e:1a:09 brd ff:ff:ff:ff:ff:ff
    inet 172.16.24.4/24 brd 172.16.24.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::222:48ff:fe1e:1a09/64 scope link
       valid_lft forever preferred_lft forever
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:3a:2c:88:bf brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:3aff:fe2c:88bf/64 scope link
       valid_lft forever preferred_lft forever
41: vethc7aabb9@if40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether 0e:3e:5d:b1:63:ab brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::c3e:5dff:feb1:63ab/64 scope link
       valid_lft forever preferred_lft forever
43: vethe65f68c@if42: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether f6:a2:89:aa:d2:00 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::f4a2:89ff:feaa:d200/64 scope link
       valid_lft forever preferred_lft forever
45: veth366af35@if44: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether 36:21:4c:84:99:ff brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::3421:4cff:fe84:99ff/64 scope link
       valid_lft forever preferred_lft forever
47: veth210b56a@if46: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether 0a:6c:76:16:aa:64 brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::86c:76ff:fe16:aa64/64 scope link
       valid_lft forever preferred_lft forever
48: br-ac20cf5095d2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:55:bd:34:16 brd ff:ff:ff:ff:ff:ff
    inet 172.20.0.1/16 brd 172.20.255.255 scope global br-ac20cf5095d2
       valid_lft forever preferred_lft forever
    inet6 fe80::42:55ff:febd:3416/64 scope link
       valid_lft forever preferred_lft forever
49: br-6555ae5cadac: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:15:8d:b7:96 brd ff:ff:ff:ff:ff:ff
    inet 172.21.0.1/16 brd 172.21.255.255 scope global br-6555ae5cadac
       valid_lft forever preferred_lft forever
    inet6 fe80::42:15ff:fe8d:b796/64 scope link
       valid_lft forever preferred_lft forever
57: veth6f5f3c2@if56: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-6555ae5cadac state UP group default
    link/ether e6:a2:47:30:31:24 brd ff:ff:ff:ff:ff:ff link-netnsid 4
    inet6 fe80::e4a2:47ff:fe30:3124/64 scope link
       valid_lft forever preferred_lft forever
59: vetha335773@if58: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-6555ae5cadac state UP group default
    link/ether 16:24:18:b5:6e:15 brd ff:ff:ff:ff:ff:ff link-netnsid 5
    inet6 fe80::1424:18ff:feb5:6e15/64 scope link
       valid_lft forever preferred_lft forever
61: veth47227a1@if60: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-ac20cf5095d2 state UP group default
    link/ether d6:3f:dd:a0:c7:b7 brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::d43f:ddff:fea0:c7b7/64 scope link
       valid_lft forever preferred_lft forever
63: veth840f502@if62: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-ac20cf5095d2 state UP group default
    link/ether be:2a:f6:fa:09:8a brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::bc2a:f6ff:fefa:98a/64 scope link
       valid_lft forever preferred_lft forever
65: vethfbf007b@if64: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether 62:67:d3:3a:ad:b6 brd ff:ff:ff:ff:ff:ff link-netnsid 6
    inet6 fe80::6067:d3ff:fe3a:adb6/64 scope link
       valid_lft forever preferred_lft forever
root@docker-host-1:~# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.16.24.1     0.0.0.0         UG    100    0        0 eth0
168.63.129.16   172.16.24.1     255.255.255.255 UGH   100    0        0 eth0
169.254.169.254 172.16.24.1     255.255.255.255 UGH   100    0        0 eth0
172.16.24.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
172.20.0.0      0.0.0.0         255.255.0.0     U     0      0        0 br-ac20cf5095d2
172.21.0.0      0.0.0.0         255.255.0.0     U     0      0        0 br-6555ae5cadac
root@docker-host-1:~# iptables -L -n
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy DROP)
target     prot opt source               destination
DOCKER-USER  all  --  0.0.0.0/0            0.0.0.0/0
DOCKER-ISOLATION-STAGE-1  all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain DOCKER (3 references)
target     prot opt source               destination
ACCEPT     tcp  --  0.0.0.0/0            172.17.0.6           tcp dpt:80

Chain DOCKER-ISOLATION-STAGE-1 (1 references)
target     prot opt source               destination
DOCKER-ISOLATION-STAGE-2  all  --  0.0.0.0/0            0.0.0.0/0
DOCKER-ISOLATION-STAGE-2  all  --  0.0.0.0/0            0.0.0.0/0
DOCKER-ISOLATION-STAGE-2  all  --  0.0.0.0/0            0.0.0.0/0
RETURN     all  --  0.0.0.0/0            0.0.0.0/0

Chain DOCKER-ISOLATION-STAGE-2 (3 references)
target     prot opt source               destination
DROP       all  --  0.0.0.0/0            0.0.0.0/0
DROP       all  --  0.0.0.0/0            0.0.0.0/0
DROP       all  --  0.0.0.0/0            0.0.0.0/0
RETURN     all  --  0.0.0.0/0            0.0.0.0/0

Chain DOCKER-USER (1 references)
target     prot opt source               destination
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
root@docker-host-1:~# brctl show
bridge name     bridge id               STP enabled     interfaces
br-6555ae5cadac         8000.0242158db796       no              veth6f5f3c2
                                                        vetha335773
br-ac20cf5095d2         8000.024255bd3416       no              veth47227a1
                                                        veth840f502
docker0         8000.02423a2c88bf       no              veth210b56a
                                                        veth366af35
                                                        vethc7aabb9
                                                        vethe65f68c
                                                        vethfbf007b
```

### Cleanup

```
root@docker-host-1:~# docker ps
CONTAINER ID   IMAGE              COMMAND                  CREATED          STATUS          PORTS                                   NAMES
33e1f6c6a271   nginxdemos/hello   "/docker-entrypoint.…"   38 minutes ago   Up 38 minutes   0.0.0.0:8080->80/tcp, :::8080->80/tcp   web
33f4ef617df4   nginxdemos/hello   "/docker-entrypoint.…"   3 hours ago      Up 3 hours      80/tcp                                  green-c2
86a13eb35477   nginxdemos/hello   "/docker-entrypoint.…"   3 hours ago      Up 3 hours      80/tcp                                  green-c1
6df6d545e317   nginxdemos/hello   "/docker-entrypoint.…"   4 hours ago      Up 4 hours      80/tcp                                  red-c2
ee42f6051ff4   nginxdemos/hello   "/docker-entrypoint.…"   4 hours ago      Up 4 hours      80/tcp                                  red-c1
2535fc3f3ec0   nginxdemos/hello   "/docker-entrypoint.…"   4 hours ago      Up 4 hours      80/tcp                                  blue-c2
460eb69b0fbd   nginxdemos/hello   "/docker-entrypoint.…"   4 hours ago      Up 4 hours      80/tcp                                  blue-c1

root@docker-host-1:~# docker ps -aq
33e1f6c6a271
33f4ef617df4
86a13eb35477
6df6d545e317
ee42f6051ff4
2535fc3f3ec0
460eb69b0fbd
root@docker-host-1:~# docker rm $(docker ps -aq) -f
33e1f6c6a271
33f4ef617df4
86a13eb35477
6df6d545e317
ee42f6051ff4
2535fc3f3ec0
460eb69b0fbd
root@docker-host-1:~# docker ps -aq
```
## Docker Installation - Troubleshooting

### I am unable to SSH to hosts, what do I need to do?

The automated deployment deploys Azure Bastion so you can connect to the VMs via the portal using Bastion. Alternatively the subnet hosting the VMs has a Network Security Group (NSG) attached called "Allow-tunnel-traffic" with a rule called 'allow-ssh-inbound' which is set to Deny by default. If you wish to allow SSH direct to the hosts, you can edit this rule and change the Source from 127.0.0.1 to your current public IP address. Afterwards, Remember to set the rule from Deny to Allow.  
### What are the logins for the VMs? 

The credentials for the VMs are stored in an Azure keyvault. 

### Are the passwords used cyptographically secure? 

No. The passwords are generated deterministically and therefore should be changed on the VMs post deployment, to maximise security. They are auto generated in this way for convenience and are intended to support this environment as a 'Proof of Concept' or learning experience only and are not intended for production use. 

### I cannot run the deployment - what is the ADuserID?

In order for the deployment to provision your signed-in user account access to the keyvault, you will need to provide your Azure Active Directory (AAD) signed-in user ObjectID. In order to retrieve this there are serveral methods. The Azure CLI and Azure Powershell methods are provided below. You can use the cloud shell to run the Azure CLI method, but for powershell you must run this from your own device using Azure Powershell module. 

Azure CLI or Cloud Shell
``` 
az ad signed-in-user show --query objectId -o tsv
```

Azure Powershell 
```
(Get-AzContext).Account.ExtendedProperties.HomeAccountId.Split('.')[0]
```

### How is docker installed on the host? 

Docker is installed via a VM custom script extension, for reference the commands used are found in the following script - [cse.sh](scripts/cse.sh)

This script is called automatically by the [deployhost.json](json/deployhost.json) ARM template on deployment. 