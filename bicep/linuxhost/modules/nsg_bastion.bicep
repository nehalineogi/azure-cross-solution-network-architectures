// Creates temporary SSH deny rule 

  param location string
   
  resource sg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
    name: 'azure-bastion-nsg'
    location: location
    properties: {
      securityRules: [
        {
          name: 'AllowHttpsInbound' 
          'properties': {
            priority: 120
            access: 'Allow'
            direction: 'Inbound'
            destinationPortRange: '443'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: '*'
          }
        }
          {
            name: 'AllowGatewayManagerInbound' 
            'properties': {
              priority: 130
              access: 'Allow'
              direction: 'Inbound'
              destinationPortRange: '443'
              protocol: 'Tcp'
              sourcePortRange: '*'
              sourceAddressPrefix: 'GatewayManager'
              destinationAddressPrefix: '*'
            }
        }
        {
          name: 'AllowAzureLoadBalancerInbound' 
          'properties': {
            priority: 140
            access: 'Allow'
            direction: 'Inbound'
            destinationPortRange: '443'
            protocol: 'Tcp'
            sourcePortRange: '*'
            sourceAddressPrefix: 'AzureLoadBalancer'
            destinationAddressPrefix: '*'
          }
      }
      {
        name: 'AllowBastionHostCommunication' 
        'properties': {
          priority: 150
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
    }
    {
      name: 'AllowSshRdpOutbound' 
      'properties': {
        priority: 100
        access: 'Allow'
        direction: 'Outbound'
        destinationPortRanges: [
          '22'
          '3389'
        ]
        protocol: '*'
        sourcePortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: 'VirtualNetwork'
      }
  }
  {
    name: 'AllowAzureCloudOutbound' 
    'properties': {
      priority: 110
      access: 'Allow'
      direction: 'Outbound'
      destinationPortRange: '443'
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'AzureCloud'
    }
}
{
  name: 'AllowBastionCommunication' 
  'properties': {
    priority: 120
    access: 'Allow'
    direction: 'Outbound'
    destinationPortRanges: [
      '8080'
      '5701'
    ]
    protocol: '*'
    sourcePortRange: '*'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'VirtualNetwork'
  }
}
{
  name: 'AllowGetSessionInformation' 
  'properties': {
    priority: 130
    access: 'Allow'
    direction: 'Outbound'
    destinationPortRange: '80'
    protocol: '*'
    sourcePortRange: '*'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'Internet'
  }
}
      ]
    }
  }

output nsgId string = sg.id
