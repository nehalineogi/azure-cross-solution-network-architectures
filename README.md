# Cross Solution Network Architectures

This is a repo of cross solution network connectivity designs with Azure PaaS services, Azure Kubernetes Services(AKS) and on-premise connectivity. The design are based on real world experiences working with Partners and customers in various ADS (Azure Design Sessions). The goal is to create a reusable artifacts like reference architectures and content based on real world examples based out of working with partners and collaborating with cross solution CSAs. This repo will contain downloadable artifacts like bicep automated deployments, io.draw diagram,visios, postman collections and test applications for various designs. Learn about tools of trades from various SME CSAs to validate designs,connectivity, view application and traffic flows.

# Design Areas

### Advanced Linux Networking (Coming Soon...)

- [Overlay Networking - VXLAN, IPVLAN, MACVLAN, TUN/TAP drivers](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- Bird Internet Routing Daemon (BGP Routing)
- Openswan VPN (IPsec Tunnels)
- IPtables

### [Azure Kubernetes Services (AKS)](aks/README-advanced.md)

- [Docker Networking](aks/README-docker-multihost.md)
  - [Single Host](aks/README-docker-singlehost.md)
  - [Multi Host](aks/README-docker-multihost.md)
  - kind Cluster (Kubernetes In Docker) (Coming soon...)
- [Basic/Kubenet Networking](aks/README-kubenet.md)
- [Advanced/Azure CNI Networking](aks/README-advanced.md)
- [AKS Private Cluster](aks/README-private-cluster.md)
- [AKS Ingress Controllers](aks/README-ingress-controllers.md)
- [AKS Private Cluster with Azure Front Door](https://github.com/nehalineogi/aks-private-cluster-with-afd-premium)
- Ingress Controllers
  - [AKS nginx ingress controller](https://github.com/nehalineogi/aks-nginx-ingress)
  - [AKS Application gateway as ingress controller](https://github.com/nehalineogi/aks-app-gw-ingress)
- AKS with Azure firewall/NVA
- Core DNS and Azure DNS Integrations (Coming soon...)
- Kubernetes Network Model - Multus, Flannel,Weave, Calico, Cilium (Coming Soon..)
- Kubernets Serivce Mesh (Istio, Linkerd and Consul)

### [Azure Database Services](database-services/README.md)

- [SQL Managed Instance](database-services/README.md)
  - Single Region (database-services/README.md)
  - Multi region with Replication - DR Scenario (Coming Soon...)
  - Database failover with Application connectivity
- [Azure Data Factory(ADF)](database-services/README-ADF.md)
  - Managed VNET and Private Endpoints
  - Self hosted Integration Runtime (IR) In Azure
  - Self hosted Integration Runtime (IR) On Premises
- Azure SQL Database
- Azure Synapse
- OSS databases - mysql and postgres

### [Azure API Management(APIM)](apim/README.md)

- [External network mode](apim/README.md)
- [Securing APIM with Internal network mode and application gateway](apim/README.md)
- [Self hosted gateway](apim/README.md)
- [Azure Private DNS Zones integration](apim/README.md)
- Letsencrypt Certificates and APIM Custom Domain(Coming Soon...)
- APIM with Azure firewall/NVA
- APIM AAD and B2C Integration
- APIM Multi-region Architecture

### [Azure App-service Webapp](app-service/README.md)

- [Private Endpoint](app-service/README.md)
- [Service Endpoint](app-service/README.md)
- [VNET Integration](app-service/README.md)
- [NAT Gateway Integration](app-service/README.md)
- [Azure Private DNS Zone Planning](app-service/README.md)

### Bicep Automated Deployments (Coming Soon...)

# Tools of Trade (Work in progress)

1. Database

   - SQl Server Management Studio (SSMS)
   - Azure Data Management Studio

2. Networking

   - linux networking tools
   - Wireshark/tcpdump
   - dig
   - hping

3. Application
   - python
   - html
   - node.js
4. DevOps
   - github
   - Postman

# Build Sample Applications (Work in progress)

1. Simple CRUD API Application
2. Simple http server
3. Simple 3-tier application for AKS

## Contributors

Special thank you to my collegues

- [David O'Keefe](https://www.linkedin.com/in/david-o-keefe/)
- [Shaun Croucher](https://github.com/shcrouch)
- [Xavier Elizondo](https://github.com/xelizondo)
- [Heather Tze](https://github.com/hsze)
- [Daniel Mueser](https://github.com/dmauser)
- [Sowmyan Soman Chullikkattil](https://github.com/sowsan)
- [Mike Richter](https://github.com/michaelsrichter)
- [Sumit Sengupta](https://github.com/sumitsengupta)
- [Mike Shelton](https://www.linkedin.com/in/mshelt)
- [Tommy Falgout](https://github.com/lastcoolnameleft)
- [Devanshi Joshi](https://github.com/devanshidiaries)

## Acknowledgments
