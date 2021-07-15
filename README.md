# appdev-database-networking

This is a repo of cross solution network designs with Azure PaaS and on-premise connectivity. The goal is to create a reusable freference architecture content. This repo will contain downloadable visio, postman collections and test applications for various designs. These architectures are based out of real world discussions with Partners and customers. Learn about tools of trades to validate connectivity, view traffic flows.

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

   - Basic Networking
   - Kubenet Networking
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
