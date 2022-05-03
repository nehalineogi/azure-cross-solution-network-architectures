param prefix string
param location string

resource uid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${prefix}identity'
  location: location
}

output uId string = uid.id
output clientId string = uid.properties.clientId
output principleId string = uid.properties.principalId
