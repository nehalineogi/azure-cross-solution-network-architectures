param adminusername string
param keyvault_name string 
param vmname string
param subnet1ref string
param githubPath string
param adUserId string
@secure()
param adminPassword string = '${uniqueString(resourceGroup().id, vmname)}aA1!${uniqueString(adUserId)}' // Note passwords not cryptographically secure, deployment is not designed for production use
param windowsVM bool
param domainName string = 'contoso.local' // this has a default so that module calls do not need to supply a domain name when deployDC is set to false, as to-do-so is misleading.

var dcdisk = [
  {
  diskSizeGB: 20
  lun: 0
  createOption: 'Empty'
}
]

param vpnVars object = 	{
  psk                : null
  gwip               : null
  gwaddressPrefix    : null
  onpremAddressPrefix: null
  spokeAddressPrefix : null
  hubAddressPrefix   : null
}

@description('Size of the virtual machine.')
param vmSize string 

@description('location for all resources')
param location string

var storageAccountName = uniqueString(resourceGroup().id, vmname)
var nicName = '${vmname}nic'

param publicIPAddressNameSuffix string = 'pip'

param deployPIP bool    = false
param deployVpn bool    = false
param deployDC bool     = false
param deployHubDns bool = false

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

resource cse 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (deployVpn) {
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
      commandToExecute: deployVpn ? 'sh cse.sh ${nInter.properties.ipConfigurations[0].properties.privateIPAddress} ${pip.properties.ipAddress} ${vpnVars.gwip} ${vpnVars.gwaddressPrefix} ${vpnVars.psk} ${vpnVars.onpremAddressPrefix} ${vpnVars.spokeAddressPrefix}' : ''
    }
    
   }
}

resource csehubdns 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (deployHubDns) {
  name: '${vmname}/csehubdns'
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
        '${githubPath}hubdns.sh'
      ]
      commandToExecute: deployHubDns ? 'sh hubdns.sh ${vpnVars.onpremAddressPrefix} ${vpnVars.spokeAddressPrefix} ${vpnVars.hubAddressPrefix}' : ''
    }
    
   }
}

// Will need to take a look at https://github.com/dsccommunity/DnsServerDsc to add DNS conditional forwarder through DSC
// More info on DSC extension with ARM templates - https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-template
resource csedc 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (deployDC) {
  parent: VM
  name: 'CreateADForest'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(githubPath, 'CreateADPDC.zip')
      ConfigurationFunction: 'CreateADPDC.ps1\\CreateADPDC'
      Properties: {
        DomainName: domainName
        AdminCreds: {
          UserName: adminusername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      } 
    }
  }
}

output VmPip string    = deployPIP ? pip.properties.dnsSettings.fqdn : ''
output VmIp string     = deployPIP ? pip.properties.ipAddress : ''
output VmPrivIp string = deployPIP ? nInter.properties.ipConfigurations[0].properties.privateIPAddress : ''
