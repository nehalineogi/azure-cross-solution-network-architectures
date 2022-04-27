param name string
param vnetgwid string
param lngid string
param psk string
param location string


resource conn 'Microsoft.Network/connections@2021-02-01' = {
  location: location
  name: name
  properties: {
    connectionType                : 'IPsec'
    connectionProtocol            : 'IKEv2'
    routingWeight                 : 0
    sharedKey                     : psk
    enableBgp                     : false
    useLocalAzureIpAddress        : false
    usePolicyBasedTrafficSelectors: false
    expressRouteGatewayBypass     : false
    dpdTimeoutSeconds             : 0
    connectionMode                : 'Default'
    virtualNetworkGateway1        : {
      id: vnetgwid
      properties: {
      }
    }
     localNetworkGateway2: {
       id: lngid
       properties:{
       }
     }
  }
}
