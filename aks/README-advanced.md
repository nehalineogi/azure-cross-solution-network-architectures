## Azure AKS Advanced/Azure CNI Networking

This architecture demonstrates the connectivity architecture and traffic flows connecting Azure AKS environment with your on-premises environment.

## Reference Architecture

### Advanced/Azure CNI Networking

![AKS Advanced Networking](images/aks-advanced.png)

Download Visio link here.

## Azure Documentation links

2. [IP Address Planning](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#ip-address-availability-and-exhaustion)
3. [Configure AKS Advanced Networking](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
4. [AKS CNI Networking](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
5. [External Load Balancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard)

## Design Components and Planning

1. [AKS Advanced Networking](https://docs.microsoft.com/en-us/azure/aks/concepts-network#azure-cni-advanced-networking)
   The kubenet networking option is the default configuration for AKS cluster creation. With kubenet:

With Azure CNI, a common issue is the assigned IP address range is too small to then add additional nodes when you scale or upgrade a cluster. The network team may also not be able to issue a large enough IP address range to support your expected application demands. 3. Node/Pod Limits 4. On-Prem routing 5. DNS Design 6. Inbound IP via Azure Load Balancer 7. Outbound IP via Azure load Balancer
Unlike kubenet, traffic to endpoints in the same virtual network isn't NAT'd to the node's primary IP. The source address for traffic inside the virtual network is the pod IP. Traffic that's external to the virtual network still NATs to the node's primary IP.

2. [IP Address Calculations](https://docs.microsoft.com/en-us/azure/aks/)
   Azure CNI - that same basic /24 subnet range could only support a maximum of 8 nodes in the cluster
   This node count could only support up to 240 pods (with a default maximum of 30 pods per node with Azure CNI)up to 27,610 pods (with a default maximum of 110 pods per node with kubenet)

3. [External Load Balancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard)

Creates an Azure load balancer resource, configures an external IP address, and connects the requested pods to the load balancer backend pool. To allow customers' traffic to reach the application, load balancing rules are created on the desired ports.

Diagram showing Load Balancer traffic flow in an AKS cluster
![AKS Basic Networking](images/aks-loadbalancer.png)

4. [Internal Load Balancer](https://docs.microsoft.com/en-us/azure/aks/internal-lb)

If you'd like to specify IP address the the [link here](https://docs.microsoft.com/en-us/azure/aks/internal-lb#specify-an-ip-address)
If you would like to use a specific IP address with the internal load balancer, add the loadBalancerIP property to the load balancer YAML manifest. In this scenario, the specified IP address must reside in the same subnet as the AKS cluster and must not already be assigned to a resource. For example, you shouldn't use an IP address in the range designated for the Kubernetes subnet.

Check the [Prerequisites](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
The cluster identity used by the AKS cluster must have at least Network Contributor permissions on the subnet within your virtual network.

## Design Validations

1. Pre-assigned IP addresses for PODs based on --max-pods setting
   ![Route table](images/aks-advanced-pod-ip-assignment.png)
2. IP Address Assignment

```
k get nodes,pods,service -o wide -n colors-ns
NAME                                     STATUS   ROLES   AGE   VERSION    INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
node/aks-nodepool1-38290826-vmss000000   Ready    agent   10h   v1.19.11   172.16.240.4    <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-38290826-vmss000001   Ready    agent   10h   v1.19.11   172.16.240.35   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-38290826-vmss000002   Ready    agent   10h   v1.19.11   172.16.240.66   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure

NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE                                NOMINATED NODE   READINESS GATES
pod/red-deployment-5f589f64c6-7fbc2   1/1     Running   0          9h    172.16.240.50   aks-nodepool1-38290826-vmss000001   <none>           <none>
pod/red-deployment-5f589f64c6-s8cqm   1/1     Running   0          9h    172.16.240.11   aks-nodepool1-38290826-vmss000000   <none>           <none>
pod/red-deployment-5f589f64c6-sz2lq   1/1     Running   0          9h    172.16.240.76   aks-nodepool1-38290826-vmss000002   <none>           <none>

NAME                           TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE   SELECTOR
service/red-service            LoadBalancer   10.101.214.144   20.72.170.184   8080:31838/TCP   42m   app=red
service/red-service-internal   LoadBalancer   10.101.54.70     172.16.240.97   8080:32732/TCP   42m   app=red

```

3. Node view

```
k get nodes,pods -o wide
NAME                                     STATUS   ROLES   AGE   VERSION    INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
node/aks-nodepool1-38290826-vmss000000   Ready    agent   11m   v1.19.11   172.16.240.4    <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-38290826-vmss000001   Ready    agent   11m   v1.19.11   172.16.240.35   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-38290826-vmss000002   Ready    agent   11m   v1.19.11   172.16.240.66   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure

 ../kubectl-node_shell aks-nodepool1-38290826-vmss000002
spawning "nsenter-dh091t" on "aks-nodepool1-38290826-vmss000002"
If you don't see a command prompt, try pressing enter.
root@aks-nodepool1-38290826-vmss000002:/# ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0d:3a:1b:38:5d brd ff:ff:ff:ff:ff:ff
    inet 172.16.240.66/24 brd 172.16.240.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::20d:3aff:fe1b:385d/64 scope link
       valid_lft forever preferred_lft forever
3: enP20757s1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master eth0 state UP group default qlen 1000
    link/ether 00:0d:3a:1b:38:5d brd ff:ff:ff:ff:ff:ff
5: azv9b700506950@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 32:ce:cd:84:25:7a brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::30ce:cdff:fe84:257a/64 scope link
       valid_lft forever preferred_lft forever
7: azv2f011236414@if6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 02:33:6a:2d:9b:69 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::33:6aff:fe2d:9b69/64 scope link
       valid_lft forever preferred_lft forever
11: azvb3c61c3cba9@if10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether ae:c0:cf:25:98:1f brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::acc0:cfff:fe25:981f/64 scope link
       valid_lft forever preferred_lft forever
13: azv3c30acfc1be@if12: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 96:79:ae:18:fd:e4 brd ff:ff:ff:ff:ff:ff link-netnsid 4
    inet6 fe80::9479:aeff:fe18:fde4/64 scope link
       valid_lft forever preferred_lft forever
root@aks-nodepool1-38290826-vmss000002:/# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.16.240.1    0.0.0.0         UG    100    0        0 eth0
168.63.129.16   172.16.240.1    255.255.255.255 UGH   100    0        0 eth0
169.254.169.254 172.16.240.1    255.255.255.255 UGH   100    0        0 eth0
172.16.240.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
172.16.240.67   0.0.0.0         255.255.255.255 UH    0      0        0 azvb3c61c3cba9
172.16.240.69   0.0.0.0         255.255.255.255 UH    0      0        0 azv9b700506950
172.16.240.76   0.0.0.0         255.255.255.255 UH    0      0        0 azv3c30acfc1be
172.16.240.80   0.0.0.0         255.255.255.255 UH    0      0        0 azv2f011236414
root@aks-nodepool1-38290826-vmss000002:/# cat /etc/resolv.conf
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
root@aks-nodepool1-38290826-vmss000002:/# curl ifconfig.io
20.84.17.89

```

6. POD View

```
k exec -it dnsutils -- sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
10: eth0@if11: <BROADCAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP qlen 1000
    link/ether c2:76:6a:85:ee:09 brd ff:ff:ff:ff:ff:ff
    inet 172.16.240.67/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::c076:6aff:fe85:ee09/64 scope link
       valid_lft forever preferred_lft forever
/ # route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         169.254.1.1     0.0.0.0         UG    0      0        0 eth0
169.254.1.1     0.0.0.0         255.255.255.255 UH    0      0        0 eth0
/ # cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local 1grit5g0qs5exa0hhgg2i425ng.bx.internal.cloudapp.net
nameserver 10.101.0.10
options ndots:5

/ # wget -qO- ifconfig.me
20.84.17.89

```

7. On Premises view

```
k exec -it dnsutils -- sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
10: eth0@if11: <BROADCAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP qlen 1000
    link/ether c2:76:6a:85:ee:09 brd ff:ff:ff:ff:ff:ff
    inet 172.16.240.67/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::c076:6aff:fe85:ee09/64 scope link
       valid_lft forever preferred_lft forever
/ # wget 192.168.199.130:8000
Connecting to 192.168.199.130:8000 (192.168.199.130:8000)
index.html           100% |******************************************************************************************************************|   854   0:00:00 ETA
/ #

On Prem server:
nehali@nehali-laptop:~$ ifconfig eth5
eth5: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.199.130  netmask 255.255.255.128  broadcast 192.168.199.255
        inet6 fe80::d9b2:eb5a:4d72:3918  prefixlen 64  scopeid 0xfd<compat,link,site,host>
        ether 00:ff:96:aa:71:26  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
nehali@nehali-laptop:/mnt/c/Users/neneogi$ python3 -m http.server
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
172.16.240.66 - - [17/Jul/2021 11:00:47] "GET / HTTP/1.1" 200 -


```

8. Azure VM View

```
POD:
k exec -it dnsutils -- sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
inet 127.0.0.1/8 scope host lo
valid_lft forever preferred_lft forever
inet6 ::1/128 scope host
valid_lft forever preferred_lft forever
10: eth0@if11: <BROADCAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP qlen 1000
link/ether c2:76:6a:85:ee:09 brd ff:ff:ff:ff:ff:ff
inet 172.16.240.67/24 scope global eth0
valid_lft forever preferred_lft forever
inet6 fe80::c076:6aff:fe85:ee09/64 scope link
valid_lft forever preferred_lft forever
/ # wget 172.16.1.5:8000
Connecting to 172.16.1.5:8000 (172.16.1.5:8000)
wget: can't open 'index.html': File exists
/ # rm index.html
/ # wget 172.16.1.5:8000
Connecting to 172.16.1.5:8000 (172.16.1.5:8000)
index.html 100% |\***\*\*\*\*\*\*\***\*\*\***\*\*\*\*\*\*\***\*\*\*\*\***\*\*\*\*\*\*\***\*\*\***\*\*\*\*\*\*\***\*\*\***\*\*\*\*\*\*\***\*\*\***\*\*\*\*\*\*\***\*\*\*\*\***\*\*\*\*\*\*\***\*\*\***\*\*\*\*\*\*\***| 77 0:00:00 ETA
/ # exit

**VM in Azure (Same VNET as AKS-subnet)**

nehali@nn-linux-dev:~$ ifconfig eth0
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST> mtu 1500
inet 172.16.1.5 netmask 255.255.255.0 broadcast 172.16.1.255
inet6 fe80::20d:3aff:fe1c:8876 prefixlen 64 scopeid 0x20<link>
ether 00:0d:3a:1c:88:76 txqueuelen 1000 (Ethernet)
RX packets 79611619 bytes 21567157846 (21.5 GB)
RX errors 0 dropped 0 overruns 0 frame 0
TX packets 80391879 bytes 13317890087 (13.3 GB)
TX errors 0 dropped 0 overruns 0 carrier 0 collisions 0

nehali@nn-linux-dev:~$ python3 -m http.server
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
172.16.240.67 - - [17/Jul/2021 15:05:43] "GET / HTTP/1.1" 200 -
172.16.240.67 - - [17/Jul/2021 15:05:48] "GET / HTTP/1.1" 200 -

```

9. Traffic from On-Premises to Azure

```
nehali@nehali-laptop:~$ ifconfig eth5
eth5: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.199.2  netmask 255.255.255.128  broadcast 192.168.199.127
        inet6 fe80::d9b2:eb5a:4d72:3918  prefixlen 64  scopeid 0xfd<compat,link,site,host>
        ether 00:ff:96:aa:71:26  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

nehali@nehali-laptop:~$ curl  http://172.16.240.97:8080
red
nehali@nehali-laptop:~$ curl  172.16.240.50:8080
red

```

## Validations

### External Service

```
k describe service red-service -n colors-ns
Name:                     red-service
Namespace:                colors-ns
Labels:                   <none>
Annotations:              <none>
Selector:                 app=red
Type:                     LoadBalancer
IP Families:              <none>
IP:                       10.101.214.144
IPs:                      <none>
LoadBalancer Ingress:     20.72.170.184
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31838/TCP
Endpoints:                172.16.240.11:8080,172.16.240.50:8080,172.16.240.76:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  21m   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   21m   service-controller  Ensured load balancer

```

### Internal Service

```
 k describe service red-service-internal -n colors-ns
Name:                     red-service-internal
Namespace:                colors-ns
Labels:                   <none>
Annotations:              service.beta.kubernetes.io/azure-load-balancer-internal: true
Selector:                 app=red
Type:                     LoadBalancer
IP Families:              <none>
IP:                       10.101.54.70
IPs:                      <none>
LoadBalancer Ingress:     172.16.240.97
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  32732/TCP
Endpoints:                172.16.240.11:8080,172.16.240.50:8080,172.16.240.76:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age                From                Message
  ----    ------                ----               ----                -------
  Normal  EnsuringLoadBalancer  47s (x2 over 21m)  service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   46s (x2 over 19m)  service-controller  Ensured load balancer

```

## Tools and Traffic Flows

1. kubectl command refernce
2. dnsutils pod (To run basic connectivity commands)
3. ssh into AKS nodes
