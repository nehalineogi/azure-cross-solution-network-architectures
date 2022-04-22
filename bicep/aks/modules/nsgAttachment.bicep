param vnetName string
param subnetName string
param subnetAddressPrefix string
param nsgId string

resource nsgAttachment 'Microsoft.Network/virtualNetworks/subnets@2020-07-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    privateEndpointNetworkPolicies: 'Disabled'
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsgId

    }
  }
}
