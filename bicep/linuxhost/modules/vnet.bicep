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
        networkSecurityGroup: subnet.customNsg ? null : {
          id        : defaultnsg.id
          location  : defaultnsg.location
          properties: {
          }
        }

      }
    }]
  }
}

resource defaultnsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'default-nsg'
  location: location
  properties: {
}
}

output vnid string   = vn.id
output vnName string = vn.name
output subnets array = vn.properties.subnets
