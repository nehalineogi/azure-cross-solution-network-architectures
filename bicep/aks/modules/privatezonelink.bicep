param privateDnsZoneName string
param vnetId string
param vnetName string

resource akshublink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneName}/${vnetName}-link-hub'
  location: 'global'
  properties: {
    registrationEnabled: false

    virtualNetwork: {
      id: vnetId
    }
  }
}
