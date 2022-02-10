
  param location string
  param destinationAddressPrefix string 
  
  resource sg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
    name: 'Allow-tunnel-traffic'
    location: location
    properties: {
      securityRules: [
        {
          name: 'allow-ssh-inbound' 
          'properties': {
            priority: 1000
            access: 'Deny'
            direction: 'Inbound'
            destinationPortRange: '22'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: '127.0.0.1'
            destinationAddressPrefix: destinationAddressPrefix
          }
        }
      ]
    }
  }

  output nsgId string = sg.id
