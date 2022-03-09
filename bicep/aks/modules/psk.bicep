param onpremSubnetRef string
param keyvault_name string
param name string

var psk = '${uniqueString(resourceGroup().id, onpremSubnetRef, name)}aA1!'

resource keyvaultname_secretname 'Microsoft.keyvault/vaults/secrets@2019-09-01' = {
  name: '${keyvault_name}/${name}-psk'
  properties: {
    contentType: 'securestring'
    value: psk
    attributes: {
      enabled: true
    }
  }
}

output psk string = psk
