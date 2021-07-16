# appdev-database-networking

This is a repo of cross solution network connectivity designs with Azure PaaS services and on-premise connectivity. The goal is to create a reusable reference architectures and content based on real world examples based out of working with partners and collaborating with cross solution CSAs. This repo will contain downloadable artifacts like visios, postman collections and test applications for various designs. Learn about tools of trades from various SME CSAs to validate designs,connectivity, view application and traffic flows.

# Cross Solution Network Architectures

1. [Azure Database Services](database-services/README.md)

   - [SQL MI (Single Region and Multi region with Replication)](database-services/README.md)
   - Azure SQL Database
   - OSS databases - mysql,postgres

2. [Azure APIM](apim/README.md)

   - Internal network mode
   - External network mode
   - Self hosted gateway
   - Azure Private DNS Zones integration
   - APIM with Azure firewall/NVA

3. [Azure Kubernetes services](aks/README.md)

   - Docker Networking
   - [Basic/Kubenet Networking](aks/README-kubenet.md)
   - Advanced/Azure CNI Networking
   - Azure Private Cluster
   - AKS with Azure firewall
   - Core DNS and Azure DNS Integrations
   - [AKS Private Cluster with Azure Front Door](https://github.com/nehalineogi/aks-private-cluster-with-afd-premium)
   - [AKS nginx ingress controller](https://github.com/nehalineogi/aks-nginx-ingress)
   - [AKS Application gateway as ingress controller](https://github.com/nehalineogi/aks-app-gw-ingress)

4. [Azure App-service Webapp](webapp/README.md)

   - Private Endpoint
   - VNET Integration
   - NAT Gateway
   - Azure Private DNS Zone

5. Bicep Automated Deployments

# Tools of Trade

1. Database

   - SQl Server Management Studio
   - Azure Data Management Studio

2. Networking

   - Wireshark

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
