## Azure AKS Basic /Kubenet Networking

This architecture demonstrates the connectivity architecture and traffic flows connecting Azure AKS environment with your on-premises environment.

## Azure Documentation links

2. [IP Address Planning](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#ip-address-availability-and-exhaustion)
3. [AKS Basic Networking](https://docs.microsoft.com/en-us/azure/aks/concepts-network#kubenet-basic-networking)
4. [AKS CNI Networking](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
5. [External Load Balancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard)

## Reference Architecture

### Basic Networking

![AKS Basic Networking](images/aks-basic.png)

Download Visio link here.

## Design Components and Planning

1. [AKS Basic Networking](https://docs.microsoft.com/en-us/azure/aks/concepts-network#kubenet-basic-networking)
   The kubenet networking option is the default configuration for AKS cluster creation. With kubenet:

- Nodes receive an IP address from the Azure virtual network subnet.
- Pods receive an IP address from a logically different address space than the nodes' Azure virtual network subnet.
- Network address translation (NAT) is then configured so that the pods can reach resources on the Azure virtual network.
- The source IP address of the traffic is translated to the node's primary IP address

Nodes use the kubenet Kubernetes plugin. You can:

Let the Azure platform create and configure the virtual networks for you, or
Choose to deploy your AKS cluster into an existing virtual network subnet

2. [IP Address Calculations](https://docs.microsoft.com/en-us/azure/aks/)
   kubenet - a simple /24 IP address range can support up to 251 nodes in the cluster (each Azure virtual network subnet reserves the first three IP addresses for management operations)
   This node count could support up to 27,610 pods (with a default maximum of 110 pods per node with kubenet)

   With kubenet, you can use a much smaller IP address range and be able to support large clusters and application demands. For example, even with a /27 IP address range on your subnet, you could run a 20-25 node cluster with enough room to scale or upgrade. This cluster size would support up to 2,200-2,750 pods (with a default maximum of 110 pods per node). The maximum number of pods per node that you can configure with kubenet in AKS is 110.

3. Node/Pod Limits
4. On-Prem routing
5. DNS Design
6. Inbound IP via Azure Load Balancer
7. Outbound IP via Azure load Balancer
   [External Load Balancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard)

Creates an Azure load balancer resource, configures an external IP address, and connects the requested pods to the load balancer backend pool. To allow customers' traffic to reach the application, load balancing rules are created on the desired ports.

Diagram showing Load Balancer traffic flow in an AKS cluster
![AKS Basic Networking](images/aks-loadbalancer.png)

## Design Validations

1. Route table
   ![Route table](images/basic-route-table.png)
2. IP Address Assignment

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

3. Node view

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

6. POD View

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

7. On Premises view

```

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

```

## Tools and Traffic Flows

1. kubectl command refernce
2. dnsutils pod (To run basic connectivity commands)
