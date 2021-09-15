## Azure API Management (APIM) Multi-region Architecture

This architecture shows APIM with multi-region deployment.APIM in multi-region mode requires Premium tier and also note that only the gateway component of API Management is deployed to all regions. The developer portal is hosted in the Primary region only.  Two options are discussed here - one with the default multi-region deployment and one with Azure Traffic manager for more granular control over the routing


## Reference Architecture

![APIM Architecture](images/multi-region/apim-multi-region.png)


## Azure Documentation links

1. [APIM Multi-region](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-deploy-multi-region)
2. [APIM Multi-region with Traffic Manager](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-deploy-multi-region#-use-custom-routing-to-api-management-regional-gateways)


## Desgin Components and Considerations
1. Note: This architecture represents APIM in External Mode
2. Default Option routes requests to the correspoding regional gateway based on the lowest latency
3. Azure TM Option give more granular control over routing and load balancing options
4. Developer Portal is hosted in Primary region only. In case of Primary region outage access to the developer portal will be impacted until primary region comes back online. Secondary region will service the API traffic.
5. Failover Design considerations
6. APIM in Internal Mode can be leveraged with Traffic manager in front of the Application Gateway 



# Configuration

## APIM Side Configuration
![apim-multiregion](images/multi-region/apim-location.png)
![apim-multiregion](images/multi-region/apim-premium-properties.png)
![apim-multiregion](images/multi-region/apim-east.png)
![apim-multiregion](images/multi-region/apim-west.png)
![apim-multiregion](images/multi-region/custom-domain.png)

# Traffic Manager Configuration

![apim-multiregion](images/multi-region/TM-configuration.png)
![apim-multiregion](images/multi-region/tm-endpoints.png)



# Multi-region (Option#1) DNS Resolution with default Multi-region

In the default mode and routes request to a regional gateway based on lowest latency

East VM Resolves to East IP (Primary Region)
```
nehali@nn-linux-dev:~$ dig +short nnapi-premium.azure-api.net
apimgmttm1xwomm3ais1n8uk6p1nuaa6wso55smgryhomsg7qr.trafficmanager.net.
nnapi-premium-eastus-01.regional.azure-api.net.
apimgmthsajvdzotyzpmfmhrqfh7xjnq7k0gzo6cmn9u2d5s5l.cloudapp.net.
52.255.185.19

```
West VM resolves to west IP(Secondary Region)
```
nehali@nn-cyan-vm:~$ dig +short nnapi-premium.azure-api.net
apimgmttm1xwomm3ais1n8uk6p1nuaa6wso55smgryhomsg7qr.trafficmanager.net.
nnapi-premium-westus-01.regional.azure-api.net.
apimgmthsehik1fs6runeq18v2h5rptaznywntzbjw0kmleq8a.cloudapp.net.
40.86.168.240

```
Developer portal always resolves to primary region

```
nehali@nehali-laptop:~$ dig nnapi-premium.developer.azure-api.net +short
apimgmthsajvdzotyzpmfmhrqfh7xjnq7k0gzo6cmn9u2d5s5l.cloudapp.net.
52.255.185.19

```

# Multi-region (Option#2) DNS Resolution with Custom domain and Traffic Manager

Note the the equal weight traffic manager resolving the EastUS and West US IPs

```
nehali@nehali-laptop:~$ dig +short apimtm.penguintrails.com
apim-premium.trafficmanager.net.
nnapi-premium-westus-01.regional.azure-api.net.
apimgmthsehik1fs6runeq18v2h5rptaznywntzbjw0kmleq8a.cloudapp.net.
40.86.168.240


nehali@nehali-laptop:~$ dig +short apimtm.penguintrails.com
apim-premium.trafficmanager.net.
nnapi-premium-eastus-01.regional.azure-api.net.
apimgmthsajvdzotyzpmfmhrqfh7xjnq7k0gzo6cmn9u2d5s5l.cloudapp.net.
52.255.185.19

```
Primary Region IP: API Call resulting in EastUS connection:

```
 curl -v -I --location --request GET 'https://apimtm.penguintrails.com/echo/resource?param1=sample' --insecure
*   Trying 52.255.185.19:443...
* TCP_NODELAY set
* Connected to apimtm.penguintrails.com (52.255.185.19) port 443 (#0)
* ALPN, offering h2
* <snip>

```
Secondary Region IP: API Call resulting in EastUS connection:
```

curl -v -I --location --request GET 'https://apimtm.penguintrails.com/echo/resource?param1=sample' --insecure
*   Trying 40.86.168.240:443...
* TCP_NODELAY set
* Connected to apimtm.penguintrails.com (40.86.168.240) port 443 (#0)
* <snip>
```

# TODO
1. Add Diagram for Internal mode with App GW and Traffic Manager