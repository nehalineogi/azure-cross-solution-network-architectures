param location string = resourceGroup().location
param tenantId string = subscription().tenantId
param keyvaultname string = '${resourceGroup().name}-${uniqueString(resourceGroup().id)}' 
param adUserId string

resource keyvaultname_resource 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyvaultname
  location: location
  properties: {
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableSoftDelete: false
    accessPolicies: [
      {
        objectId: adUserId
        tenantId: tenantId
        permissions: {
          keys: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
            'managecontacts'
            'manageissuers'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
          ]
        }
      }
    ]
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

output keyvaultid string = keyvaultname_resource.id
output keyvaultname string = keyvaultname_resource.name
