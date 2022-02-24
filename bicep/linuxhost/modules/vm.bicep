param adminusername string
param keyvault_name string 
param vmname string
param subnet1ref string
param adUserId string
@secure()
param adminPassword string = '${uniqueString(resourceGroup().id, vmname)}aA1!${uniqueString(adUserId)}'  // Note passwords not cryptographically secure, deployment is not designed for production use
param windowsVM bool

var dcdisk = [
  {
  diskSizeGB: 20
  lun: 0
  createOption: 'Empty'
}
]

@description('Size of the virtual machine.')
param vmSize string 

@description('location for all resources')
param location string = resourceGroup().location

var storageAccountName = '${uniqueString(resourceGroup().id, vmname)}'
var nicName = '${vmname}nic'

param publicIPAddressNameSuffix string = 'pip'

param deployPIP bool = false
param deployVpn bool = false
param deployDC bool  = false

var dnsLabelPrefix = 'dns-${uniqueString(resourceGroup().id, vmname)}-${publicIPAddressNameSuffix}'

resource pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = if (deployPIP) {
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

resource nInter 'Microsoft.Network/networkInterfaces@2020-06-01' = if (deployPIP) {
  name: '${nicName}pip'
  location: location

  properties: {
    enableIPForwarding: deployVpn ? true : false
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

resource nInternoIP 'Microsoft.Network/networkInterfaces@2020-06-01' = if (!(deployPIP)) {
  name: nicName
  location: location
  properties: {
    enableIPForwarding: deployVpn ? true : false
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {

          privateIPAllocationMethod: 'Dynamic'
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
        
        publisher: windowsVM ? 'MicrosoftWindowsServer': 'canonical'
        offer    : windowsVM ? 'WindowsServer' : '0001-com-ubuntu-server-focal'
        sku      : windowsVM ? '2019-Datacenter' : '20_04-lts'
        version  : windowsVM ? 'latest' : 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: deployDC ? dcdisk : null
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: deployPIP ? nInter.id : nInternoIP.id
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

output vmPip string    = deployPIP ? pip.properties.dnsSettings.fqdn : ''
output vmIp string     = deployPIP ? pip.properties.ipAddress : ''
output vmPrivIp string = deployPIP ? nInter.properties.ipConfigurations[0].properties.privateIPAddress : ''
