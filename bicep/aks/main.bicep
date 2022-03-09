@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query objectId -o tsv')
param adUserId string  = ''

@description('Set the resource group name, this will be created automatically')
@minLength(3)
@maxLength(10)
param ResourceGroupName string = 'bluelines'

@description('Set the size for the VM')
@minLength(6)
param HostVmSize string = 'Standard_D2_v3'

@description('Set the name of the domain eg contoso.local')
@minLength(3)
param domainName string = 'contoso.local'

var githubPath         = 'https://raw.githubusercontent.com/nehalineogi/azure-cross-solution-network-architectures/aks/bicep/aks/scripts/'
var VmAdminUsername           = 'localadmin'
var location                  = deployment().location // linting warning here, but for this deployment it is at subscription level and so if we have a separate parameter specified here, 
                                                      // there will be two "location" options on the "Deploy to Azure" custom deployment and this is confusing for the user.

var onpremVPNVmName           = 'vpnvm'
var publicIPAddressNameSuffix = 'vpnpip'
var hubDNSVmName              = 'hubdnsvm'
var hubVmName                 = 'hubjump'
var spokeVmName               = 'spokejump'
var dcVmName                  = 'dc1'

// VNet and Subnet References (module outputs)
var hubVnetId              = virtualnetwork[0].outputs.vnid
var spokeVnetId            = virtualnetwork[1].outputs.vnid
var onpremVnetId           = virtualnetwork[2].outputs.vnid
var hubVnetName            = virtualnetwork[0].outputs.vnName
var spokeVnetName          = virtualnetwork[1].outputs.vnName
var onpremVnetName         = virtualnetwork[2].outputs.vnName
var onpremSubnetName       = virtualnetwork[2].outputs.subnets[0].name
var hubSubnetRef           = '${hubVnetId}/subnets/${virtualnetwork[0].outputs.subnets[0].name}'
var hubBastionSubnetRef    = '${hubVnetId}/subnets/${virtualnetwork[0].outputs.subnets[1].name}'
var SpokeSubnetRef         = '${spokeVnetId}/subnets/${virtualnetwork[1].outputs.subnets[0].name}'
var onpremSubnetRef        = '${onpremVnetId}/subnets/${onpremSubnetName}'
var onpremBastionSubnetRef = '${onpremVnetId}/subnets/${virtualnetwork[2].outputs.subnets[1].name}'
var hubAddressPrefix       = virtualnetwork[0].outputs.subnets[0].properties.addressPrefix
var onpremAddressPrefix    = virtualnetwork[2].outputs.subnets[0].properties.addressPrefix
var spokeAddressPrefix     = virtualnetwork[1].outputs.subnets[0].properties.addressPrefix
var onpremBastionAddPrefix = virtualnetwork[2].outputs.subnets[1].properties.addressPrefix
var onpremBastionSubnetName= virtualnetwork[2].outputs.subnets[1].name
var hubBastionSubnetName   = virtualnetwork[0].outputs.subnets[1].name
var hubBastionAddPrefix    = virtualnetwork[0].outputs.subnets[1].properties.addressPrefix
var gwSubnetId             = virtualnetwork[0].outputs.subnets[2].id

// VNet schema 
var vnets = [
  {
    vnetName: 'hubVnet'
    vnetAddressPrefix: '172.17.0.0/16'
    subnets: [
      {
        name: 'main'
        prefix: '172.17.1.0/24'
        customNsg: false
      }
      {
        name: 'AzureBastionSubnet'
        prefix: '172.17.2.0/24'
        customNsg: true
      }
      {
        name: 'GatewaySubnet' 
        prefix: '172.17.3.0/24'
        customNsg: true // Advice is for GatewaySubnet to not be associated with NSG - therefore this is marked as custom, without a custom NSG defined.
      }
    ]
  }
  {
    vnetName: 'spokeVnet'
    vnetAddressPrefix: '172.16.0.0/16'
    subnets: [
      {
        name: 'main'
        prefix: '172.16.1.0/24'
        customNsg: false
      }
    ]
  }
  {
    vnetName: 'onpremises'
    vnetAddressPrefix: '192.168.0.0/16'
    subnets: [
      {
        name: 'main'
        prefix: '192.168.199.0/24'
        customNsg: true
      }
      {
        name: 'AzureBastionSubnet'
        prefix: '192.168.200.0/24'
        customNsg: true
      }
    ]
  }
]

/* var vpnVars = {
    psk                : psk.outputs.psk
    gwip               : hubgw.outputs.gwpip
    gwaddressPrefix    : hubAddressPrefix
    onpremAddressPrefix: onpremAddressPrefix
    spokeAddressPrefix : spokeAddressPrefix
  } */

targetScope = 'subscription'

  resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
    name    : ResourceGroupName
    location: location
  }

module virtualnetwork './modules/vnet.bicep' = [for vnet in vnets: {
  params: {
    vnetName         : vnet.vnetName
    vnetAddressPrefix: vnet.vnetaddressprefix
    location         : location
    subnets          : vnet.subnets
    nsgDefaultId     : defaultnsg.outputs.nsgId  // attached to every vnet. Overwritten if another NSG is defined in main.bicep

  }

  name: '${vnet.vnetName}'
  scope: rg
} ]

 /* module kv './modules/kv.bicep' = {
  params: {
    location: location
    adUserId: adUserId
  }
  name : 'kv'
  scope: rg
}

module psk 'modules/psk.bicep' = {
  scope: rg
  name: 'psk'
  params: {
    keyvault_name  : kv.outputs.keyvaultname
    onpremSubnetRef: onpremSubnetRef
    name           : 'azure-conn'
  }
} */

// The VM passwords are generated at run time and automatically stored in Keyvault. 
// It is not possible to create a loop through the vm var because the 'subnetref' which is an output only known at runtime is not calculated until after deployment. It is not possible therefore to use it in a loop.
/* module hubJumpServer './modules/vm.bicep' = {
  params: {
    location     : location
    windowsVM    : true
    deployDC     : false
    adminusername: VmAdminUsername
    keyvault_name: kv.outputs.keyvaultname
    vmname       : hubVmName
    subnet1ref   : hubSubnetRef
    vmSize       : HostVmSize
    githubPath   : githubPath
    adUserId     : adUserId

  }
  name: 'hubjump'
  scope: rg
}  

module spokeJumpServer './modules/vm.bicep' = {
  params: {
    location     : location
    windowsVM    : true
    adminusername: VmAdminUsername
    keyvault_name: kv.outputs.keyvaultname
    vmname       : spokeVmName
    subnet1ref   : SpokeSubnetRef
    vmSize       : HostVmSize
    githubPath   : githubPath
    adUserId     : adUserId
  }
  name: 'spokejump'
  scope: rg
}  

module dc './modules/vm.bicep' = {
  params: {
    location     : location
    windowsVM    : true
    deployDC     : true
    domainName   : domainName
    adminusername: VmAdminUsername
    keyvault_name: kv.outputs.keyvaultname
    vmname       : dcVmName
    subnet1ref   : onpremSubnetRef
    vmSize       : HostVmSize
    githubPath   : githubPath
    adUserId     : adUserId
  }
  name: 'OnpremDC'
  scope: rg
} 

module onpremVpnVM './modules/vm.bicep' = {
  params: {
    location                 : location
    windowsVM                : false
    deployPIP                : true
    deployVpn                : true
    adminusername            : VmAdminUsername
    keyvault_name            : kv.outputs.keyvaultname
    vmname                   : onpremVPNVmName
    subnet1ref               : onpremSubnetRef
    vmSize                   : HostVmSize
    githubPath               : githubPath
    publicIPAddressNameSuffix: publicIPAddressNameSuffix
    vpnVars                  : vpnVars
    adUserId                 : adUserId
  }
  name: 'onpremVpnVM'
  scope: rg
} 

module hubDnsVM './modules/vm.bicep' = {
  params: {
    location     : location
    windowsVM    : false
    adminusername: VmAdminUsername
    keyvault_name: kv.outputs.keyvaultname
    vmname       : hubDNSVmName
    subnet1ref   : hubSubnetRef
    vmSize       : HostVmSize
    githubPath   : githubPath
    adUserId     : adUserId

  }
  name: 'hubDnsVM'
  scope: rg
} 
 */


/* module hubgw './modules/vnetgw.bicep' = {
  name: 'hubgw'
  scope: rg
  params:{
    gatewaySubnetId: gwSubnetId
    location: location
  }
}

module localNetworkGW 'modules/lng.bicep' = {
  scope: rg
  name: 'onpremgw'
  params: {
    addressSpace:  onpremAddressPrefix
    ipAddress: onpremVpnVM.outputs.VmIp
    name: 'onpremgw'
  }
}

module vpnconn 'modules/vpnconn.bicep' = {
  scope: rg
  name: 'onprem-azure-conn'
  params: {
    psk     : psk.outputs.psk
    lngid   : localNetworkGW.outputs.lngid
    vnetgwid: hubgw.outputs.vnetgwid
    name    : 'onprem-azure-conn'
    
  }
}
 
module vnetPeering './modules/vnetpeering.bicep' = {
  params:{
    hubVnetId    : hubVnetId
    spokeVnetId  : spokeVnetId
    hubVnetName  : hubVnetName
    spokeVnetName: spokeVnetName
  }
  scope: rg
  name: 'vNetpeering'
  dependsOn: [
  //  hubgw
  ]
}

module hubBastion './modules/bastion.bicep' = {
params:{
  bastionHostName: 'hubBastion'
  location: location
  subnetRef: hubBastionSubnetRef
}
scope:rg
name: 'hubBastion'
}

module onpremBastion './modules/bastion.bicep' = {
  params:{
    bastionHostName: 'onpremBastion'
    location: location
    subnetRef: onpremBastionSubnetRef
  }
  scope:rg
  name: 'onpremBastion'
  }

module onpremNSG './modules/nsg.bicep' = {
  name: 'hubNSG'
  params:{
    location: location
    sourceAddressPrefix: hubgw.outputs.gwpip
  }
scope:rg
}

module onpremNsgAttachment './modules/nsgAttachment.bicep' = {
  name: 'onpremNsgAttachment'
  params:{
    nsgId              : onpremNSG.outputs.onpremNsgId
    subnetAddressPrefix: onpremAddressPrefix                    
    subnetName         : onpremSubnetName
    vnetName           : onpremVnetName
  }
  scope:rg
}
module routeTableAttachment 'modules/routetable.bicep' = {
  scope: rg
  name: 'rt'
  params: {
    applianceAddress   : onpremVpnVM.outputs.VmPrivIp
    nsgId              : onpremNSG.outputs.onpremNsgId
    hubAddressPrefix   : hubAddressPrefix
    spokeAddressPrefix : spokeAddressPrefix
    subnetAddressPrefix: onpremAddressPrefix
    subnetName         : onpremSubnetName
    vnetName           : onpremVnetName
  }
}

module bastionNSG './modules/nsg_bastion.bicep' = {
  name: 'bastionNSG'
  params:{
    location: location
  }
scope:rg
}

*/
module defaultnsg './modules/nsg_default.bicep' = {
  name : 'default-nsg'
  params: {
    location: location
  }
  scope: rg
}

/*

module bastionHubNSGAttachment './modules/nsgAttachment.bicep' = {
  name: 'bastionHubNsgAttachment'
  params:{
    nsgId              : bastionNSG.outputs.nsgId
    subnetAddressPrefix: hubBastionAddPrefix
    subnetName         : hubBastionSubnetName
    vnetName           : hubVnetName
  }
  scope:rg
}

module bastionOnpremNSGAttachment './modules/nsgAttachment.bicep' = {
  name: 'bastionOnpremNsgAttachment'
  params:{
    nsgId              : bastionNSG.outputs.nsgId
    subnetAddressPrefix: onpremBastionAddPrefix
    subnetName         : onpremBastionSubnetName
    vnetName           : onpremVnetName
  }
  scope:rg
}
*/
