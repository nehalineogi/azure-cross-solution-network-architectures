// Creates default NSG, best practice is for each subnet to have an NSG attached.
  param location string
  param name string
  
  resource sg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
    name: name
    location: location
    properties: {
  }
}

  output nsgId string = sg.id
