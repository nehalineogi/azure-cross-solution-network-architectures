# Multi Host Networking using Docker Swarm Cluster

This architecture demonstrates multi-host docker swarm cluster using VXLAN overlay networks. Overlay networks span multiple nodes. Overlay networks extend the layer-2 broadcast domain to multiple nodes

The quickstart deployment will provision two Azure VMs acting as docker hosts, each has an out-the-box installation of docker. Azure bastion is also deployed and enabled for the VMs and you can connect to the docker VMs using this method immediately. For direct SSH connection, please see below.

# Reference Architecture

#### Multi-Host Networking (Docker Swarm Cluster)

![Docker swarm cluster](images/docker-multihost.png)

Download [Multi-tab Visio](aks-all-reference-architectures-visio.vsdx) and [PDF](aks-all-reference-architectures-PDF.pdf)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnehalineogi%2Fazure-cross-solution-network-architectures%2Fmain%2Faks%2Fjson%2Fdockerhostmulti.json)

# Quickstart deployment

The username for the deployed VMs is `localadmin`

The passwords are stored in a keyvault deployed to the same resource group.

### Task 1: Start Deployment

1. Click Deploy to Azure button above and supply the signed-in user ID from step 2.

2. Open Cloud Shell and retrieve your signed-in user ID below (this is used to apply access to Keyvault).

```
az ad signed-in-user show --query id -o tsv
```

3. Using Azure Bastion, log in to the VMs using the username `localadmin` and passwords from keyvault.

4. log in as root with command ```sudo su```

### Task 2 (optional): SSH to the docker VMs.

1. Locate the Network Security Group (NSG) called "Allow-tunnel-traffic" and amend rule "allow-ssh-inbound" - change 127.0.0.1 to your current public IP address and change rule from Deny to Allow

2. Retrieve the public IP address (or DNS label) for each VM

3. Retrieve the VM passwords from the keyvault.

4. SSH to your VMs

```
ssh localadmin@[VM Public IP or DNS]
```

5. log in as root with command ```sudo su```

# Design Components

- Two Ubuntu Linux VM acting as docker hosts. In this design, docker host VMs reside on the same azure subnet but it can be deployed in environments where they have layer 3 connectivity.
- Enable Swarm Mode to create a multihost cluster
- Custom Overlay Networks (red-overlay and green-overlay)
- docker_gwbridge is the default bridge for swarm cluster
- Overlay networks span multiple nodes and the Docker overlay network uses VXLAN to extend the layer-2 broadcast domain to multiple nodes
- ![Overlay packets](images/vxlan-packets.png)
- Encryption can be enabled on overlay networks
- Ingress into the swarm cluster via ingress overlay. Layer 4 load balancing using service VIP. Cloud providers provide L4 load balancer in front of the nodes. Nginx or HA proxy can be used to load balance the docker nodes.

# Documentation links

1. [Docker Swarm Mode](https://docs.docker.com/engine/swarm/swarm-mode/)
2. [Docker - How a swarm service works](https://docs.docker.com/engine/swarm/how-swarm-mode-works/services/)
3. [VXLAN Overlay Networks](https://docs.docker.com/network/overlay/)
4. [Encrypt traffic on an overlay network](https://docs.docker.com/network/overlay/#encrypt-traffic-on-an-overlay-network)

# Challenge 1: Create a Docker Swarm Cluster

List the default networks and initialize docker swarm cluster

### Initialize the cluster on the Manager Node

```
#
# On docker-host-1 (manager node)
# Intialize the cluster and grade the swarm join
# command
#
sudo -s
root@docker-host-1:~# docker network ls
NETWORK ID NAME DRIVER SCOPE
617215cfa2bf bridge bridge local
e40cd249ca0f host host local
bbc4a629e148 none null local

root@docker-host-1:~# docker swarm init --advertise-addr=172.16.24.4
Swarm initialized: current node (im1clp7aw6n6qqv8lcs3u3hxe) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5y4llc1jq1eowsq42pkxrmjl01z50299uszrqaajvh79r33bkq-27wum03xpatfo65av02ufiexd 172.16.24.4:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

```

### Join the Worker Node to the swarm cluster

```
#
# On docker-host-2 (worker node)
# Use the join command from the output above
root@docker-host-2:~# docker rm $(docker ps -aq) -f
e6dc0d3bc421
root@docker-host-2:~# docker swarm join --token SWMTKN-1-5y4llc1jq1eowsq42pkxrmjl01z50299uszrqaajvh79r33bkq-27wum03xpatfo65av02ufiexd 172.16.24.4:2377
This node joined a swarm as a worker.

Bridge Network: Layer2 broadcast domain. All containers connected to the bridge can talk to each other.

```

### Run validations Manager Node

```
#
# On docker-host-1
#
root@docker-host-1:~# docker node ls
ID                            HOSTNAME        STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
im1clp7aw6n6qqv8lcs3u3hxe *   docker-host-1   Ready     Active         Leader           20.10.7
66lur8tr9pz53r1bdrd1ee6bj     docker-host-2   Ready     Active                          20.10.7
root@docker-host-1:~#

Notice two new network the docker_gwbridge network scoped as "local" and overlay network called "ingress" scoped as swarm
root@docker-host-1:~# docker network ls
NETWORK ID     NAME              DRIVER    SCOPE
617215cfa2bf   bridge            bridge    local
31854151fca2   docker_gwbridge   bridge    local
e40cd249ca0f   host              host      local
cbggz8x7u06z   ingress           overlay   swarm
bbc4a629e148   none              null      local
root@docker-host-1:~#

Observe the IPs on the Default bridge:

root@docker-host-1:~# docker network inspect docker_gwbridge
[
    {
        "Name": "docker_gwbridge",
        "Id": "31854151fca2b9a3c23492b5cec8b4f1a98d878cae1cbfffe07f0bfb8e24ec73",
        "Created": "2021-07-28T17:30:03.934967791Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
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
            "ingress-sbox": {
                "Name": "gateway_ingress-sbox",
                "EndpointID": "b21f423d1daf361ac1c2edeb3dc23eb90fdf32c3e28983c018fa1c8761dd1c7c",
                "MacAddress": "02:42:ac:16:00:02",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.enable_icc": "false",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.name": "docker_gwbridge"
        },
        "Labels": {}
    }
]
root@docker-host-1:~#

# Repeat the activity on docker-host-2

root@docker-host-2:~# docker network inspect docker_gwbridge
[
    {
        "Name": "docker_gwbridge",
        "Id": "03633bcf16523df6bc2e1ad4c61c0c1fa48aff8707220a2487511675aeeca8b0",
        "Created": "2021-07-28T17:30:47.940924793Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
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
            "ingress-sbox": {
                "Name": "gateway_ingress-sbox",
                "EndpointID": "4986fc32aeefe212a5ba3aecbd75a6d90257273c435c578f717826c269f52c12",
                "MacAddress": "02:42:ac:14:00:02",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.enable_icc": "false",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.name": "docker_gwbridge"
        },
        "Labels": {}
    }
]

```

# Challenge 2: Create new custom overlay networks on docker-host-1

Note: These overlay networks are scoped as "swarm"

```
#
# create read overlay network
#
root@docker-host-1:~# docker network create -d overlay red-overlay
e2wklxwawqznawtlwyieynell
#
# create green-overlay with encrypted option
#
root@docker-host-1:~# docker network create -d overlay green-overlay --opt encyrpted
yq9448zt082zrr6wmva6zygld
root@docker-host-1:~# docker network inspect red-overlay
[
    {
        "Name": "red-overlay",
        "Id": "e2wklxwawqznawtlwyieynell",
        "Created": "2021-07-28T17:39:51.625319947Z",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.1.0/24",
                    "Gateway": "10.0.1.1"
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
        "Containers": null,
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4097"
        },
        "Labels": null
    }
]
root@docker-host-1:~# docker network inspect green-overlay
[
    {
        "Name": "green-overlay",
        "Id": "yq9448zt082zrr6wmva6zygld",
        "Created": "2021-07-28T17:40:05.825047112Z",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.2.0/24",
                    "Gateway": "10.0.2.1"
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
        "Containers": null,
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4098",
            "encyrpted": ""
        },
        "Labels": null
    }

]

root@docker-host-1:~# docker network ls
NETWORK ID     NAME              DRIVER    SCOPE
617215cfa2bf   bridge            bridge    local
31854151fca2   docker_gwbridge   bridge    local
yq9448zt082z   green-overlay     overlay   swarm
e40cd249ca0f   host              host      local
cbggz8x7u06z   ingress           overlay   swarm
bbc4a629e148   none              null      local
e2wklxwawqzn   red-overlay       overlay   swarm

#
# Note the subnets
#
root@docker-host-1:/home/localadmin# docker network inspect red-overlay | grep -A 2 -i subnet
                    "Subnet": "10.0.1.0/24",
                    "Gateway": "10.0.1.1"
                }
root@docker-host-1:/home/localadmin# docker network inspect green-overlay | grep -A 2 -i subnet
                    "Subnet": "10.0.2.0/24",
                    "Gateway": "10.0.2.1"
                }
root@docker-host-1:/home/localadmin# docker network inspect docker_gwbridge | grep -A 2 -i subnet
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }

root@docker-host-1:/home/localadmin# docker network inspect ingress | grep -A 2 -i subnet
                    "Subnet": "10.0.0.0/24",
                    "Gateway": "10.0.0.1"
                }
```

Observations:

1. What is the vxlan ID of the red-overlay and green-overlay networks?
2. What is the ip address space of the overlay networks?
3. Do the new overlay networks appear on both hosts?

# Challenge 3: Create docker service with 2 replicas on the red-overlay network

```
#
# create a docker service with 2 replicas and expose
# expose port 8080 on host to 80 on service
#
root@docker-host-1:/home/localadmin# docker service create -p 8080:80 --name web-service --replicas=2 --network red-overlay nginxdemos/hello
o6mpmdcdrm6f6kvccy0f74eln
overall progress: 2 out of 2 tasks
1/2: running   [==================================================>]
2/2: running   [==================================================>]
verify: Service converged
root@docker-host-1:/home/localadmin# docker service ls
ID             NAME          MODE         REPLICAS   IMAGE                     PORTS
o6mpmdcdrm6f   web-service   replicated   2/2        nginxdemos/hello:latest   *:8080->80/tcp
#
# list the service
#
root@docker-host-1:/home/localadmin# docker service ps web-service
ID             NAME            IMAGE                     NODE            DESIRED STATE   CURRENT STATE            ERROR     PORTS
rbhms3k74l35   web-service.1   nginxdemos/hello:latest   docker-host-2   Running         Running 10 minutes ago
xy2qpwzu7nqc   web-service.2   nginxdemos/hello:latest   docker-host-1   Running         Running 10 minutes ago
root@docker-host-1:/home/localadmin#
#
# inspect the service
#
root@docker-host-1:/home/localadmin# docker inspect service web-service
[
    {
        "ID": "o6mpmdcdrm6f6kvccy0f74eln",
        "Version": {
            "Index": 59
        },
        "CreatedAt": "2022-02-03T09:39:38.018392955Z",
        "UpdatedAt": "2022-02-03T09:39:38.086526146Z",
        "Spec": {
            "Name": "web-service",
            "Labels": {},
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "nginxdemos/hello:latest@sha256:ae2b5e1ce20fc95668ee991f72e2c8ecb46c8542e5a5eae0b846541c92565643",
                    "Init": false,
                    "StopGracePeriod": 10000000000,
                    "DNSConfig": {},
                    "Isolation": "default"
                },
                "Resources": {
                    "Limits": {},
                    "Reservations": {}
                },
                "RestartPolicy": {
                    "Condition": "any",
                    "Delay": 5000000000,
                    "MaxAttempts": 0
                },
                "Placement": {
                    "Platforms": [
                        {
                            "OS": "linux"
                        },
                        {
                            "OS": "linux"
                        },
                        {
                            "Architecture": "arm64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "amd64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "ppc64le",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "s390x",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "386",
                            "OS": "linux"
                        }
                    ]
                },
                "Networks": [
                    {
                        "Target": "54g3qcpkcpx2o5o9hyj4nroe3"
                    }
                ],
                "ForceUpdate": 0,
                "Runtime": "container"
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 2
                }
            },
            "UpdateConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "RollbackConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "EndpointSpec": {
                "Mode": "vip",
                "Ports": [
                    {
                        "Protocol": "tcp",
                        "TargetPort": 80,
                        "PublishedPort": 8080,
                        "PublishMode": "ingress"
                    }
                ]
            }
        },
        "Endpoint": {
            "Spec": {
                "Mode": "vip",
                "Ports": [
                    {
                        "Protocol": "tcp",
                        "TargetPort": 80,
                        "PublishedPort": 8080,
                        "PublishMode": "ingress"
                    }
                ]
            },
            "Ports": [
                },
                {
                    "NetworkID": "54g3qcpkcpx2o5o9hyj4nroe3",
                    "Addr": "10.0.1.10/24"
                }
            ]
        }
    }

```

# Challenge 4: Inspect the container networking and egress path

Note that you may have different IP addresses assigned, and the interfaces may be in a different order to those shown in the architectural diagram above. 
```
#
# On docker-host-1 ssh into the container. Use the 'docker ps' command to retrieve the container ID and then 'docker exec -it' command to open a shell.
#
root@docker-host-1:/home/localadmin# docker ps 

CONTAINER ID   IMAGE                     COMMAND                  CREATED         STATUS         PORTS     NAMES
c036ec2f1a57   nginxdemos/hello:latest   "/docker-entrypoint.…"   8 minutes ago   Up 8 minutes   80/tcp    web-service.2.psorwwx2zs5fba9dnl11fi3fy

root@docker-host-1:/home/localadmin# docker exec -it c036ec2f1a57 sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:0A:00:00:09
          inet addr:10.0.0.9  Bcast:10.0.0.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

eth1      Link encap:Ethernet  HWaddr 02:42:0A:00:01:0C
          inet addr:10.0.1.12  Bcast:10.0.1.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

eth2      Link encap:Ethernet  HWaddr 02:42:AC:12:00:03
          inet addr:172.18.0.3  Bcast:172.18.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:12 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:936 (936.0 B)  TX bytes:0 (0.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
27: eth0@if28: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP
    link/ether 02:42:0a:00:00:09 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.9/24 brd 10.0.0.255 scope global eth0
       valid_lft forever preferred_lft forever
29: eth2@if30: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:12:00:03 brd ff:ff:ff:ff:ff:ff
    inet 172.18.0.3/16 brd 172.18.255.255 scope global eth2
       valid_lft forever preferred_lft forever
31: eth1@if32: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP
    link/ether 02:42:0a:00:01:0c brd ff:ff:ff:ff:ff:ff
    inet 10.0.1.12/24 brd 10.0.1.255 scope global eth1
       valid_lft forever preferred_lft forever
/ #

 # curl ifconfig.me
40.117.252.69/ # exit
root@docker-host-1:/home/localadmin# curl ifconfig.me
40.117.252.69
#
/ # route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.18.0.1      0.0.0.0         UG    0      0        0 eth2
10.0.0.0        0.0.0.0         255.255.255.0   U     0      0        0 eth0
10.0.1.0        0.0.0.0         255.255.255.0   U     0      0        0 eth1
172.18.0.0      0.0.0.0         255.255.0.0     U     0      0        0 eth2
# On docker-host-2
#
oot@docker-host-2:/home/localadmin# docker ps
CONTAINER ID   IMAGE                     COMMAND                  CREATED          STATUS          PORTS     NAMES
29eab7a74545   nginxdemos/hello:latest   "/docker-entrypoint.…"   17 minutes ago   Up 17 minutes   80/tcp    web-service.1.rbhms3k74l35jrfc6eq2wh28u
root@docker-host-2:/home/localadmin# docker exec -it 29eab7a74545 sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
27: eth1@if28: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP
    link/ether 02:42:0a:00:01:0b brd ff:ff:ff:ff:ff:ff
    inet 10.0.1.11/24 brd 10.0.1.255 scope global eth1
       valid_lft forever preferred_lft forever
29: eth2@if30: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:12:00:03 brd ff:ff:ff:ff:ff:ff
    inet 172.18.0.3/16 brd 172.18.255.255 scope global eth2
       valid_lft forever preferred_lft forever
31: eth0@if32: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP
    link/ether 02:42:0a:00:00:08 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.8/24 brd 10.0.0.255 scope global eth0
       valid_lft forever preferred_lft forever
/ #

```

Observations:

1. Do the overlay networks appear on both hosts?

# Challenge 5: Ingress overlay network and Service VIP Load balancing

Note that you may have different IP addresses assigned, and the interfaces may be in a different order to those shown in the architectural diagram above. 

```
root@docker-host-1:/home/localadmin# docker service inspect web-service | grep -A 9 -i VirtualIPs
"VirtualIPs": [
{
"NetworkID": "oo861ktagy0blgs9myp7izku0",
"Addr": "10.0.0.7/24"
},
{
"NetworkID": "54g3qcpkcpx2o5o9hyj4nroe3",
"Addr": "10.0.1.10/24"
}
]

#

root@docker-host-1:/home/localadmin# curl -s 172.16.24.4:8080 | grep -i address

<p><span>Server&nbsp;address:</span> <span>10.0.0.8:80</span></p>
root@docker-host-1:/home/localadmin# curl -s 172.16.24.4:8080 | grep -i address
<p><span>Server&nbsp;address:</span> <span>10.0.0.9:80</span></p>


```

### Task 1: Validate egress IP

```
root@docker-host-1:~# docker exec -it web-service.2.4nvjeoc4irny8vq5mbr2vxhkz sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
inet 127.0.0.1/8 scope host lo
valid_lft forever preferred_lft forever
75: eth0@if76: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP
link/ether 02:42:0a:00:01:04 brd ff:ff:ff:ff:ff:ff
inet 10.0.1.4/24 brd 10.0.1.255 scope global eth0
valid_lft forever preferred_lft forever
77: eth1@if78: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
link/ether 02:42:ac:16:00:03 brd ff:ff:ff:ff:ff:ff
inet 172.18.0.3/16 brd 172.22.255.255 scope global eth1
valid_lft forever preferred_lft forever
/ # route -n
Kernel IP routing table
Destination Gateway Genmask Flags Metric Ref Use Iface
0.0.0.0 172.18.0.1 0.0.0.0 UG 0 0 0 eth1
10.0.1.0 0.0.0.0 255.255.255.0 U 0 0 0 eth0
172.18.0.0 0.0.0.0 255.255.0.0 U 0 0 0 eth1
/ #
/ # ping web-service.1.4j5g6tq92nlqwja2aovsghnpm
PING web-service.1.4j5g6tq92nlqwja2aovsghnpm (10.0.1.3): 56 data bytes
64 bytes from 10.0.1.3: seq=0 ttl=64 time=1.423 ms
64 bytes from 10.0.1.3: seq=1 ttl=64 time=0.811 ms
^C
--- web-service.1.4j5g6tq92nlqwja2aovsghnpm ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.811/1.117/1.423 ms
/ #

Container on docker-host-2
root@docker-host-2:~# docker exec -it web-service.1.4j5g6tq92nlqwja2aovsghnpm sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
inet 127.0.0.1/8 scope host lo
valid_lft forever preferred_lft forever
43: eth0@if44: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP
link/ether 02:42:0a:00:01:03 brd ff:ff:ff:ff:ff:ff
inet 10.0.1.3/24 brd 10.0.1.255 scope global eth0
valid_lft forever preferred_lft forever
45: eth1@if46: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
link/ether 02:42:ac:14:00:03 brd ff:ff:ff:ff:ff:ff
inet 172.18.0.3/16 brd 172.20.255.255 scope global eth1
valid_lft forever preferred_lft forever
/ # route -n
Kernel IP routing table
Destination Gateway Genmask Flags Metric Ref Use Iface
0.0.0.0 172.18.0.1 0.0.0.0 UG 0 0 0 eth1
10.0.1.0 0.0.0.0 255.255.255.0 U 0 0 0 eth0
172.18.0.0 0.0.0.0 255.255.0.0 U 0 0 0 eth1

```

# Challenge 6: VXLAN Overlay Packet capture

### Initiate ping from container on docker-host-1 to container on docker-host-2

```

root@docker-host-1:/home/localadmin# docker ps

CONTAINER ID   IMAGE                     COMMAND                  CREATED          STATUS          PORTS     NAMES
5277b04b07b3   nginxdemos/hello:latest   "/docker-entrypoint.…"   31 minutes ago   Up 30 minutes   80/tcp    web-service.2.4nvjeoc4irny8vq5mbr2vxhkz

root@docker-host-1:~# docker exec -it web-service.2.4nvjeoc4irny8vq5mbr2vxhkz sh

/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
inet 127.0.0.1/8 scope host lo
valid_lft forever preferred_lft forever
75: eth0@if76: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP
link/ether 02:42:0a:00:01:04 brd ff:ff:ff:ff:ff:ff
inet 10.0.1.4/24 brd 10.0.1.255 scope global eth0
valid_lft forever preferred_lft forever
77: eth1@if78: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
link/ether 02:42:ac:16:00:03 brd ff:ff:ff:ff:ff:ff
inet 172.18.0.3/16 brd 172.22.255.255 scope global eth1
valid_lft forever preferred_lft forever
/ # ping 10.0.1.3
PING 10.0.1.3 (10.0.1.3): 56 data bytes
64 bytes from 10.0.1.3: seq=0 ttl=64 time=1.268 ms
64 bytes from 10.0.1.3: seq=1 ttl=64 time=1.060 ms
64 bytes from 10.0.1.3: seq=2 ttl=64 time=0.837 ms
64 bytes from 10.0.1.3: seq=3 ttl=64 time=1.331 ms
^C
--- 10.0.1.3 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.837/1.124/1.331 ms
/ #

```

####Run tcpdump on docker-host-2 eth0 interface

Observe vxlan encapsulated packets (inner icmp packets)

```

root@docker-host-2:~# tcpdump -ni eth0 port 4789
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
19:04:42.806601 IP 172.16.24.4.54292 > 172.16.24.5.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.0.1.4 > 10.0.1.3: ICMP echo request, id 54, seq 0, length 64
19:04:42.806720 IP 172.16.24.5.57953 > 172.16.24.4.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.0.1.3 > 10.0.1.4: ICMP echo reply, id 54, seq 0, length 64
19:04:43.806583 IP 172.16.24.4.54292 > 172.16.24.5.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.0.1.4 > 10.0.1.3: ICMP echo request, id 54, seq 1, length 64
19:04:43.806674 IP 172.16.24.5.57953 > 172.16.24.4.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.0.1.3 > 10.0.1.4: ICMP echo reply, id 54, seq 1, length 64
19:04:44.806607 IP 172.16.24.4.54292 > 172.16.24.5.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.0.1.4 > 10.0.1.3: ICMP echo request, id 54, seq 2, length 64
19:04:44.806691 IP 172.16.24.5.57953 > 172.16.24.4.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.0.1.3 > 10.0.1.4: ICMP echo reply, id 54, seq 2, length 64
19:04:45.806923 IP 172.16.24.4.54292 > 172.16.24.5.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.0.1.4 > 10.0.1.3: ICMP echo request, id 54, seq 3, length 64
19:04:45.807009 IP 172.16.24.5.57953 > 172.16.24.4.4789: VXLAN, flags [I] (0x08), vni 4097
IP 10.0.1.3 > 10.0.1.4: ICMP echo reply, id 54, seq 3, length 64

```

# Challenge 7: DNS Container and Service resolution

```
# docker-host-2 (grab the container name)

root@docker-host-2:/home/localadmin# docker ps
CONTAINER ID   IMAGE                     COMMAND                  CREATED          STATUS          PORTS     NAMES
29eab7a74545   nginxdemos/hello:latest   "/docker-entrypoint.…"   49 minutes ago   Up 49 minutes   80/tcp    web-service.1.rbhms3k74l35jrfc6eq2wh28u

#
# docker-host-1 (ping container on docker-host-2 by name)
#

root@docker-host-1:/home/localadmin# docker ps
CONTAINER ID   IMAGE                     COMMAND                  CREATED          STATUS          PORTS     NAMES
c4411c1155d5   nginxdemos/hello:latest   "/docker-entrypoint.…"   48 minutes ago   Up 48 minutes   80/tcp    web-service.2.xy2qpwzu7nqcmut9o5mwc7m26
root@docker-host-1:/home/localadmin# docker service ps web-service
ID             NAME            IMAGE                     NODE            DESIRED STATE   CURRENT STATE            ERROR     PORTS
rbhms3k74l35   web-service.1   nginxdemos/hello:latest   docker-host-2   Running         Running 48 minutes ago
xy2qpwzu7nqc   web-service.2   nginxdemos/hello:latest   docker-host-1   Running         Running 48 minutes ago


root@docker-host-1:/home/localadmin# docker exec -it c4411c1155d5 sh

/ # ping web-service.1.rbhms3k74l35jrfc6eq2wh28u
PING web-service.1.rbhms3k74l35jrfc6eq2wh28u (10.0.1.11): 56 data bytes
64 bytes from 10.0.1.11: seq=0 ttl=64 time=1.300 ms
^C
--- web-service.1.rbhms3k74l35jrfc6eq2wh28u ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.300/1.300/1.300 ms
/ #

```
# Cleanup services, swarm cluster

```

root@docker-host-1:~# docker service ls
ID NAME MODE REPLICAS IMAGE PORTS
dimkgkean8tk web-service replicated 3/2 nginxdemos/hello:latest
root@docker-host-1:~# docker service rm web-service
web-service

root@docker-host-2:~# docker swarm leave
Node left the swarm.

root@docker-host-1:~# docker swarm leave
Error response from daemon: You are attempting to leave the swarm on a node that is participating as a manager. Removing the last manager erases all current state of the swarm. Use `--force` to ignore this message.
root@docker-host-1:~# docker swarm leave --force
Node left the swarm.

root@docker-host-1:~# docker network rm docker_gwbridge
docker_gwbridge

root@docker-host-2:~# docker network rm docker_gwbridge
docker_gwbridge
root@docker-host-2:~#

```

# Docker Installation - Troubleshooting

### I am unable to SSH to hosts, what do I need to do?

The automated deployment deploys Azure Bastion so you can connect to the VMs via the portal using Bastion. Alternatively the subnet hosting the VMs has a Network Security Group (NSG) attached called "Allow-tunnel-traffic" with a rule called 'allow-ssh-inbound' which is set to Deny by default. If you wish to allow SSH direct to the hosts, you can edit this rule and change the Source from 127.0.0.1 to your current public IP address. Afterwards, Remember to set the rule from Deny to Allow.

## I have followed the steps suggested abive, but I still cannot log in over SSH? 

Ensure that you have correctly edited the Network Security Group (NSG) to allow access for port 22. The rule will need your current public IP address and the rule needs to be amended to <b>'allow' rather than 'deny' </b> traffic. 

If you are using a Virtual Private Network (VPN) for outbound internet access, the public IP address you are assigned may differ from the public IP address that is used to connect on the internet, VPN services sometimes use public to public IP address NAT for outbound internet access for efficient use of their public IP addresses. This can be tricky to determine, and will mean that entering your public IP addresss on the NSG will not work. You may wish to open the rule to a 'range' of public IP addresses provided by the VPN service (for instance a.a.a.a/24). You should consider that this does mean that your service will become network reachable to any other VPN customers who are currently assigned an IP address in that range. 

Alternatively, you can check on the destination side (host in Azure) exactly what public IP address is connecting by running this iptables command and then viewing /var/log/syslog. You can use bastion to connect to the host.

``` iptables -I INPUT -p tcp -m tcp --dport 22 -m state --state NEW  -j LOG --log-level 1 --log-prefix "SSH Log" ```

### What are the logins for the VMs?

The credentials for the VMs are stored in an Azure keyvault.

### Are the passwords used cyptographically secure?

No. The passwords are generated deterministically and therefore should be changed on the VMs post deployment, to maximise security. They are auto generated in this way for convenience and are intended to support this environment as a 'Proof of Concept' or learning experience only and are not intended for production use.

### I cannot run the deployment - what is the ADuserID?

In order for the deployment to provision your signed-in user account access to the keyvault, you will need to provide your Azure Active Directory (AAD) signed-in user ObjectID. In order to retrieve this there are serveral methods. The Azure CLI and Azure Powershell methods are provided below. You can use the cloud shell to run the Azure CLI method, but for powershell you must run this from your own device using Azure Powershell module.

Note that older versions of az cli you may need to run the command with ```--query Objectid``` instead of ```--query id```

Azure CLI or Cloud Shell

```

az ad signed-in-user show --query id -o tsv

```

Azure Powershell

```

(Get-AzContext).Account.ExtendedProperties.HomeAccountId.Split('.')[0]

```

### How is docker installed on the host?

Docker is installed via a VM custom script extension, for reference the commands used are found in the following script - [cse.sh](/bicep/dockerhost/scripts/cse.sh)

This script is called automatically by the [dockerhost.json](json/dockerhost.json) ARM template on deployment.

## Are there any commands I can use to get the host's DNS, passwords and to change the Network Security Group (NSG) rule, instead of using the portal? 

Yes, below are commands that can be used to more quickly retieve this information. 

<b> Obtain password from keyvault (example for docker-host-1 host in default resource group) </b>

If you wish to retieve passwords for a different hostname, simply change the name property to match.

``` az keyvault secret show --name "docker-host-1-admin-password" --vault-name $(az keyvault list -g dockerhost --query "[].name" -o tsv) --query "value" -o tsv ```

If you receive an error on this command relating to a timeout and you are using Windows Subsystem for Linux and referencing the Windows based az, you should reference this github issue - https://github.com/Azure/azure-cli/issues/13573. Use powershell or cloud shell instead to mitigate this known bug.

<b> Obtain DNS label for public IP of host (example for docker-host-1 in default resource group) </b>

``` az network public-ip show -g dockerhost -n docker-host-1-nic-pip --query "dnsSettings.fqdn" -o tsv ```

<b> Change Network Security Rule (NSG) to allow SSH inbound from a specific public IP address </b>

You should change a.a.a.a to match your public IP address

``` az network nsg rule update -g dockerhost --nsg-name Allow-tunnel-traffic -n allow-ssh-inbound  --access allow --source-address-prefix "a.a.a.a" ```


# TODO

1. Enable encryption on overlay and capture packets
2. Create Attachable overlay network
3. Add Azure Public loadbalancer. Alternatively VM based load balancer (nginx or ha-proxy) can also be used in front of the swarm nodes

```

```
