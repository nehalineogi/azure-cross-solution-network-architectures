## Azure API Management (APIM) Architecture

This architecture demonstrates the connectivity architecture and traffic flows to and from API Management (APIM). APIM can be deployed in various modes. The diagram shows APIM in internal mode with Application gateway and Custom DNS, APIM Self hosted gateway and APIM in External mode with direct access from the internet. Custom domain can be configured for all the three network models.

## Reference Architecture

![APIM Architecture](images/apim-architecture.png)

Download Visio link here

Download postman APIM collection here

## Azure Documentation links

1. [APIM External Mode](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet)
2. [APIM Internal Mode](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet)
3. [Internal APIM with Application Gateway](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet)
4. [Internal APIM Self Hosted Gateway](https://docs.microsoft.com/en-us/azure/api-management/self-hosted-gateway-overviewt)

## Design Components

1. APIM in Internal mode is accessible from on-premise via a private IP. APIM in internal mode can be deployed in conjunction with Application gateway for external access.
2. **DNS Considerations:** Internal network mode consideration is that the DNS needs to be maintained and configured by the user. Custom DNS using Azure Private DNS Zone.
3. APIM in External mode is directly accesible from the Intenet. APIM in external mode the external DNS resolution for APIM endpoints is provided by the service.
4. Backend APIs needs to be routable from APIM in internal mode or external mode.
5. Use Docker host or On-Premises Kubernetes cluster to run API Management self hosted gateway
6. The diagram shows Backend APIs running in Azure (AKS Cluster, Function App), externally hosted APIs (example weather API or conference API) and Backend API hosted on-premises
7. Custom domain can be configured with internal, external and self hosted gateway

## Design Considerations and Planning

1. Azure Subnet planning for APIM subnet.

If using API version 2021-01-01-preview or later to deploy an Azure API Management, you don't have to use a subnet dedicated to API Management instances.

2. DNS Resolution in Azure (Internal Mode)

   In external VNET mode, Azure manages the DNS. For internal VNET mode, you have to manage your own DNS. Note that none of the service endpoints in Internal Mode are registered on the public DNS. The service endpoints will remain inaccessible until you configure DNS for the VNET. If using custom DNS on-premises should also resolve APIM endpoints below

#

```
#APIM default domain
#
172.16.6.9 nnapi.azure-api.net
172.16.6.9 nnapi.portal.azure-api.net
172.16.6.9 nnapi.developer.azure-api.net
172.16.6.9 nnapi.management.azure-api.net
172.16.6.9 nnapi.scm.azure-api.net
##
#APIM custom domain
#
172.16.6.9 nnapi.penguintrails.com
172.16.6.9 developer.penguintrails.com
172.16.6.9 portal.penguintrails.com
172.16.6.9 management.penguintrails.com
172.16.6.9 scm.penguintrails.com

```

3. DNS Resolution with Application Gateway (Internal Mode)

Use Custom Domain and CNAME records point to the application gateway for the APIM endpoints.

```
nnapi CNAME 60 nneastappgw.eastus.cloudapp.azure.com
developer CNAME 60 nneastappgw.eastus.cloudapp.azure.com
management CNAME 60 nneastappgw.eastus.cloudapp.azure.com

```

4. APIM Modes (External vs Internal)
   ![Networking](images/apim-network-mode.png)

5. Azure firewall/NVA Design
   Check network connectivity status for any potential DNS or assymetric routing issue with NVA or Azure firewall

![Networking](images/network-connectivity-status.png)

## TODO

1. Writeup on custom domain certificate considerations with self hosted gatewway
2. Document Developer portal considerations.
