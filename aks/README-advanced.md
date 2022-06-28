## Azure AKS Advanced/CNI Networking

This architecture uses the AKS Advanced (CNI) Network Model. 

Observe that the AKS Nodes **and** Pods receive IP address from Azure subnet (NODE CIDR). Note the traffic flows for inbound connectivity to AKS via internal and public load balancers.This architecture also demonstrates connectivity and flows to and from on-premises. On-premises network can directly reach both node and pod networks. Outbound flows from AKS pods to internet traverse the Azure load balancer. There are other design options to egress via Azure firewall/NVA or Azure NAT Gateway.

## Reference Architecture

### Advanced/Azure CNI Networking

![AKS Advanced Networking](images/aks-advanced.png)

Download [Multi-tab Visio](aks-all-reference-architectures-visio.vsdx) and [PDF](aks-all-reference-architectures-PDF.pdf)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnehalineogi%2Fazure-cross-solution-network-architectures%2Fmain%2Faks%2Fjson%2Faks-cni.json)

# Quickstart deployment
### Task 1: Start Deployment

1. Click Deploy to Azure button above and supply the signed-in user ID from step 2.

2. Open Cloud Shell and retrieve your signed-in user ID below (this is used to apply access to Keyvault).

```
az ad signed-in-user show --query id -o tsv
```

3. Using Azure Bastion, log in to the VMs using the username `localadmin` and passwords from keyvault.

Note: SSH directly to the VMs is possible, however, it is best security practice to not expose VMs to the internet for SSH. 
It is not uncommon for tenants that are managed by corporations to restrict the use of SSH directly from the internet. More information can be found in the [FAQ](https://github.com/nehalineogi/azure-cross-solution-network-architectures/blob/main/aks/README-advanced.md#faqtroubleshooting).

4. log in as root with command ```sudo su```

5. Note that you may have different IP addresses and interfaces on your environment than the screenshots throughout this series, this is expected.
## Azure Documentation links

1. [Choose a Network Model](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#choose-a-network-model-to-use)
2. [IP Address Planning](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#ip-address-availability-and-exhaustion)
3. [Configure AKS Advanced Networking](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
4. [AKS CNI Networking](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
5. [External Load Balancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard)

## Design Considerations

Network Model Comparison from [Azure Documentation](https://docs.microsoft.com/en-us/azure/aks/concepts-network#compare-network-models)

![AKS Advanced Networking](images/network-model-comparison.png)

[Key Design considerations](https://docs.microsoft.com/en-us/azure/aks/concepts-network#azure-cni-advanced-networking)

The CNI networking option is used during AKS cluster creation. 

Components with blue dotted lines in the diagram above are automatically deployed and a three node AKS cluster is deployed in CNI mode by default. 

The NODE CIDR is 172.16.240.0/24 (aks-node-subnet) and PODs will use IPs from the same subnet.

1. Nodes and PODs get IPs from the same subnet - this could lead to IP exhaustion issue and need for a large IP space to be available.
2. Pods get full virtual network connectivity and can be directly reached via their private IP address from connected networks
3. Needs a large available IP address space. Common consideration is the assigned IP address range is too small to then add additional nodes when you scale or upgrade a cluster.
4. The network team may also not be able to issue a large enough IP address range to support your expected application demands.
5. There is no user defined routes for pod connectivity.
6. Azure Network Policy support


### [IP Address Calculations](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#ip-address-availability-and-exhaustion)
   With Azure CNI network model, that same /24 subnet (251 usable IPs) range could only support a maximum of 8 nodes in the cluster
   This node count could only support up to 240 (8x30) pods (with a default maximum of 30 pods per node with Azure CNI).

   If you have 8 nodes and 30 pods, you'll use up 8x30=240 IP addresses.

   Note: Maximum nodes per cluster with Virtual Machine Scale Sets and Standard Load Balancer SKU. Limits link [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-kubernetes-service-limits))

### [Public Load Balancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard)

AKS uses [services](https://docs.microsoft.com/en-us/azure/aks/concepts-network#services) to provide inbound connectivity to pods insides the AKS cluster. The three service types are (Cluster IP, NodePort and LoadBalancer). In the archictecture above, the service type is LoadBalancer. AKS Creates an Azure load balancer resource, configures an external IP address, and connects the requested pods to the load balancer backend pool. To allow customers' traffic to reach the application, load balancing rules are created on the desired ports. Internal load balancer and external load balancer can be used at the same time. All egress traffic from the NODEs and PODs use the loadbalancer IP for outbound traffic.

Diagram showing Load Balancer traffic flow in an AKS cluster <br />

![AKS Basic Networking](images/aks-loadbalancer.png)

4. [Internal Load Balancer](https://docs.microsoft.com/en-us/azure/aks/internal-lb)
   Internal load balancer can be used to expose the services. This exposed IP will reside on the AKS-subnet. If you'd like to specify a specific IP address following instructions in [link here](https://docs.microsoft.com/en-us/azure/aks/internal-lb#specify-an-ip-address).

# Deployment Validations

These steps will deploy a single test pod. You should run all these commands from a cloud shell for best results.

1. Obtain the cluster credentials to log in to kubectl (if you did not use the default, replace resource-group with your specified resource group name).

Note: If you get a warning "an object named MyAKSCluster already exists in your kubeconfig file, Overwrite? ", you should overwrite to obtain fresh credentials.

```shaun@Azure:~$ az aks get-credentials --resource-group aks-CNI --name myAKSCluster```

2. Open cloud shell and clone the reposity (if you haven't already from a previous lab)

```shaun@Azure:~$ git clone https://github.com/nehalineogi/azure-cross-solution-network-architectures```

3. Navigate to the dnsutils directory 

```shaun@Azure:~$ cd azure-cross-solution-network-architectures/aks/yaml/dns```

4. Deploy a simple pod

```shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/dns$ kubectl apply -f dnsutils.yaml```

5. Check pod is running successfully 

```shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/dns$ kubectl get pods -o wide```

6. Move to repo base directory 

```shaun@Azure:~/azure-cross-solution-network-architectures$ cd ../../.. ```

#### IP Address Assignment

Pre-assigned IP addresses for PODs based on --max-pods=30 setting setting
Screen capture of the Azure VNET and AKS subnet:

![IP Assignment](images/aks-advanced-pod-IP-assignment.png)

Note that AKS nodes and pods get IPs from the same AKS subnet

#### Verify nodes

```
shaun@Azure:~/azure-cross-solution-network-architectures$ kubectl get nodes -o wide

NAME                                 STATUS   ROLES   AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-agentpool1-19014455-vmss000000   Ready    agent   37m   v1.22.6   172.16.240.4    <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2
aks-agentpool1-19014455-vmss000001   Ready    agent   37m   v1.22.6   172.16.240.35   <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2
aks-agentpool1-19014455-vmss000002   Ready    agent   37m   v1.22.6   172.16.240.66   <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2

```

# Challenge 1: Deploy Pods and Internal Service

In this challenge you will deploy pods and configure an internal service using an existing yaml definition in the repository. Notice how the pods are placed on the three nodes using the IP addresses from the AKS VNet, and spread over the three VMSS instances that make the AKS cluster. 

```
#
# Create a namespace for the service, and apply the configuration
#
shaun@Azure:~/azure-cross-solution-network-architectures$ kubectl create ns colors-ns
shaun@Azure:~/azure-cross-solution-network-architectures$ cd aks/yaml/colors-ns
shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl apply -f red-internal-service.yaml
shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl get pods,services -o wide -n colors-ns

NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE                                 NOMINATED NODE   READINESS GATES
pod/red-deployment-5f589f64c6-9tw8x   1/1     Running   0          7s    172.16.240.31   aks-agentpool1-19014455-vmss000000   <none>           <none>
pod/red-deployment-5f589f64c6-bnvkq   1/1     Running   0          7s    172.16.240.70   aks-agentpool1-19014455-vmss000002   <none>           <none>
pod/red-deployment-5f589f64c6-c4xc9   1/1     Running   0          7s    172.16.240.51   aks-agentpool1-19014455-vmss000001   <none>           <none>

NAME                           TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE   SELECTOR
service/red-service-internal   LoadBalancer   10.101.116.163   <pending>     8080:30889/TCP   7s    app=red

shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl describe service red-service-internal -n colors-ns

Name:                     red-service-internal
Namespace:                colors-ns
Labels:                   <none>
Annotations:              service.beta.kubernetes.io/azure-load-balancer-internal: true
Selector:                 app=red
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.101.116.163
IPs:                      10.101.116.163
LoadBalancer Ingress:     172.16.240.97
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30889/TCP
Endpoints:                172.16.240.31:8080,172.16.240.51:8080,172.16.240.70:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age    From                Message
  ----    ------                ----   ----                -------
  Normal  EnsuringLoadBalancer  2m58s  service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   2m31s  service-controller  Ensured load balancer

```

# Challenge 2: Verify service from on-premises 

From the VPN server on-premise (vpnvm) log in via bastion (password in keyvault) and try to curl the service via the LoadBalancer Ingress:

```
localadmin@vpnvm:~$ curl http://172.16.240.97:8080/
red

```

# Challenge 3: Deploy Pods and External Service

```

shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl apply -f red-external-lb.yaml
deployment.apps/red-deployment unchanged
service/red-service-external created
shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl get pods,services -o wide -n colors-ns

NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE                                 NOMINATED NODE   READINESS GATES
pod/red-deployment-5f589f64c6-9tw8x   1/1     Running   0          10m   172.16.240.31   aks-agentpool1-19014455-vmss000000   <none>           <none>
pod/red-deployment-5f589f64c6-bnvkq   1/1     Running   0          10m   172.16.240.70   aks-agentpool1-19014455-vmss000002   <none>           <none>
pod/red-deployment-5f589f64c6-c4xc9   1/1     Running   0          10m   172.16.240.51   aks-agentpool1-19014455-vmss000001   <none>           <none>

NAME                           TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE   SELECTOR
service/red-service-external   LoadBalancer   10.101.216.194   20.90.217.4     8080:31308/TCP   32s   app=red
service/red-service-internal   LoadBalancer   10.101.116.163   172.16.240.97   8080:30889/TCP   10m   app=red

shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl describe service red-service-external -n colors-ns

Name:                     red-service-external
Namespace:                colors-ns
Labels:                   <none>
Annotations:              <none>
Selector:                 app=red
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.101.216.194
IPs:                      10.101.216.194
LoadBalancer Ingress:     20.90.217.4
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31308/TCP
Endpoints:                172.16.240.31:8080,172.16.240.51:8080,172.16.240.70:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  31m   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   31m   service-controller  Ensured load balancer

```
# Challenge 4: Validate Network Security Group (NSG)

### NSG Validation

AKS automatically applies an NSG to the interfaces of the node pool VMSS instances. Check in the portal for an NSG beginning aks-agentpoolxxxx in the resource group and find the NSG rule automatically written to accept connections on port 8080. You can test this from the VPN VM or from your own device to check the application is accessible.

# Challenge 5: Validate view from AKS nodes, pods and on-premise

In this challenge you will check the view from each type of AKS component. 
### AKS Node view

Note that node inherits the DNS from the Azure VNET DNS setting. The outbound IP for the node is the public load balancer outbound SNAT.

```
shaun@Azure:~$  kubectl get nodes,pods -o wide
NAME                                      STATUS   ROLES   AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
node/aks-agentpool1-19014455-vmss000000   Ready    agent   129m   v1.22.6   172.16.240.4    <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2
node/aks-agentpool1-19014455-vmss000001   Ready    agent   129m   v1.22.6   172.16.240.35   <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2
node/aks-agentpool1-19014455-vmss000002   Ready    agent   129m   v1.22.6   172.16.240.66   <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2

NAME           READY   STATUS    RESTARTS      AGE   IP              NODE                                 NOMINATED NODE   READINESS GATES
pod/dnsutils   1/1     Running   1 (34m ago)   94m   172.16.240.55   aks-agentpool1-19014455-vmss000001   <none>           <none>

Create shell connection to one of the nodes using the commands below. Replace with your own AKS node names. For further instructions on this process or to learn more see [Connect to AKS cluster nodes for maintenance or troubleshooting](https://docs.microsoft.com/en-us/azure/aks/node-access) 

shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl get nodes

NAME                                 STATUS   ROLES   AGE    VERSION
aks-agentpool1-19014455-vmss000000   Ready    agent   133m   v1.22.6
aks-agentpool1-19014455-vmss000001   Ready    agent   133m   v1.22.6
aks-agentpool1-19014455-vmss000002   Ready    agent   133m   v1.22.6

shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl debug nodes/aks-agentpool1-19014455-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
Creating debugging pod node-debugger-aks-agentpool1-19014455-vmss000000-8kln4 with container debugger on node aks-agentpool1-19014455-vmss000000.
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

# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.16.240.1    0.0.0.0         UG    100    0        0 eth0
168.63.129.16   172.16.240.1    255.255.255.255 UGH   100    0        0 eth0
169.254.169.254 172.16.240.1    255.255.255.255 UGH   100    0        0 eth0
172.16.240.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
172.16.240.11   0.0.0.0         255.255.255.255 UH    0      0        0 azv8ac2e35e029
172.16.240.13   0.0.0.0         255.255.255.255 UH    0      0        0 azvea9ed1a8167
172.16.240.29   0.0.0.0         255.255.255.255 UH    0      0        0 azv6de87fdf838
172.16.240.31   0.0.0.0         255.255.255.255 UH    0      0        0 azv4bc020cf487

# cat /etc/resolv.conf
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
search pzlew5cwozpurboboh2bo2wgue.zx.internal.cloudapp.net

```
### AKS Pod view

Note that the outbound IP of the POD is the public load balancer SNAT.

```
shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl exec -it dnsutils -- sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
7: eth0@if8: <BROADCAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP qlen 1000
    link/ether da:79:8d:ef:5a:38 brd ff:ff:ff:ff:ff:ff
    inet 172.16.240.55/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::d879:8dff:feef:5a38/64 scope link 
       valid_lft forever preferred_lft forever

/ # route -n 
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         169.254.1.1     0.0.0.0         UG    0      0        0 eth0
169.254.1.1     0.0.0.0         255.255.255.255 UH    0      0        0 eth0

/ # cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local pzlew5cwozpurboboh2bo2wgue.zx.internal.cloudapp.net
nameserver 10.101.0.10
options ndots:5

/ # wget -qO- ifconfig.me
20.84.17.89

```

### On Premises view

Initiate Outbound traffic from AKS to On-Premises. Note that on-premise sees the node IP. You will initiate a simple HTTP server on the VPN VM (vpnvm) and see the outbound IP call from the dnsutil pod on AKS to the vpn vm HTTP server. 

**From AKS to On-premises**
Note: On-Premises server sees the node IP.

Log in to the VPN VM and start the server 

```
localadmin@vpnvm:~$ python3 -m http.server

```
From cloud shell, create a shell connection to the dnsutil pod and initiate a connection

```
shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl exec -it dnsutils -- sh

/ # wget 192.168.199.4:8000
Connecting to 192.168.199.4:8000 (192.168.199.4:8000)
index.html           100% |************************************************************************************************************************************************************************************************************|   575   0:00:00 ETA


From on-premise VPN VM:
root@vpnvm:/home/localadmin# python3 -m http.server
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
172.16.240.35 - - [28/Jun/2022 15:17:58] "GET / HTTP/1.1" 200 -

```

**From On-Premises to AKS:**
For ingress, note that the AKS pods are directly reachable using their own IP address from on-premise. Here you can access the red pod via its assigned POD IP. 

```
shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl get pods,services -o wide -n colors-ns

NAME                                  READY   STATUS    RESTARTS   AGE    IP              NODE                                 NOMINATED NODE   READINESS GATES
pod/red-deployment-5f589f64c6-9tw8x   1/1     Running   0          122m   172.16.240.31   aks-agentpool1-19014455-vmss000000   <none>           <none>
pod/red-deployment-5f589f64c6-bnvkq   1/1     Running   0          122m   172.16.240.70   aks-agentpool1-19014455-vmss000002   <none>           <none>
pod/red-deployment-5f589f64c6-c4xc9   1/1     Running   0          122m   172.16.240.51   aks-agentpool1-19014455-vmss000001   <none>           <none>

```
From vpn vm to a pod in the 'red' service:
```
localadmin@vpnvm:~$ curl http://172.16.240.31:8080/
red

```

### Azure VM View

For this challenge you will need to deploy a VM onto the same VNet as the AKS nodes. You can then run the same steps as above, but instead of using the VPN VM on-premise, you can use the VM on the same subnet. Note: Azure VM on the same VNET sees the actual POD IP, not the NODE IP!

### External Service

Note the Endpoints are up. Node Type:LoadBalancer and exposed IP is public

```
shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl describe service red-service-external -n colors-ns
Name:                     red-service-external
Namespace:                colors-ns
Labels:                   <none>
Annotations:              <none>
Selector:                 app=red
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.101.216.194
IPs:                      10.101.216.194
LoadBalancer Ingress:     20.90.217.4
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31308/TCP
Endpoints:                172.16.240.31:8080,172.16.240.51:8080,172.16.240.70:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

```

### Internal Service

Note the type: Load balancer and the exposed IP is private

```
shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl describe service red-service-internal -n colors-ns

Name:                     red-service-internal
Namespace:                colors-ns
Labels:                   <none>
Annotations:              service.beta.kubernetes.io/azure-load-balancer-internal: true
Selector:                 app=red
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.101.116.163
IPs:                      10.101.116.163
LoadBalancer Ingress:     172.16.240.97
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30889/TCP
Endpoints:                172.16.240.31:8080,172.16.240.51:8080,172.16.240.70:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

```

# FAQ/Troubleshooting

### Steps to enable SSH to the docker VMs.

1. Locate the Network Security Group (NSG) called "Allow-tunnel-traffic" and amend rule "allow-ssh-inbound" - change 127.0.0.1 to your current public IP address and change rule from Deny to Allow

2. Retrieve the public IP address (or DNS label) for each VM

3. Retrieve the VM passwords from the keyvault.

4. SSH to your VMs

```
ssh localadmin@[VM Public IP or DNS]
```

5. log in as root with command ```sudo su```

## I have followed the steps suggested above, but I still cannot log in over SSH? 

Ensure that you have correctly edited the Network Security Group (NSG) to allow access for port 22. The rule will need your current public IP address and the rule needs to be amended to <b>'allow' rather than 'deny' </b> traffic. 

If you are using a Virtual Private Network (VPN) for outbound internet access, the public IP address you are assigned may differ from the public IP address that is used to connect on the internet, VPN services sometimes use public to public IP address NAT for outbound internet access for efficient use of their public IP addresses. This can be tricky to determine, and will mean that entering your public IP addresss on the NSG will not work. You may wish to open the rule to a 'range' of public IP addresses provided by the VPN service (for instance a.a.a.a/24). You should consider that this does mean that your service will become network reachable to any other VPN customers who are currently assigned an IP address in that range. 

Alternatively, you can check on the destination side (host in Azure) exactly what public IP address is connecting by running this iptables command and then viewing /var/log/syslog. You can use bastion to connect to the host.

``` iptables -I INPUT -p tcp -m tcp --dport 22 -m state --state NEW  -j LOG --log-level 1 --log-prefix "SSH Log" ```

Finally, check that your company is not blocking or restricting port 22 access to the VMs.

## What are the logins for the VMs?

The credentials for the VMs are stored in an Azure keyvault.

## Are the passwords used cyptographically secure?

No. The passwords are generated deterministically and therefore should be changed on the VMs post deployment, to maximise security. They are auto generated in this way for convenience and are intended to support this environment as a 'Proof of Concept' or learning experience only and are not intended for production use.

## I cannot run the deployment - what is the ADuserID?

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

## How are OS level application automatically installed on the VMs?

OS level configuration is applied via a VM custom script extension, for reference the commands used are found in the following folder - [Scripts](/bicep/aks/scripts)

The scripts are called automatically by the [aks-CNI.json](json/aks-cni.json) ARM template on deployment.
## Are there any commands I can use to get the host's DNS, passwords and to change the Network Security Group (NSG) rule, instead of using the portal? 

Yes, below are commands that can be used to more quickly retieve this information. 

<b> Obtain password from keyvault (example for vpnvm host in default resource group) </b>

If you wish to retieve passwords for a different hostname, simply change the name property to match.

``` az keyvault secret show --name "vpnvm-admin-password" --vault-name $(az keyvault list -g aks-CNI --query "[].name" -o tsv) --query "value" -o tsv ```

If you receive an error on this command relating to a timeout and you are using Windows Subsystem for Linux and referencing the Windows based az, you should reference this github issue - https://github.com/Azure/azure-cli/issues/13573. Use powershell or cloud shell instead to mitigate this known bug.

<b> Obtain DNS label for public IP of host (example for vpnvm in default resource group) </b>

``` az network public-ip show -g aks-CNI -n vpnvmnic-vpnpip --query "dnsSettings.fqdn" -o tsv ```

<b> Change Network Security Rule (NSG) to allow SSH inbound from a specific public IP address </b>

You should change a.a.a.a to match your public IP address

``` az network nsg rule update -g aks-CNI --nsg-name Allow-tunnel-traffic -n allow-ssh-inbound  --access allow --source-address-prefix "a.a.a.a" ```


## TODO

1. Azure Network Policy Validations
