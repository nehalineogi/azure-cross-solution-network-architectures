param addressPrefix string          
param subnetname  string             
param subnetprefix string     
param bastionNetworkName string   
param bastionSubnet string     
param virtualNetworkName string      
param location string

resource vn 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetname
        properties: {
          addressPrefix: subnetprefix
        }
      }
      {
        name: bastionNetworkName
        properties: {
          addressPrefix: bastionSubnet
        }
      }
    ]
  }
}

output subnetname string = vn.properties.subnets[0].name
output bastionSubnetName string = vn.properties.subnets[1].name
output subnet1addressPrefix string = vn.properties.subnets[0].properties.addressPrefix 
output bastionsubnetprefix string = vn.properties.subnets[1].properties.addressPrefix
output vnid string = vn.id
output vnName string = vn.name
