param spokeVnetId string
param spokeVnetName string
param hubVnetId string
param hubVnetName string

resource vnetpeering1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${spokeVnetName}/${spokeVnetName}-${hubVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic    : true
    allowGatewayTransit      : false
    useRemoteGateways        : true
    remoteVirtualNetwork     : {
      id: hubVnetId
    }
  }
}

resource vnetpeering2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${hubVnetName}/${hubVnetName}-${spokeVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic    : false
    allowGatewayTransit      : true
    useRemoteGateways        : false
    remoteVirtualNetwork     : {
      id: spokeVnetId
    }
  }
}
