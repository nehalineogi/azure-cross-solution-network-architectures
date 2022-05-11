 param location string
    
  resource sg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
    name: 'aks-subnet-nsg'
    location: location
    properties: {
      securityRules: [
        { 
          name: 'allow-8080-inbound' 
          'properties': {
            priority: 100
            access: 'Allow'
            direction: 'Inbound'
            destinationPortRange: '8080'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
          }
        }
      ]
    }
  }

  output NsgId string = sg.id
