param spokeAddressPrefix string
param hubAddressPrefix string
param subnetAddressPrefix string
param vnetName string
param subnetName string
param applianceAddress string
param nsgId string

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'onprem-route-table'
  location: resourceGroup().location
  properties: {
    routes: [
      {
        name: 'route-to-hub'
        properties: {
          addressPrefix: hubAddressPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: applianceAddress
        }
      }
      {
        name: 'route-to-spoke'
        properties: {
          addressPrefix: spokeAddressPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: applianceAddress
        }
      }
    ]
    disableBgpRoutePropagation: true
  }
}

resource routeAttachment 'Microsoft.Network/virtualNetworks/subnets@2020-07-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    routeTable: {
      id: routeTable.id
    }
    networkSecurityGroup: {
      id: nsgId
    }
  }
}
