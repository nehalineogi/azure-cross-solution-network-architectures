param name string
param ipAddress string
param addressSpace string

resource lng 'Microsoft.Network/localNetworkGateways@2021-02-01' = {
  name: name
  location: resourceGroup().location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    gatewayIpAddress: ipAddress
  }
}

output lngid string = lng.id
