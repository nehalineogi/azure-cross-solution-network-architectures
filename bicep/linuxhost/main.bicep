@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query objectId -o tsv')
param adUserId string  = ''

@description('Set the resource group name, this will be created automatically')
@minLength(3)
@maxLength(10)
param ResourceGroupName string = 'linuxhost'

@description('Set the size for the VM')
@minLength(6)
param HostVmSize string = 'Standard_D2_v3'

var VmAdminUsername  = 'localadmin'
var VmHostnamePrefix = 'linux-host-'
var numberOfHosts    = 2
var location         = deployment().location  // linting warning here, but for this deployment it is at subscription level and so if we have a separate parameter specified here, 
                                              // there will be two "location" options on the "Deploy to Azure" custom deployment and this is confusing for the user.

// VNet and Subnet References (module outputs)
var hubVnetId            = virtualnetwork[0].outputs.vnid
var hubVnetName          = virtualnetwork[0].outputs.vnName
var hubMainSubnetName    = virtualnetwork[0].outputs.subnets[0].name
var hubBastionSubnetName = virtualnetwork[0].outputs.subnets[1].name
var hubSubnetRef         = '${hubVnetId}/subnets/${virtualnetwork[0].outputs.subnets[0].name}'
var hubBastionSubnetRef  = '${hubVnetId}/subnets/${virtualnetwork[0].outputs.subnets[1].name}'
var hubMainSubnetPrefix  = virtualnetwork[0].outputs.subnets[0].properties.addressPrefix
var hubBastionHostPrefix = virtualnetwork[0].outputs.subnets[1].properties.addressPrefix

// VNet schema 
var vnets = [
  {
    vnetName: 'hubVnet'
    vnetAddressPrefix: '172.16.0.0/16'
    subnets: [
      {
        name     : 'main'
        prefix   : '172.16.24.0/24'
        customNsg: true
      }
      {
        name     : 'AzureBastionSubnet'
        prefix   : '172.16.254.0/24'
        customNsg: true
      }
    ]
  }
]

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name    : ResourceGroupName
  location: location
}

module virtualnetwork './modules/vnet.bicep' = [for vnet in vnets: {
  params: {
    vnetName         : vnet.vnetName
    vnetAddressPrefix: vnet.vnetAddressPrefix
    location         : location
    subnets          : vnet.subnets
    nsgDefaultId     : defaultnsg.outputs.nsgId
  }

  name: '${vnet.vnetName}'
  scope: rg
} ]

 module kv './modules/kv.bicep' = {
  params: {
    location: location
    adUserId: adUserId
  }
  name : 'kv'
  scope: rg
}
module linuxhost './modules/vm.bicep' = [for i in range (1,numberOfHosts): {
  params: {
    location     : location
    deployPIP    : true
    windowsVM    : false
    deployDC     : false
    adminusername: VmAdminUsername
    keyvault_name: kv.outputs.keyvaultname
    vmname       : '${VmHostnamePrefix}${i}'
    subnet1ref   : hubSubnetRef
    vmSize       : HostVmSize
    adUserId     : adUserId
  }
  name: '${VmHostnamePrefix}${i}'
  scope: rg
}  ]

module hubBastion './modules/bastion.bicep' = {
params:{
  bastionHostName: 'hubBastion'
  location       : location
  subnetRef      : hubBastionSubnetRef
}
scope:rg
name: 'hubBastion'
}

module tempsshNSG './modules/nsg_tempdenyssh.bicep' = {
  name: 'hubNSG'
  params:{
    location : location
    destinationAddressPrefix: hubMainSubnetPrefix
  }
scope:rg
}

module bastionNSG './modules/nsg_bastion.bicep' = {
  name: 'bastionNSG'
  params:{
    location: location
  }
scope:rg
}

module defaultnsg './modules/nsg_default.bicep' = {
  name : 'default-nsg'
  params: {
    location: location
  }
  scope: rg
}
module mainNsgAttachment './modules/nsgAttachment.bicep' = {
  name: 'mainNsgAttachment'
  params:{
    nsgId              : tempsshNSG.outputs.nsgId
    subnetAddressPrefix: hubMainSubnetPrefix                    
    subnetName         : hubMainSubnetName
    vnetName           : hubVnetName
  }
  scope:rg
}

module bastionNSGAttachment './modules/nsgAttachment.bicep' = {
  name: 'bastionNsgAttachment'
  params:{
    nsgId              : bastionNSG.outputs.nsgId
    subnetAddressPrefix: hubBastionHostPrefix
    subnetName         : hubBastionSubnetName
    vnetName           : hubVnetName
  }
  scope:rg
}
