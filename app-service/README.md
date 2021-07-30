## Azure Web APP, Function App, Logic App Architecture

This architecture demonstrates the connectivity architecture and traffic flows Azure Web APP and Function app when using VNET integration and private endpoints. This architecture also covers DNS architecture in a multi-region design when using private endpoints with web app

## Reference Architecture

![APIM Architecture](images/app-service.png)

Download Visio link here

## Azure Documentation links

1. [VNET Integration with App services](https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet#how-regional-vnet-integration-works)
2. [VNET Integration and Subnet Delegation](https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet)
3. [Network Isolation with VNET Integration](https://docs.microsoft.com/en-us/azure/virtual-network/vnet-integration-for-azure-services)
4. [Control Outbound IP using Azure NAT Gateway](https://docs.microsoft.com/en-us/azure/azure-functions/functions-how-to-use-nat-gateway)
5. [Premium SKU requirement for Private Endpoints](https://docs.microsoft.com/en-us/azure/app-service/networking/private-endpoint)
6. [DNS Private Zone with App Services](https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet#azure-dns-private-zones)

## Design Components and considerations

1. Hybrid DNS setup with Hub VNET Using Azure DNS, Spokes with Custom DNS server pointing to the HUB DNS server
2. Private Endpoints Per region vs Private Endpoints Cross Region depending on your DR strategy and existing end-to-end routing.
3. VNET links to Private Zone Zone for **Registration**
4. VNET links to Priave DNS Zones for **Resolution**
5. Front End App Service talking to BE App Service via Private Endpoints
6. Egress Requirements for App services: Use VNET Integration and **Outbound NAT Gateway** for deterministic IP for outbound
7. Create Private Endpoints per region and establish routing for the other region to connect to the private endpoint.
8. Create Private endpoints cross regions if end-to-end IP routing is not in place.
9. Centralized Private DNS Zones vs Prviate DNS Zones Per region. In the above architecture both east and the west hubs are linked to the same Private DNS Zone in the east region.

## Design Validations

#### DNS Validations

Make sure the private link DNS zone are linked to the corresponding VNETs

![DNS Zone VNET links](images/vnet-link-dns-zone.png)

#### From FE Web APP ssh Console

Verify DNS resolution from Webapp console

```
DNS Resolution for Private Endpoints From FrontEnd Webapp (ssh console)
root@c3feca61e67d:/home# nslookup nnwebapp-premium.azurewebsites.net
Server:         127.0.0.11
Address:        127.0.0.11#53

Non-authoritative answer:
nnwebapp-premium.azurewebsites.net      canonical name = nnwebapp-premium.privatelink.azurewebsites.net.
Name:   nnwebapp-premium.privatelink.azurewebsites.net
Address: 172.16.1.11

Access Backend website via Private Endpoint

root@c3feca61e67d:/home# curl -I https://nnwebapp-premium.azurewebsites.net
HTTP/1.1 200 OK
<snip>

Outbound IP via NAT Gateway
root@c3feca61e67d:/home# curl ifconfig.io
52.186.92.228
```

#### DNS private zones

DNS private zone for privatelink.azurewebsites.net in each regions. Note that a vnet can only be linked to once to the same private DNS zone.

![East DNS Zone](images/east-dns-zone.png)

![West DNS Zone](images/west-dns-zone.png)

TODO

1. Document Fuction app creating and validation
