# Cross Solution Network Architecture

This is a repo of cross solution network connectivity designs with Azure PaaS services, Azure Kubernetes Services(AKS) and on-premise connectivity. The design are based on real world experiences working with Partners and customers in various ADS (Azure Design Sessions). The goal is to create a reusable reference architectures and content based on real world examples based out of working with partners and collaborating with cross solution CSAs. This repo will contain downloadable artifacts like visios, postman collections and test applications for various designs. Learn about tools of trades from various SME CSAs to validate designs,connectivity, view application and traffic flows.

# Design Areas

1. [Azure Database Services](database-services/README.md)

   - [SQL Managed Instance](database-services/README.md)
     - Single Region
     - Multi region with Replication
       DR Scenario
       Multi Region Read
       Database failover with Application connectivity
   - [Azure Data Factory(ADF)](database-services/README-ADF.md)
     - Managed VNET and Private Endpoints
     - Self hosted Integration Runtime (IR) In Azure
     - Self hosted Integration Runtime (IR) On Premises
   - Azure SQL Database
   - Azure Synapse
   - OSS databases - mysql and postgres

2. [Azure API Management(APIM)](apim/README.md)

   - [External network mode](apim/README.md)
   - [Securing APIM with Internal network mode and application gateway](apim/README.md)
   - [Self hosted gateway](apim/README.md)
   - [Azure Private DNS Zones integration](apim/README.md)
   - [Letsencrypt Certificates and APIM Custom Domain](apim/README.md)
   - APIM with Azure firewall/NVA
   - APIM AAD and B2C Integration
   - APIM Multi-region Architecture

3. [Azure Kubernetes Services (AKS)](aks/README-advanced.md)

   - Advanced Linux Networking
     - VXLAN, IPVLAN, MACVLAN, TUN/TAP drivers
     - Bird Internet Routing Daemon
     - IPtables
   - [Docker Networking](aks/README-docker-multihost.md)
     - [Single Host](aks/README-docker-singlehost.md)
     - [Multi Host](aks/README-docker-multihost.md)
   - [Basic/Kubenet Networking](aks/README-kubenet.md)
   - [Advanced/Azure CNI Networking](aks/README-advanced.md)
   - [AKS Private Cluster](aks/README-private-cluster.md)
   - [AKS Ingress Controllers](aks/README-ingress-controllers.md)
   - [AKS Private Cluster with Azure Front Door](https://github.com/nehalineogi/aks-private-cluster-with-afd-premium)
   - Ingress Controllers
     - [AKS nginx ingress controller](https://github.com/nehalineogi/aks-nginx-ingress)
     - [AKS Application gateway as ingress controller](https://github.com/nehalineogi/aks-app-gw-ingress)
   - AKS with Azure firewall/NVA
   - Core DNS and Azure DNS Integrations
   - Kubernetes Network Model (Multus, Flannel,Weave, Calico, Cilium)
   - Kubernets Serivce Mesh (Istio, Linkerd and Consul)

4. [Azure App-service Webapp](app-service/README.md)

   - [Private Endpoint](app-service/README.md)
   - [Service Endpoint](app-service/README.md)
   - [VNET Integration](app-service/README.md)
   - [NAT Gateway Integration](app-service/README.md)
   - [Azure Private DNS Zone Planning](app-service/README.md)

5. Bicep Automated Deployments

# Tools of Trade

1. Database

   - SQl Server Management Studio
   - Azure Data Management Studio

2. Networking

   - Wireshark
   - dig
   - hping

3. Application
   - python
   - html
   - node.js
4. DevOps
   - Postman

# Sample Applications

1. Simple CRUD API Application
2. Simple http server
3. Simple 3-tier application for AKS

## Contributors

Special thank you to my collegues

- [Heather Tze](https://github.com/hsze)
- [Daniel Mueser](https://github.com/dmauser)
- [Mike Richter](https://github.com/michaelsrichter)
- [Sumit Sengupta](https://github.com/sumitsengupta)
- [Mike Shelton](https://www.linkedin.com/in/mshelt)
- [Tommy Falgout](https://github.com/lastcoolnameleft)
- [Devanshi Joshi](https://github.com/devanshidiaries)
- [Sowmyan Soman Chullikkattil](https://github.com/sowsan)

## Acknowledgments
