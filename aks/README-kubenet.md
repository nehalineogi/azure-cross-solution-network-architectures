## Azure AKS Basic /Kubenet Networking

This architecture uses the for AKS Basic/Kubenet Network Model. Observe that the AKS Nodes receive IP address from Azure subnet (NODE CIDR) and Pod receive an IP address from a POD CIDR different from the node network. Note the traffic flows for inbound connectivity to AKS via Internal and External Load balancers.This architecture also demonstrates connectivity and flows to and from on-premises. Outbound flows from AKS pods to internet traverse the Azure load balancer. There are other design options to egress via Azure firewall/NVA or Azure NAT Gateway.

## Reference Architecture

#### Basic/Kubenet Networking

![AKS Basic Networking](images/aks-basic.png)

Download Visio link here.

## Azure Documentation links

1. [Choosing a network model](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#choose-a-network-model-to-use)
2. [IP Address Planning](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#ip-address-availability-and-exhaustion)
3. [AKS Basic Networking](https://docs.microsoft.com/en-us/azure/aks/concepts-network#kubenet-basic-networking)
4. [AKS CNI Design Considerations](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#limitations--considerations-for-kubenet)
5. [AKS Services](https://docs.microsoft.com/en-us/azure/aks/concepts-network#services)

## Design Components and Planning

#### [Design Considerations](https://docs.microsoft.com/en-us/azure/aks/concepts-network#kubenet-basic-networking)

The kubenet networking option is the default configuration for AKS cluster creation.Some design considerations for Kubenet

- Nodes receive an IP address from the Azure subnet (NODE CIDR). You can deploy these nodes in existing Azure VNET or a new VNET.
- Pods receive an IP address from a POD CIDR which is logically different address space than the NODE CIDR. Direct pod addressing isn't supported for kubenet due to kubenet design.
- Route tables and user-defined routes are required for using kubenet, which adds complexity to operations.
- AKS Uses Network address translation (NAT) so that the pods can reach resources on the Azure virtual and on-prem resources. The source IP address of the traffic is translated to the node's primary IP address
- Inbound connectivity using Internal or External load Balancer
- Use Kubnet when you have limited IP address space on Azure VNET
- Most of the pod communication is within the cluster.
- Azure Network Policy is not supported but calico policies are supported

#### [IP Address Calculations](https://docs.microsoft.com/en-us/azure/aks/)

kubenet - a simple /24 IP address range can support up to 251 nodes in the cluster (each Azure virtual network subnet reserves the first three IP addresses for management operations). Each Node can have a maximum of 110 pods/node. This node count could support up to 27,610 pods (251x110)

With kubenet, you can use a much smaller IP address range and be able to support large clusters and application demands. For example, even with a /27 IP address range on your subnet, you could run a 20-25 node cluster with enough room to scale or upgrade. This cluster size would support up to 2,200-2,750 pods (with a default maximum of 110 pods per node). The maximum number of pods per node that you can configure with kubenet in AKS is 110.

#### Routing to and from onpremises

```
Outbound from AKS to On-Premises
Note: On-Premise sees the Node IP
python3 -m http.server
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
172.16.239.6 - - [16/Jul/2021 14:51:52] "GET / HTTP/1.1" 200 -
172.16.239.6 - - [16/Jul/2021 14:51:59] "GET / HTTP/1.1" 200 -
172.16.239.6 - - [16/Jul/2021 14:53:00] "GET / HTTP/1.1" 200 -
172.16.239.6 - - [16/Jul/2021 14:53:04] "GET / HTTP/1.1" 200 -

From On-Prem to AKS use the internal load balancer over VPN/ExpressRoute
nehali@nehali-laptop:~$ curl  172.16.239.7:8080
red

```

####DNS Design
Azure Subnet can use custom DNS or Azure Default DNS. Core DNS can be used along with Azure DNS.
####Inbound Services

AKS Uses [services](https://docs.microsoft.com/en-us/azure/aks/concepts-network#services) to provide inbound connectivity to pods insides the AKS cluster. The three service types are (Cluster IP, NodePort and LoadBalancer). In the archictecture above, the service type is LoadBalancer. AKS Creates an Azure load balancer resource, configures an external IP address, and connects the requested pods to the load balancer backend pool. To allow customers' traffic to reach the application, load balancing rules are created on the desired ports.

Diagram showing Load Balancer traffic flow in an AKS cluster
![AKS Basic Networking](images/aks-loadbalancer.png)

####Outbound to Internet Flows
Outbound traffic from the pods to the Internet flows via Azure External load Balancer (Separate article showing the outbound via Azure firwall/NVA/NAT)

## Design Validations

**1. IP Address Assignment**

The cluster was created using this command line. Note the Node CIDR is 172.16.240.0/24 (AKS-Subnet)

```
az aks create \
    --resource-group $RG \
    --name $AKSCLUSTER \
    --node-count 3 \
    --generate-ssh-keys \
    --enable-addons monitoring  \
    --dns-name-prefix $AKSDNS \
    --network-plugin $PLUGIN \
    --service-cidr 10.101.0.0/16 \
    --dns-service-ip 10.101.0.10 \
    --pod-cidr 10.244.0.0/16 \
    --docker-bridge-address 172.20.0.1/16 \
    --vnet-subnet-id $SUBNET_ID \
    --enable-managed-identity \
    --attach-acr $MYACR \
    --max-pods 30 \
    --verbose

```

```
NAME                                     STATUS   ROLES   AGE    VERSION    INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
node/aks-nodepool1-62766439-vmss000000   Ready    agent   7h8m   v1.19.11   172.16.239.4   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-62766439-vmss000001   Ready    agent   7h8m   v1.19.11   172.16.239.5   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-62766439-vmss000002   Ready    agent   7h8m   v1.19.11   172.16.239.6   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure

NAME                                  READY   STATUS    RESTARTS   AGE     IP           NODE                                NOMINATED NODE   READINESS GATES
pod/red-deployment-5f589f64c6-75t5f   1/1     Running   0          2m31s   10.244.1.6   aks-nodepool1-62766439-vmss000002   <none>           <none>
pod/red-deployment-5f589f64c6-lvqvs   1/1     Running   0          2m31s   10.244.0.5   aks-nodepool1-62766439-vmss000001   <none>           <none>
pod/red-deployment-5f589f64c6-wlqmp   1/1     Running   0          2m31s   10.244.2.7   aks-nodepool1-62766439-vmss000000   <none>           <none>

NAME                  TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE     SELECTOR
service/red-service   LoadBalancer   10.101.198.78   20.72.185.240   8080:31876/TCP   2m31s   app=red

```

**2. Route table**
Note the POD CIDR is : --pod-cidr 10.244.0.0/16.
![Route table](images/basic-route-table.png)

**3. Node view**

Node inherits the DNS from the Azure DNS.

```
../kubectl-node_shell aks-nodepool1-62766439-vmss000002
spawning "nsenter-xdz3o0" on "aks-nodepool1-62766439-vmss000002"
If you don't see a command prompt, try pressing enter.
root@aks-nodepool1-62766439-vmss000002:/# ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0d:3a:9e:51:52 brd ff:ff:ff:ff:ff:ff
    inet 172.16.239.6/24 brd 172.16.239.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::20d:3aff:fe9e:5152/64 scope link
       valid_lft forever preferred_lft forever
3: enP58592s1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master eth0 state UP group default qlen 1000
    link/ether 00:0d:3a:9e:51:52 brd ff:ff:ff:ff:ff:ff
4: cbr0: <BROADCAST,MULTICAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether ae:d6:45:3d:6f:ec brd ff:ff:ff:ff:ff:ff
    inet 10.244.1.1/24 scope global cbr0
       valid_lft forever preferred_lft forever
    inet6 fe80::acd6:45ff:fe3d:6fec/64 scope link
       valid_lft forever preferred_lft forever
5: veth482424ea@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master cbr0 state UP group default
    link/ether 56:e5:eb:58:fb:44 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::54e5:ebff:fe58:fb44/64 scope link
       valid_lft forever preferred_lft forever
6: veth93e12bb4@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master cbr0 state UP group default
    link/ether 62:e2:4d:42:76:61 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::60e2:4dff:fe42:7661/64 scope link
       valid_lft forever preferred_lft forever
7: vethd95f569f@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master cbr0 state UP group default
    link/ether 3e:cb:84:b2:f7:f0 brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::3ccb:84ff:feb2:f7f0/64 scope link
       valid_lft forever preferred_lft forever
8: vethe75d7104@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master cbr0 state UP group default
    link/ether 62:ee:97:dc:fd:75 brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::60ee:97ff:fedc:fd75/64 scope link
       valid_lft forever preferred_lft forever
9: vethdd2875f0@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master cbr0 state UP group default
    link/ether 3a:cb:a7:80:87:2f brd ff:ff:ff:ff:ff:ff link-netnsid 4
    inet6 fe80::38cb:a7ff:fe80:872f/64 scope link
       valid_lft forever preferred_lft forever
root@aks-nodepool1-62766439-vmss000002:/# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.16.239.1    0.0.0.0         UG    100    0        0 eth0
10.244.1.0      0.0.0.0         255.255.255.0   U     0      0        0 cbr0
168.63.129.16   172.16.239.1    255.255.255.255 UGH   100    0        0 eth0
169.254.169.254 172.16.239.1    255.255.255.255 UGH   100    0        0 eth0
172.16.239.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
root@aks-nodepool1-62766439-vmss000002:/# more /etc/resolv.conf
# This file is managed by man:systemd-resolved(8). Do not edit.
#
# This is a dynamic resolv.conf file for connecting local clients directly to
# all known uplink DNS servers. This file lists all configured search domains.
#
# Third party programs must not access this file directly, but only through the
# symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a different way,
# replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.

nameserver 168.63.129.16
search 1grit5g0qs5exa0hhgg2i425ng.bx.internal.cloudapp.net

root@aks-nodepool1-62766439-vmss000002:/# brctl show cbr0
bridge name     bridge id               STP enabled     interfaces
cbr0            8000.aed6453d6fec       no              veth482424ea
                                                        veth93e12bb4
                                                        vethd95f569f
                                                        vethdd2875f0
                                                        vethe75d7104

```

**6. POD View**

The curl output showing the egress from POD to Internet via load balancer IP.

```
k get pods -o wide
NAME       READY   STATUS    RESTARTS   AGE   IP           NODE                                NOMINATED NODE   READINESS GATES
dnsutils   1/1     Running   0          10m   10.244.1.5   aks-nodepool1-62766439-vmss000002   <none>           <none>

k exec -it dnsutils sh
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.

/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: eth0@if8: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 9a:40:c8:86:07:f7 brd ff:ff:ff:ff:ff:ff
    inet 10.244.1.5/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::9840:c8ff:fe86:7f7/64 scope link
       valid_lft forever preferred_lft forever
/ # route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.244.1.1      0.0.0.0         UG    0      0        0 eth0
10.244.1.0      0.0.0.0         255.255.255.0   U     0      0        0 eth0

/ # wget -qO- ifconfig.me
20.81.108.198

```

**7. On Premises view**

Initiate Outbound traffic from AKS to On-Premises. Note that On-Premise sees the Node IP

```

Source AKS:
Exec into AKS Pod
k get pods -o wide
NAME       READY   STATUS    RESTARTS   AGE     IP           NODE                                NOMINATED NODE   READINESS GATES
dnsutils   1/1     Running   6          6h55m   10.244.1.5   aks-nodepool1-62766439-vmss000002   <none>           <none>
 k get nodes -o wide
NAME                                STATUS   ROLES   AGE     VERSION    INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-nodepool1-62766439-vmss000000   Ready    agent   7h21m   v1.19.11   172.16.239.4   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
aks-nodepool1-62766439-vmss000001   Ready    agent   7h22m   v1.19.11   172.16.239.5   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
aks-nodepool1-62766439-vmss000002   Ready    agent   7h22m   v1.19.11   172.16.239.6   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
 k exec -it dnsutils -- sh
/ # wget 192.168.199.130:8000
Connecting to 192.168.199.130:8000 (192.168.199.130:8000)
index.html           100% |*********************************************************************************************************************|   854   0:00:00 ETA
/ # exit

Destination On-Premises:

python3 -m http.server
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
172.16.239.6 - - [16/Jul/2021 14:51:52] "GET / HTTP/1.1" 200 -
172.16.239.6 - - [16/Jul/2021 14:51:59] "GET / HTTP/1.1" 200 -
172.16.239.6 - - [16/Jul/2021 14:53:00] "GET / HTTP/1.1" 200 -
172.16.239.6 - - [16/Jul/2021 14:53:04] "GET / HTTP/1.1" 200 -

From On-Prem to AKS
nehali@nehali-laptop:~$ curl  172.16.239.7:8080
red

```

## TODO

1. Reference link to egress via firewall/NAT gateway
2. Section for Calico Policy
