param subnets array                       
param vnetName string      
param vnetAddressPrefix string
param location string

resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName 
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.prefix
      }
    }]
  }
}

output vnid string   = vn.id
output vnName string = vn.name
output subnets array = vn.properties.subnets
