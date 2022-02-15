param adminusername string
param keyvault_name string 
param vmname string
param subnet1ref string
param githubPath string
param adUserId string

@secure()
param adminPassword string = '${uniqueString(resourceGroup().id, vmname)}aA1!${uniqueString(adUserId)}'

@description('Size of the virtual machine.')
param vmSize string 

@description('location for all resources')
param location string = resourceGroup().location

param publicIPAddressNameSuffix string = 'pip'
var dnsLabelPrefix = 'dns-${uniqueString(resourceGroup().id, vmname)}-${publicIPAddressNameSuffix}'

var storageAccountName = '${uniqueString(resourceGroup().id, vmname)}'
var nicName = '${vmname}-nic'

resource pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${nicName}-${publicIPAddressNameSuffix}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource stg 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource nInter 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName
  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: subnet1ref
          }
        }
      }
    ]
  }
}

resource VM 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmname
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmname
      adminUsername: adminusername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {

        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nInter.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}

resource keyvaultname_secretname 'Microsoft.keyvault/vaults/secrets@2019-09-01' = {
  name: '${keyvault_name}/${vmname}-admin-password'
  properties: {
    contentType: 'securestring'
    value: adminPassword
    attributes: {
      enabled: true
    }
  }
}

resource keyvaultname_username 'Microsoft.keyvault/vaults/secrets@2019-09-01' = {
  name: '${keyvault_name}/${vmname}-admin-username'
  properties: {
    contentType: 'string'
    value: adminusername
    attributes: {
      enabled: true
    }
  }
}

resource cse 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${vmname}/cse'
  location: location
  dependsOn:[
    VM
  ]
   properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1' 
    autoUpgradeMinorVersion: false
    settings: {}
    protectedSettings: {
      fileUris: [
        '${githubPath}cse.sh'
      ]
      commandToExecute: 'sh cse.sh'
    }
    
   }
}
