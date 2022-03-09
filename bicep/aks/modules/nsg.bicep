
  param location string
  param sourceAddressPrefix string = '*'
  
  resource sg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
    name: 'Allow-tunnel-traffic'
    location: location
    properties: {
      securityRules: [
        { // This rule to be removed - temporary to allow set up of IPsec tunnel
          name: 'allow-ssh-inbound' 
          'properties': {
            priority: 1000
            access: 'Deny'
            direction: 'Inbound'
            destinationPortRange: '22'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: '127.0.0.1'
            destinationAddressPrefix: '*'
          }
        }
        {
          name: 'default-allow-tunnel-comms'
          'properties': {
            priority: 1100
            access: 'Allow'
            direction: 'Inbound'
            destinationPortRange: '*'
            protocol: '*'
            sourcePortRange: '*'
            sourceAddressPrefix: sourceAddressPrefix // Hub g/w PIP
            destinationAddressPrefix: '*'
          }
        }
      ]
    }
  }

  output onpremNsgId string = sg.id
