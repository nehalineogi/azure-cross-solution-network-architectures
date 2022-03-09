param gatewaySubnetId string
param location string

resource vnetgw 'Microsoft.Network/virtualNetworkGateways@2021-02-01' = {
  name: 'hubGateway'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vnet1GatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: gwpip.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    vpnType: 'RouteBased'
    enableBgp: true
    bgpSettings: {
      asn: 65515

    }
  }
}


resource gwpip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'gwpip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output gwpip string = gwpip.properties.ipAddress
output vnetgwid string = vnetgw.id
