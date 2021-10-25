
# Network Troubleshooting
This is a collection of errors (and corresponding troubleshooting tip) at various stages across the different scenarios during the deployment. 

# Azure Documentation links
[Common Network Issues](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#force-tunneling-traffic-to-on-premises-firewall-using-expressroute-or-network-virtual-appliance)

[APIM Troubleshooting](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#troubleshooting)

[Custom DNS](https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#custom-dns-server-setup)


# Network Connectivity Status

Verify Network connectivity status. If the status is not healthy review DNS, VPN/Routing, Firewall/NVA design considerations for Internal vs External mode.

![Network Health](images/external/fw-network-connectivity-status.png)



# Routing to backend API

Validate routing to the backend API, review NSGs and if firewall /NVA IP needs to be whitelisted


```
HTTP/1.1 500 Internal Server Error
content-length: 111
content-type: application/json
ocp-apim-trace-location: https://apimstpfudfrlt3kx6pyv5ty.blob.core.windows.net/apiinspectorcontainer/
vary: Origin
    {
    "statusCode": 500,
    "message": "Internal server error",
    "activityId": "cd71e1f2-28a5-4c28-8b72-368278afcbda"}

```


Validate routing to the backend API (in this case 172.16.1.5) is not routable from on-premises resulting in this error

```
lastError: { "elapsed": 20039, "source": "request-forwarder", "path": "forward-request\forward-request", "reason": "BackendConnectionFailure", "message": "connection timed out: 172.16.1.5:3001", "section": "backend" }, errors: [


```
# API Testing via Postman


Review http and https settings on the APIM Web service URL

```
HTTP/1.1 302 Moved Temporarily
Backend service responded with a redirect.

```  
# Self hosted Gateway API connectivity

Validate self-hosted gateway is attached to an API

```
{
    "statusCode": 404,
    "message": "Resource not found"
}
```

# Self hosted Gateway Container Connectivity

Verify that a valid certificate is installed

```
[Error]2021-08-29T12:47:23.554 [Error], exception: System.Net.Http.HttpRequestException: Response status code does not indicate success: 503 (Service Unavailable).
   at System.Net.Http.HttpResponseMessage.EnsureSuccessStatusCode()

```

# Application Gateway

Check app gw health, probe test, http/https settings on the APIM

```
<html>
<head>
    <title>502 Bad Gateway</title>
</head>
<body>
    <center>
        <h1>502 Bad Gateway</h1>
    </center>
    <hr>
    <center>Microsoft-Azure-Application-Gateway/v2</center>
</body>
</html>

```

# Firewall blocking outbound API traffic

Review firewall rules

```
HTTP/1.1 470 Unknown
content-length: 165
content-type: text/plain; charset=utf-8
ocp-apim-trace-location: https://apimstxlgadtm0vo1piuszfu.blob.core.windows.net/apiinspectorcontainer/lXIOgxyWd3s0TMWRpkHxMw2-3?sv=2019-07-07&sr=b&sig=6u6XW%2FrA0KLx9MxUe8NjyF6NZ4lUrR%2BTk0mN5EfUytE%3D&se=2021-08-30T20%3A30%3A55Z&sp=r&traceId=7c68459c0531447ab5de1605843a68ae
vary: Origin
    HTTP  request from172.16.6.6:50748 toechoapi.cloudapp.net:80. Url: echoapi.cloudapp.net/api/resource. Action: Deny. Norule matched. Proceeding with default action

```

Default domain in external mode fails because the return traffic gets assymetric. Use custom domain when you have a firewall/NVA in the design.

```
GET http://nnapi-external.azure-api.net/internal/listUsers
Error: connect ETIMEDOUT 40.71.32.102:80

```

# Management endpoint connectivity issues

Verify firewall/NVA causing assymetric routing issue


```
Failed to connect to management endpoint
Failed to connect to management endpoint at nnapi-external.management.azure-api.net:3443 for a service deployed in a virtual network. Make sure to follow guidance at https://aka.ms/apim-vnet-common-issues.

```

# Developer Portal Authentication Issue

Verfiy that management endpoint is reachable and DNS resolution works

```
GET http://https//52.142.39.37/internal/ListUsers
Error: getaddrinfo ENOTFOUND https

▶Request Headers
Host: nnapi.azure-api.net
User-Agent: PostmanRuntime/7.28.4
Accept: */*
Postman-Token: ce4b4d65-ab47-4232-a99a-468ec01c586b
Accept-Encoding: gzip, deflate, br

```

# NSG On APIM or Backend subnet

Potential Issue: NSG on the APIM or Backend API subnet



```
GET http://http//52.142.39.37/internal/ListUsers
Error: getaddrinfo ENOTFOUND http
HTTP/1.1 400 Bad Request
content-length: 213
content-type: application/json
vary: Origin
    {
    "error": "A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond 40.71.32.102:80"}
```

# Subscription Issue
 Missing subscritpion Key

```
{
    "statusCode": 401,
    "message": "Access denied due to invalid subscription key. Make sure to provide a valid key for an active subscription."
}
```

# Docker container logs

Verify backend API is routable

```
 docker logs 92 --follow
 IpAddress: 172.17.0.1, timeGenerated: 09/03/2021 11:09:11, region: nn-eastus, correlationId: 287cc23d-984e-4490-a05c-de8abecb4229, method: GET, url: https://127.0.0.1:6002/self/listUsers, responseCode: 500, responseSize: 259, cache: none, apiId: self-hosted-api, operationId: get-all-user, apimSubscriptionId: all-api-subscription, clientProtocol: HTTP/1.1, apiRevision: 1, clientTlsVersion: 1.2, lastError: {
  "elapsed": 20018,
  "source": "request-forwarder",
  "path": "forward-request\\forward-request",
  "reason": "BackendConnectionFailure",
  "message": "connection timed out: 172.16.1.5:3001",
  "section": "backend"
}, errors: [
  {
    "elapsed": 20018,
    "source": "request-forwarder",
    "path": "forward-request\\forward-request",
    "message": "connection timed out: 172.16.1.5:3001",
    "section": "backend"
  }
]
```

# CORS Policy

   Review CORS polciy setting.

```
Since the browser initiates the request, it requires Cross-Origin Resource Sharing (CORS) enabled on the server. Learn more.

```
![CORS policy](images/common/cors.png)


