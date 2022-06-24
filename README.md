# Cross Solution Network Architectures

This is a repo of cross solution network connectivity designs with Azure PaaS services, Azure Kubernetes Services(AKS) and on-premise connectivity. These designs are based on real world experiences working with partners,customers and cross solution Cloud Solution Architects (CSAs) in various Azure Design Sessions (ADS). This repo will contain downloadable artifacts including bicep automated deployments, architecture diagrams, postman collections and tools to test applications for various designs. Learn about tools of trades from various Subject Matter Expert (SME) CSAs to validate designs,connectivity, view application and traffic flows.

# Design Areas
### Advanced Linux Networking

- [VXLAN with two linux hosts (As good as it gets!)](advanced-linux-networking/linux-vxlan.md)
- [Linux bridge ](advanced-linux-networking/linux-bridge.md)
- [Linux namespaces](advanced-linux-networking/linux-namespaces.md)
- [Linux firewall with iptables](advanced-linux-networking/linux-firewall.md)
- Dynamic Routing (Zebra,Quagga,BIRD - BGP Routing on linux)
- Openswan VPN (IPsec Tunnels)
- Macsec encryption on Linux
- The perfect NVA with linux
- IPtables and eBPF
- Cluster Networking - [IPVLAN, MACVLAN, TUN/TAP drivers](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Bicep automated deployment](bicep/linuxhost)

### Azure Kubernetes Services (AKS) Networking Series

- Download [Multi-tab Visio](aks/aks-all-reference-architectures-visio.vsdx) and [PDF](aks/aks-all-reference-architectures-PDF.pdf)
- Docker Networking
  - [Single Host](aks/README-docker-singlehost.md)
  - [Multi Host](aks/README-docker-multihost.md)
  - [Bicep automated deployment](bicep/dockerhost)
- AKS Cluster
  - [Basic/Kubenet Networking](aks/README-kubenet.md)
  - [Advanced/Azure CNI Networking](aks/README-advanced.md)
  - [AKS Private Cluster](aks/README-private-cluster.md)
  - [Bicep automated deployment](bicep/aks)
- Ingress and Egress Control
  - [AKS Private Cluster with Azure Front Door](aks/README-private-cluster-with-AFD.md)
  - [AKS Application Gateway Ingress Controller (AGIC)](aks/README-ingress-appgw.md)
  - [Nginx Ingress controller](aks/README-ingress-nginx.md)
  - [AKS Egress with Azure firewall/NVA](aks/README-aks-egress.md)
- Design Extras
  - [AKS Multiple Nodepool Design](aks/README-multinode.md)
  - kind Cluster (Kubernetes In Docker)
  - Core DNS and Azure DNS Integrations
  - Kubernetes Network Model - Multus, Flannel,Weave, Calico, Cilium
  - Kubernetes Service Mesh (Istio, Linkerd and Consul)

### Azure Database Services

- Download [Multi-tab Visio](database-services/db-services-all-reference-architectures-visio.vsdx) and [PDF](database-services/db-services-all-reference-architectures-PDF.pdf)
- Azure Data Factory (ADF)
  - [AutoResolve Azure Default Integration Runtime](database-services/README-ADF.md)
  - [Azure Managed VNET Integration Runtime and Private Endpoints](database-services/README-Managed.md)
  - [Self hosted Integration Runtime (IR) In Azure](database-services/README-SH-Azure.md)
  - [Self hosted Integration Runtime (IR) On Premises](database-services/README-SH-On-Premises.md)
  - [The big picture with different types of IR](database-services/README-ADF-Big-Picture.md)
- [SQL Managed Instance](database-services/README.md)
  - [Single Region](database-services/README-SQLMI.md)
  - Multi region with Replication - DR Scenario
  - Database failover with application connectivity
- Azure SQL Database (PaaS Service)
- Azure Synapse
- OSS databases - mysql and postgres

### [Azure API Management(APIM) Networking Series](apim/README.md)

- [APIM Big Picture view](apim/README-common.md)
- [Default mode](apim/README-default.md)
- [External network mode](apim/README-external.md)
- [Internal network mode](apim/README-internal.md)
- [Internal network mode with Azure Application Gateway](apim/README-appgw.md)
- [Internal network mode with AKS Backend API](apim/README-AKS-Function.md)
- [APIM with Azure firewall/NVA](apim/README-firewall.md)
- [APIM Identity - AAD and B2C Integration](apim/README-identity.md)
- [APIM Multi-region Architecture](apim/README-mulitregion.md)
- [Self hosted gateway](apim/README-internal.md#api-self-hosted-gateway)
- [LetsEncrypt Certificates and APIM Custom Domain](apim/README-custom-domain.md)
- [Azure Private DNS Zones integration](apim/README-custom-domain.md)
- [Network Troubleshooting](apim/README-troubleshooting.md)
- [Download Postman Collection](apim/README-postman.md)
- Download [Multi-tab Visio](apim/APIM-all-reference-architectures-visio.vsdx) and [PDF](apim/APIM-all-reference-architectures-PDF.pdf) of all APIM Networking Architectures

### [Azure App-service Networking ](app-service/README.md)

- [Private Endpoint Integration](app-service/README.md)
- [Service Endpoint](app-service/README.md)
- [VNET Integration](app-service/README.md)
- [NAT Gateway Integration](app-service/README.md)
- [Azure Private DNS Zone Planning](app-service/README.md)
- APP Services with Custom Domain and Private Endpoints
- Azure App-Service with firewall for outbound traffic filtering

### DevOps and Automation

- [Automated deployments architecture](automated-deployment-architecture/automation-process.md)
- [Azure DevOps CI/CD pipelines](/automated-deployment-architecture/pipelines.md)
- GitOps for Application deployment
- CI/CD pipelines using Github Actions
# Tools of Trade (Work in progress)

0. VSCode Extentions

1. Database

   - SQl Server Management Studio (SSMS)
   - Azure Data Management Studio

2. Networking

   - Microsoft Whiteboard
   - Linux Networking
   - Wireshark/tcpdump
   - dig
   - hping, tcptraceroute

3. Application
   - python
   - html
   - node.js
   - mysql
4. DevOps
   - github
   - Azure DevOps (ADO) project boards
   - Visual Studio Code (vscode)
   - Postman

# Build Sample Applications (Work in progress)

1. Simple CRUD API Application
2. Simple http server
3. Simple 3-tier application for AKS

## Contributors

Special thank you to my colleagues

- [Shaun Croucher](https://github.com/shcrouch)
- [David O'Keefe](https://www.linkedin.com/in/david-o-keefe/)
- [Xavier Elizondo](https://github.com/xelizondo)
- [Heather Tze](https://github.com/hsze)
- [Daniel Mauser](https://github.com/dmauser)
- [Sowmyan Soman Chullikkattil](https://github.com/sowsan)
- [Mike Richter](https://github.com/michaelsrichter)
- [Sumit Sengupta](https://github.com/sumitsengupta)
- [Mike Shelton](https://www.linkedin.com/in/mshelt)
- [Tommy Falgout](https://github.com/lastcoolnameleft)
- [Devanshi Joshi](https://github.com/devanshidiaries)

## Acknowledgments
