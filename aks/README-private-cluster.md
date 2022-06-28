## Azure AKS Advanced/Azure CNI Networking

This architecture demonstrates the connectivity architecture and traffic flows for connecting Azure AKS Private Cluster environment with your on-premises environment. In the Private AKS cluster the control plane or the kube API server has an **internal IP address**. This IP is exposed via a private endpoint in the AKS subnet. The on-premises networks use the Private IP address of the Kube-API server hence **both DNS and routing** has to be in place between on-premises and AKS network. A private DNS zone is also created example - abcxyz.privatelink.<region>.azmk8s.io. AKS services are exposed using an internal load balancer. Egress paths from AKS cluster to Internet can be designed using public load balancer (default) or using Azure Firewall/NVA/NAT gateway using userDefinedRouting setting in AKS.

The automated deployment will deploy an Azure private zone, and will conditional forward from the on-premises domain controller to a BIND DNS server running on a VM in the hub for resolution of AKS in private deployment mode.
## Reference Architecture

#### This reference architecture uses Advanced/Azure CNI Networking

![AKS Advanced Networking](images/aks-private-cluster.png)

Download [Multi-tab Visio](aks-all-reference-architectures-visio.vsdx) and [PDF](aks-all-reference-architectures-PDF.pdf)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnehalineogi%2Fazure-cross-solution-network-architectures%2Fmain%2Faks%2Fjson%2Faks-private.json)

# Quickstart deployment
### Task 1: Start Deployment

1. Click Deploy to Azure button above and supply the signed-in user ID from step 2. Leave all defaults and deploy.

2. Open Cloud Shell and retrieve your signed-in user ID below (this is used to apply access to Keyvault).

```
az ad signed-in-user show --query id -o tsv
```

3. You can log in to the supporting VMs (DC, hub DNS, VPN VM) using the username `localadmin` and passwords from the deployed keyvault.

Note: SSH directly to the VMs is possible, however, it is best security practice to not expose VMs to the internet for SSH. 
It is not uncommon for tenants that are managed by corporations to restrict the use of SSH directly from the internet. More information can be found in the [FAQ](https://github.com/nehalineogi/azure-cross-solution-network-architectures/blob/main/aks/README-private-cluster.md#faqtroubleshooting).

4. Log in to kubectl from the hubvm, follow instructions below

## Azure Documentation links

1. [AKS Baseline architecture](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks/secure-baseline-aks)
2. [Create Private Cluster](https://docs.microsoft.com/en-us/azure/aks/private-clusters)
3. [AKS Private Cluster limitations](https://docs.microsoft.com/en-us/azure/aks/private-clusters#limitations)
4. [External Load Balancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard)
5. [Internal Load Balancer](https://docs.microsoft.com/en-us/azure/aks/internal-lb)
6. [Configure Private DNS Zone](https://docs.microsoft.com/en-us/azure/aks/private-clusters#configure-private-dns-zone)
7. [Egress Path](https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype#outbound-type-of-userdefinedrouting)

## Design Components and Planning

1. Private Cluster is supported in AKS Basic (kubenet) and AKS Advanced (CNI) mode. The above diagram show Azure Advanced (CNI).
2. Private Cluster can be deployed in existing or new VNET.
3. Planning is required routing Kube API private endpoint from on-premises or from other Azure VNETs.
4. Hybrid DNS setup with private DNS zones for DNS resolution from on-premises in Enterprise environments. However, local hosts files can be used in lab/POCs. 
5. **Ingress Considerations:** While, both Internal and External load balancers can be used to expose Ingress services however, in a truely private cluster only Internal load balancer is used for Ingress. External Load balancer is used for egress.
6. **Egress Considerations**: Egress path options via Azure public load balancer or using Azure Firewall/NVA
7. Options for connecting to Private cluster. Azure documentation link [here](https://docs.microsoft.com/en-us/azure/aks/private-clusters#options-for-connecting-to-the-private-cluster). For this architecture we have on-premises connectivity and also example of AKS run command.

- Create a VM in the same Azure Virtual Network (VNet) as the AKS cluster.
- Use a VM in a separate network and set up Virtual network peering. See the section below for more information on this option.
- Use an Express Route or VPN connection.
- Use the AKS Run Command feature.

8. Common errors without DNS and Routing in place.

```
kubectl get pods -o wide
Unable to connect to the server: dial tcp: i/o timeout

```

From Azure Portal. You need to be connected to Azure VNET or have VPN/Private connectivity in place.
![AKS Advanced Networking](images/aks-private-cluster-error.png)

## Kube API Access

With the above command AKS Private DNS Zone and Private endpoint gets created.

![AKS Private DNS Zone](images/aks-private-dns-zone.png)

## On-Premises to Kube API server connectivity

Note the kubeAPI / cluster IP will resolve differently in your deployment based on the clustername and the location you deploy to. The references below are specifically for the deployment used for this demo series, you will need to replace the environment specific references to match your own deployment. 

The form will be [clustername].privatelink.[location].azmk8s.io (private endpoint IP)

```
kubectlcluster-info
Kubernetes control plane is running at https://nnaks-private-b8afe38a.abc8bcf2-73d8-4d97-83d5-0ae74d9aa974.privatelink.eastus.azmk8s.io:443
healthmodel-replicaset-service is running at https://nnaks-private-b8afe38a.abc8bcf2-73d8-4d97-83d5-0ae74d9aa974.privatelink.eastus.azmk8s.io:443/api/v1/namespaces/kube-system/services/healthmodel-replicaset-service/proxy
CoreDNS is running at https://nnaks-private-b8afe38a.abc8bcf2-73d8-4d97-83d5-0ae74d9aa974.privatelink.eastus.azmk8s.io:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://nnaks-private-b8afe38a.abc8bcf2-73d8-4d97-83d5-0ae74d9aa974.privatelink.eastus.azmk8s.io:443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'

```

Note that the KubeAPI DNS resolves to private IP and hence routing to the private IP needs to be configured. Best practice to use the hybrid On-premises DNS best practices for DNS resolution of private endpoint from on-premises. However, a local hosts file can be leverage for lab/POC.

```
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
nehali@nehali-laptop:/mnt/c/Users/neneogi/Documents/repos/k8s/aks-azcli$ more /etc/hosts | grep nnaks-private-b8afe38a.abc8bcf2-73d8-4d97-83d5-0ae74d9aa974.privatelink.eastus.azmk8s.io
172.16.238.4 nnaks-private-b8afe38a.abc8bcf2-73d8-4d97-83d5-0ae74d9aa974.privatelink.eastus.azmk8s.io

```
## Deployment Validations

These steps will deploy a single test pod and delete it. This deployment type is 'private' so you can run these commands from a VM that has layer 3 connectivity to the AKS network, but not from outside of the deployed environment. For control plane access purposes, we will use the ```hubdnsvm``` located in the hub network. 

1. Obtain the password for ```hubdnsvm``` from keyvault and log in via bastion, switch to sudo. 

```localadmin@hubdnsvm:~$ sudo su```

2. Download the az cli tools and install

```root@hubdnsvm:/home/localadmin# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash```

2. Authenticate to your tenant 

```root@hubdnsvm:/home/localadmin# az login```

3. Install az cli aks (kubetcl) and follow on screen instructions to add the executables to your environment variables path.

```root@hubdnsvm:/home/localadmin# az aks install-cli```

4. Obtain the cluster credentials to log in to kubectl (if you did not use the default, replace resource-group with your specified resource group name). 

```root@hubdnsvm:/home/localadmin# az aks get-credentials --resource-group nnaks-private-rg --name nnaks-private```

5. Clone the reposity

```root@hubdnsvm:/home/localadmin# git clone https://github.com/nehalineogi/azure-cross-solution-network-architectures```

6. Navigate to the dnsutils directory 

```root@hubdnsvm:/home/localadmin# cd azure-cross-solution-network-architectures/aks/yaml/dns```

7. Deploy a simple pod

```root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/dns# kubectl apply -f dnsutils.yaml```

8. Check pod is running successfully 

```root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/dns# kubectl get pods -o wide```

9. Move to repo base directory 

```root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/dns# cd ../../..```

## IP Address Assignment

This deployment will be using Azure CNI so the node and pod IPs are in the same subnet

#### Verify nodes

```
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures# kubectl get nodes -o wide

NAME                                 STATUS   ROLES   AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-agentpool1-38167371-vmss000000   Ready    agent   60m   v1.22.6   172.16.240.5    <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2
aks-agentpool1-38167371-vmss000001   Ready    agent   60m   v1.22.6   172.16.240.36   <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2
aks-agentpool1-38167371-vmss000002   Ready    agent   60m   v1.22.6   172.16.240.67   <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2

```

# Challenge 1: Deploy Pods and Internal Service

In this challenge you will deploy pods and configure an internal service using an existing yaml definition in the repository. Notice how the pods are placed on the three nodes using the IP addresses from the AKS VNet, and spread over the three VMSS instances that make the AKS cluster. 

```
#
# Create a namespace for the service, and apply the configuration
#
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures# kubectl create ns colors-ns
namespace/colors-ns created
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures# cd aks/yaml/colors-ns
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl apply -f red-internal-service.yaml
deployment.apps/red-deployment created
service/red-service-internal created
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl get pods,services -o wide -n colors-ns
NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE                                 NOMINATED NODE   READINESS GATES
pod/red-deployment-5f589f64c6-bbmt4   1/1     Running   0          7s    172.16.240.12   aks-agentpool1-38167371-vmss000000   <none>           <none>
pod/red-deployment-5f589f64c6-rwctc   1/1     Running   0          7s    172.16.240.52   aks-agentpool1-38167371-vmss000001   <none>           <none>
pod/red-deployment-5f589f64c6-xprvn   1/1     Running   0          7s    172.16.240.75   aks-agentpool1-38167371-vmss000002   <none>           <none>

NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE   SELECTOR
service/red-service-internal   LoadBalancer   10.101.156.68   <pending>     8080:30454/TCP   7s    app=red
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl describe service red-service-internal -n colors-ns
Name:                     red-service-internal
Namespace:                colors-ns
Labels:                   <none>
Annotations:              service.beta.kubernetes.io/azure-load-balancer-internal: true
Selector:                 app=red
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.101.156.68
IPs:                      10.101.156.68
LoadBalancer Ingress:     172.16.240.98
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30454/TCP
Endpoints:                172.16.240.12:8080,172.16.240.52:8080,172.16.240.75:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  62s   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   10s   service-controller  Ensured load balancer

```

# Challenge 2: Verify service from on-premises 

From the VPN server on-premise (vpnvm) log in via bastion (password in keyvault) and try to curl the service via the LoadBalancer Ingress:

```
localadmin@vpnvm:~$ curl http://172.16.240.98:8080/
red
```
# Challenge 3: Deploy Pods and External Service

Note that although the AKS cluster has been deployed as a private cluster, this refers to the control plane, and it is still possible to expose a service publically as we are here. Test from a browser on your own device that you can reach the load balancer ingress IP.

```

root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl apply -f red-external-lb.yaml
deployment.apps/red-deployment unchanged
service/red-service-external created
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl get pods,services -o wide -n colors-ns
NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE                                 NOMINATED NODE   READINESS GATES
pod/red-deployment-5f589f64c6-bbmt4   1/1     Running   0          21m   172.16.240.12   aks-agentpool1-38167371-vmss000000   <none>           <none>
pod/red-deployment-5f589f64c6-rwctc   1/1     Running   0          21m   172.16.240.52   aks-agentpool1-38167371-vmss000001   <none>           <none>
pod/red-deployment-5f589f64c6-xprvn   1/1     Running   0          21m   172.16.240.75   aks-agentpool1-38167371-vmss000002   <none>           <none>

NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE     SELECTOR
service/red-service-external   LoadBalancer   10.101.192.67   51.104.252.152   8080:32615/TCP   3m58s   app=red
service/red-service-internal   LoadBalancer   10.101.156.68   172.16.240.98    8080:30454/TCP   21m     app=red
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl describe service red-service-external -n colors-ns
Name:                     red-service-external
Namespace:                colors-ns
Labels:                   <none>
Annotations:              <none>
Selector:                 app=red
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.101.192.67
IPs:                      10.101.192.67
LoadBalancer Ingress:     51.104.252.152
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  32615/TCP
Endpoints:                172.16.240.12:8080,172.16.240.52:8080,172.16.240.75:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age    From                Message
  ----    ------                ----   ----                -------
  Normal  EnsuringLoadBalancer  4m9s   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   3m59s  service-controller  Ensured load balancer

```
# Challenge 4: Validate Network Security Group (NSG)

### NSG Validation

AKS automatically applies an NSG to the interfaces of the node pool VMSS instances. Check in the portal for an NSG beginning aks-agentpoolxxxx in the resource group and find the NSG rule automatically written to accept connections on port 8080. You can test this from the VPN VM or from your own device to check the application is accessible.

# Challenge 5: Validate view from AKS nodes, pods and on-premise

In this challenge you will check the view from each type of AKS component.

### AKS Node view

NNote the Node inherits the DNS from VNET DNS setting and egress for the node via Azure public load balancer (NVA/Firewall options available)

```
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl get nodes,pods -o wide
NAME                                      STATUS   ROLES   AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
node/aks-agentpool1-38167371-vmss000000   Ready    agent   90m   v1.22.6   172.16.240.5    <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2
node/aks-agentpool1-38167371-vmss000001   Ready    agent   90m   v1.22.6   172.16.240.36   <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2
node/aks-agentpool1-38167371-vmss000002   Ready    agent   90m   v1.22.6   172.16.240.67   <none>        Ubuntu 18.04.6 LTS   5.4.0-1083-azure   containerd://1.5.11+azure-2

NAME           READY   STATUS    RESTARTS   AGE   IP             NODE                                 NOMINATED NODE   READINESS GATES
pod/dnsutils   1/1     Running   0          34m   172.16.240.7   aks-agentpool1-38167371-vmss000000   <none>           <none>

Create shell connection from the hubdnsvm to one of the nodes using the commands below. Replace with your own AKS node names. For further instructions on this process or to learn more see [Connect to AKS cluster nodes for maintenance or troubleshooting](https://docs.microsoft.com/en-us/azure/aks/node-access) 

shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl get nodes

NAME                                 STATUS   ROLES   AGE    VERSION
aks-agentpool1-19014455-vmss000000   Ready    agent   133m   v1.22.6
aks-agentpool1-19014455-vmss000001   Ready    agent   133m   v1.22.6
aks-agentpool1-19014455-vmss000002   Ready    agent   133m   v1.22.6

shaun@Azure:~/azure-cross-solution-network-architectures/aks/yaml/colors-ns$ kubectl debug nodes/aks-agentpool1-19014455-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
Creating debugging pod node-debugger-aks-agentpool1-19014455-vmss000000-8kln4 with container debugger on node aks-agentpool1-19014455-vmss000000.
If you don't see a command prompt, try pressing enter.

root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl debug nodes/aks-agentpool1-38167371-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
Creating debugging pod node-debugger-aks-agentpool1-38167371-vmss000000-jn9zn with container debugger on node aks-agentpool1-38167371-vmss000000.
If you don't see a command prompt, try pressing enter.
root@aks-agentpool1-38167371-vmss000000:/# chroot /host
# ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 60:45:bd:12:83:6b brd ff:ff:ff:ff:ff:ff
    inet 172.16.240.5/24 brd 172.16.240.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::6245:bdff:fe12:836b/64 scope link 
       valid_lft forever preferred_lft forever
4: azv64a3ef6fa7b@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether c2:70:0e:62:85:75 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::c070:eff:fe62:8575/64 scope link 
       valid_lft forever preferred_lft forever
6: azv01497dafea0@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 4a:2e:a5:6e:4f:ba brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::482e:a5ff:fe6e:4fba/64 scope link 
       valid_lft forever preferred_lft forever
10: azvb3c61c3cba9@if9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 9a:19:7c:57:5d:4d brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::9819:7cff:fe57:5d4d/64 scope link 
       valid_lft forever preferred_lft forever
12: azve35ef5eb01f@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 22:37:36:46:39:28 brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::2037:36ff:fe46:3928/64 scope link 
       valid_lft forever preferred_lft forever
# 
# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.16.240.1    0.0.0.0         UG    100    0        0 eth0
168.63.129.16   172.16.240.1    255.255.255.255 UGH   100    0        0 eth0
169.254.169.254 172.16.240.1    255.255.255.255 UGH   100    0        0 eth0
172.16.240.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
172.16.240.7    0.0.0.0         255.255.255.255 UH    0      0        0 azvb3c61c3cba9
172.16.240.12   0.0.0.0         255.255.255.255 UH    0      0        0 azve35ef5eb01f
172.16.240.13   0.0.0.0         255.255.255.255 UH    0      0        0 azv01497dafea0
172.16.240.18   0.0.0.0         255.255.255.255 UH    0      0        0 azv64a3ef6fa7b
# 
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
search sbmktmjsj3jezjiccjszwcqdra.zx.internal.cloudapp.net

```
### AKS Pod view

Pod Inherits DNS from the Node and egress via external LB.

```
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl exec -it dnsutils -- sh
/ # ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
9: eth0@if10: <BROADCAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP qlen 1000
    link/ether 5a:40:56:7e:7c:9d brd ff:ff:ff:ff:ff:ff
    inet 172.16.240.7/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::5840:56ff:fe7e:7c9d/64 scope link 
       valid_lft forever preferred_lft forever
/ # 
/ # route -n 
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         169.254.1.1     0.0.0.0         UG    0      0        0 eth0
169.254.1.1     0.0.0.0         255.255.255.255 UH    0      0        0 eth0
/ # 
/ # cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local sbmktmjsj3jezjiccjszwcqdra.zx.internal.cloudapp.net
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
From hubdnsvm, create a shell connection to the dnsutil pod and initiate a connection

```
root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl exec -it dnsutils -- sh
/ # wget 192.168.199.4:8000
Connecting to 192.168.199.4:8000 (192.168.199.4:8000)
index.html           100% |**********************************************************************************************************************************************************|   702   0:00:00 ETA
/ # 
```
View results on the vpnvm 

```
localadmin@vpnvm:~$ python3 -m http.server
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
172.16.240.5 - - [28/Jun/2022 18:01:49] "GET / HTTP/1.1" 200 -

```
## Traffic validations from On-Premises to AKS

For ingress, note that the AKS pods are directly reachable using their own IP address from on-premise. Here you can access the red pod via its assigned POD IP. 

```

root@hubdnsvm:/home/localadmin/azure-cross-solution-network-architectures/aks/yaml/colors-ns# kubectl get pods,services -o wide -n colors-ns
NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE                                 NOMINATED NODE   READINESS GATES
pod/red-deployment-5f589f64c6-bbmt4   1/1     Running   0          52m   172.16.240.12   aks-agentpool1-38167371-vmss000000   <none>           <none>
pod/red-deployment-5f589f64c6-rwctc   1/1     Running   0          52m   172.16.240.52   aks-agentpool1-38167371-vmss000001   <none>           <none>
pod/red-deployment-5f589f64c6-xprvn   1/1     Running   0          52m   172.16.240.75   aks-agentpool1-38167371-vmss000002   <none>           <none>

NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE   SELECTOR
service/red-service-external   LoadBalancer   10.101.192.67   51.104.252.152   8080:32615/TCP   34m   app=red
service/red-service-internal   LoadBalancer   10.101.156.68   172.16.240.98    8080:30454/TCP   52m   app=red


Internal load balancer service IP
localadmin@vpnvm:~$ curl http://172.16.240.98:8080
red

Directly Hitting the POD IP:
localadmin@vpnvm:~$ curl http://172.16.240.12:8080
red

Public IP Via public load balancer service IP
localadmin@vpnvm:~$ curl http://51.104.252.152:8080
red

```
# AKS Run command

Azure documentation
https://docs.microsoft.com/en-us/azure/aks/private-clusters#use-aks-run-command

Quick way to run kubectl commands using AKS run:

```
 kubectl get pods -o wide
 Unable to connect to the server: dial tcp: i/o timeout


 az aks command invoke -g aks-private-cluster-rg -n nnaks-private -c "kubectl get nodes -o wide"
command started at 2021-09-21 13:08:40+00:00, finished at 2021-09-21 13:08:41+00:00 with exitcode=0
NAME                                STATUS   ROLES   AGE   VERSION    INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-nodepool1-40840556-vmss000000   Ready    agent   64d   v1.19.11   172.16.238.5    <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
aks-nodepool1-40840556-vmss000001   Ready    agent   64d   v1.19.11   172.16.238.36   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
aks-nodepool1-40840556-vmss000002   Ready    agent   64d   v1.19.11   172.16.238.67   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure

```

Sample deployment using AKS Run:

```
az aks command invoke -g aks-private-cluster-rg -n nnaks-private -c "kubectl create ns demo-ns"
command started at 2021-09-21 13:18:27+00:00, finished at 2021-09-21 13:18:28+00:00 with exitcode=0
namespace/demo-ns created

az aks command invoke -g aks-private-cluster-rg -n nnaks-private -c "kubectl apply -f deployment.yaml" -f deployment.yaml
command started at 2021-09-21 13:19:06+00:00, finished at 2021-09-21 13:19:07+00:00 with exitcode=0
deployment.apps/nginx-deployment created

az aks command invoke -g aks-private-cluster-rg -n nnaks-private -c "kubectl get pods -o wide -n demo-ns"
command started at 2021-09-21 13:19:32+00:00, finished at 2021-09-21 13:19:33+00:00 with exitcode=0
NAME                                READY   STATUS    RESTARTS   AGE   IP              NODE                                NOMINATED NODE   READINESS GATES
nginx-deployment-6c46465cc6-2nhqq   1/1     Running   0          26s   172.16.238.33   aks-nodepool1-40840556-vmss000000   <none>           <none>
nginx-deployment-6c46465cc6-kk284   1/1     Running   0          26s   172.16.238.97   aks-nodepool1-40840556-vmss000002   <none>           <none>
nginx-deployment-6c46465cc6-txs5j   1/1     Running   0          26s   172.16.238.45   aks-nodepool1-40840556-vmss000001   <none>           <none>
```
# FAQ/Troubleshooting

## I am unable to SSH to hosts, what do I need to do?

The automated deployment deploys Azure Bastion so you can connect to the VMs via the portal using Bastion. This is the recommended practice. 

Alternatively the subnet hosting the VMs has a Network Security Group (NSG) attached called "Allow-tunnel-traffic" with a rule called 'allow-ssh-inbound' which is set to Deny by default. If you wish to allow SSH direct to the hosts, you can edit this rule and change the Source from 127.0.0.1 to your current public IP address. Afterwards, Remember to set the rule from Deny to Allow. Corporate policies may restict the use of SSH, so if you are under the governanace of a corporate environment please liaise directly. 

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

The scripts are called automatically by the [aks-private.json](json/aks-private.json) ARM template on deployment.
## Are there any commands I can use to get the host's DNS, passwords and to change the Network Security Group (NSG) rule, instead of using the portal? 

Yes, below are commands that can be used to more quickly retrieve this information. 

<b> Obtain password from keyvault (example for vpnvm host in default resource group) </b>

If you wish to retrieve passwords for a different hostname, simply change the name property to match.

``` az keyvault secret show --name "vpnvm-admin-password" --vault-name $(az keyvault list -g nnaks-private-rg --query "[].name" -o tsv) --query "value" -o tsv ```

If you receive an error on this command relating to a timeout and you are using Windows Subsystem for Linux and referencing the Windows based az, you should reference this github issue - https://github.com/Azure/azure-cli/issues/13573. Use powershell or cloud shell instead to mitigate this known bug.

<b> Obtain DNS label for public IP of host (example for vpnvm in default resource group) </b>

``` az network public-ip show -g nnaks-private-rg -n vpnvmnic-vpnpip --query "dnsSettings.fqdn" -o tsv ```

<b> Change Network Security Rule (NSG) to allow SSH inbound from a specific public IP address </b>

You should change a.a.a.a to match your public IP address

``` az network nsg rule update -g nnaks-private-rg --nsg-name Allow-tunnel-traffic -n allow-ssh-inbound  --access allow --source-address-prefix "a.a.a.a" ```
