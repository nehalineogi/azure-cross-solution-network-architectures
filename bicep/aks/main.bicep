@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query id -o tsv')
param ADUserID string

@description('Set the resource group name, this will be created automatically')
@minLength(3)
param ResourceGroupName string = 'aks'

@description('AKS network Plugin - kubenet or CNI')
@allowed([
  'kubenet'
  'CNI'
])
param KubenetOrCNINetworkPolicy string = 'kubenet'

@description('Choose AKS Cluster Type (this is used to define kubectl access mode)')
@allowed([
  'private'
  'public'
])
param PublicOrPrivateCluster string = 'public'

@description('Set the size for the supporting VMs (domain controller, hub DNS, VPN VM etc) ')
@minLength(6)
param SupportingServersVMSize string = 'Standard_D2_v3'

@description('Set the name of the domain eg contoso.local')
@minLength(3)
param domainName string = 'contoso.local'

// Load the JSON file depending on the parameter chosen for network plugin. Used by VNET creation below
var env = {
  kubenet: {
    vnets : json(loadTextContent('./modules/vnet/vnet_kubenet.json')).vnets
  }
  CNI: {
    vnets : json(loadTextContent('./modules/vnet/vnet_cni.json')).vnets
  }
  private: {
    vnets : json(loadTextContent('./modules/vnet/vnet_private.json')).vnets
  }
}

// Friendly parameter names used above for the custom deployment ARM presentation. Reverted to shorter names here for readability
var HostVmSize       = SupportingServersVMSize
var aksPrivatePublic = PublicOrPrivateCluster
var networkPlugin    = KubenetOrCNINetworkPolicy

var repoOwnerName = 'nehalineogi'
var branchName    = 'main'
var githubPath    = 'https://raw.githubusercontent.com/${repoOwnerName}/azure-cross-solution-network-architectures/${branchName}/bicep/aks/scripts/'

var VmAdminUsername = 'localadmin'
var location        = deployment().location    // linting warning here, but for this deployment it is at subscription level and so if we have a separate parameter specified here, 
                                               // there will be two "location" options on the "Deploy to Azure" custom deployment and this is confusing for the user.

//var hubVmName                 = 'hubjump'
//var spokeVmName               = 'spokejump'
var onpremVPNVmName           = 'vpnvm'
var publicIPAddressNameSuffix = 'vpnpip'
var hubDNSVmName              = 'hubdnsvm'

var dcVmName                  = 'dc1'
var podCidr                   = '10.244.0.0/16'

// VNet and Subnet References (module outputs)
var hubVnetId              = virtualnetwork[0].outputs.vnid
var spokeVnetId            = virtualnetwork[1].outputs.vnid
var onpremVnetId           = virtualnetwork[2].outputs.vnid
var hubVnetName            = virtualnetwork[0].outputs.vnName
var spokeVnetName          = virtualnetwork[1].outputs.vnName
var onpremVnetName         = virtualnetwork[2].outputs.vnName
var onpremSubnetName       = virtualnetwork[2].outputs.subnets[0].name
var spokeSubnetName        = virtualnetwork[1].outputs.subnets[0].name
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

var vpnVars = {
    psk                : psk.outputs.psk
    gwip               : hubgw.outputs.gwpip
    gwaddressPrefix    : hubAddressPrefix
    onpremAddressPrefix: onpremAddressPrefix
    spokeAddressPrefix : spokeAddressPrefix
    hubAddressPrefix   : hubAddressPrefix
  } 

var clusterName = 'MyAKSCluster'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
    name    : ResourceGroupName
    location: location
  }

  // NETWORKING RESOURCES //
module virtualnetwork './modules/vnet.bicep' = [for vnet in env[networkPlugin].vnets: {
  params: {
    vnetName         : vnet.vnetName
    vnetAddressPrefix: vnet.vnetAddressPrefix
    location         : location
    subnets          : vnet.subnets
    nsgDefaultId     : defaultnsg.outputs.nsgId  // attached to every vnet. Overwritten if another NSG is defined and attached

  }

  name: '${vnet.vnetName}'
  scope: rg
} ]

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
    hubgw
  ]
}

module bastionNSG './modules/nsg/nsg_bastion.bicep' = {
  name: 'bastionNSG'
  params:{
    location: location
  }
scope:rg
}
module defaultnsg './modules/nsg/nsg_default.bicep' = {
  name : 'default-nsg'
  params: {
    location: location
  }
  scope: rg
}
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

module hubgw './modules/vnetgw.bicep' = {
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
    location: location
    addressSpace:  onpremAddressPrefix
    ipAddress: onpremVpnVM.outputs.VmIp
    name: 'onpremgw'
  }
}
module vpnconn 'modules/vpnconn.bicep' = {
  scope: rg
  name: 'onprem-azure-conn'
  params: {
    location: location
    psk     : psk.outputs.psk
    lngid   : localNetworkGW.outputs.lngid
    vnetgwid: hubgw.outputs.vnetgwid
    name    : 'onprem-azure-conn'
    
  }
}

// GENERAL RESOURCES //
module kv './modules/kv.bicep' = {
  params: {
    location: location
    adUserId: ADUserID
  }
  name : 'kv'
  scope: rg
}

// HUB & SPOKE RESOURCES //
module hubBastion './modules/bastion.bicep' = {
  params:{
    bastionHostName: 'hubBastion'
    location: location
    subnetRef: hubBastionSubnetRef
  }
  scope:rg
  name: 'hubBastion'
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
    adUserId     : ADUserID
    vpnVars      : vpnVars
    deployHubDns : true

  }
  name: 'hubDnsVM'
  scope: rg
} 
module akssubnetNSG './modules/nsg/nsg_akssubnet.bicep' = {
  name: 'akssubnetNSG'
  params:{
    location: location
  }
scope:rg
}

module aksNsgAttachment './modules/nsgAttachment.bicep' = {
  name: 'aksNsgAttachment'
  params:{
    nsgId              : akssubnetNSG.outputs.NsgId
    subnetAddressPrefix: spokeAddressPrefix                    
    subnetName         : spokeSubnetName
    vnetName           : spokeVnetName
  }
  scope:rg
}
module aks_user_identity 'modules/identity.bicep' = {
  name: 'aks_user_identity'
  params: {
    location: location
    prefix  : 'aks_user_'
  }
  scope: rg
}
module user_assigned_RBAC_assign './modules/rbac_assign.bicep' = {
  name: 'assign-RBAC-to-aks-rg' 
  params: {
    location               : location
    principalId            : aks_user_identity.outputs.principleId
    roleDefinitionIdOrNames: [
      'Network Contributor' 
      'Private DNS Zone Contributor'
    ]
  }
  scope: rg
}
module privateDNSZone 'modules/privatezone.bicep' = if (contains(aksPrivatePublic, 'private')) {
  name: 'create-DNS-private-zone-for-AKS'
  params: {
    privateDNSZoneName: '${clusterName}.privatelink.${location}.azmk8s.io'
  }
  scope: rg
}
module privateDNSZoneLinkSpoke 'modules/privatezonelink.bicep' = if (contains(aksPrivatePublic, 'private')){
  name: 'link-DNS-zone-to-spoke-vnet'
  params: {
    privateDnsZoneName: contains(aksPrivatePublic, 'private') ? privateDNSZone.outputs.privateDNSZoneName : ''
    vnetId: spokeVnetId
    vnetName: spokeVnetName
  }
  scope: rg
}

module privateDNSZoneLinkHub 'modules/privatezonelink.bicep' = if (contains(aksPrivatePublic, 'private')){
  name: 'link-DNS-zone-to-hub-vnet'
  params: {
    privateDnsZoneName: contains(aksPrivatePublic, 'private') ? privateDNSZone.outputs.privateDNSZoneName : ''
    vnetId: hubVnetId
    vnetName: hubVnetName
  }
  scope: rg
}
module aks_cluster 'modules/aks.bicep' = {
  name: 'aks_cluster' 
  params: {
    clusterName         : clusterName
    location            : location
    networkPlugin       : contains(networkPlugin, 'CNI') ? 'azure' : 'kubenet'
    networkPolicy       : 'calico'
    vnetSubnetID        : SpokeSubnetRef
    dockerBridgeCidr    : '172.20.0.1/16'
    podCidr             : podCidr
    serviceCidr         : '10.101.0.0/16'
    serviceIP           : '10.101.0.10'
    PublicPrivateCluster: aksPrivatePublic
    privateDNSZoneId    : contains(aksPrivatePublic, 'private') ? privateDNSZone.outputs.privateDNSZoneId : ''
    userAssignedId      : aks_user_identity.outputs.uId
  }
  scope: rg
}

// The VM passwords are generated at run time and automatically stored in Keyvault. 
// It is not possible to create a loop through the vm var because the 'subnetref' which is an output only known at runtime is not calculated until after deployment. It is not possible therefore to use it in a loop.
// module hubJumpServer './modules/vm.bicep' = {
//   params: {
//     location     : location
//     windowsVM    : true
//     deployDC     : false
//     adminusername: VmAdminUsername
//     keyvault_name: kv.outputs.keyvaultname
//     vmname       : hubVmName
//     subnet1ref   : hubSubnetRef
//     vmSize       : HostVmSize
//     githubPath   : githubPath
//     adUserId     : ADUserID

//   }
//   name: 'hubjump'
//   scope: rg
// }  
// module spokeJumpServer './modules/vm.bicep' = {
//   params: {
//     location     : location
//     windowsVM    : true
//     adminusername: VmAdminUsername
//     keyvault_name: kv.outputs.keyvaultname
//     vmname       : spokeVmName
//     subnet1ref   : SpokeSubnetRef
//     vmSize       : HostVmSize
//     githubPath   : githubPath
//     adUserId     : ADUserID
//   }
//   name: 'spokejump'
//   scope: rg
// }  

// ON-PREM RESOURCES // 

module onpremBastion './modules/bastion.bicep' = {
  params:{
    bastionHostName: 'onpremBastion'
    location: location
    subnetRef: onpremBastionSubnetRef
  }
  scope:rg
  name: 'onpremBastion'
  }
module psk 'modules/psk.bicep' = {
  scope: rg
  name: 'psk'
  params: {
    keyvault_name  : kv.outputs.keyvaultname
    onpremSubnetRef: onpremSubnetRef
    name           : 'azure-conn'
  }
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
    adUserId     : ADUserID
    pDNSZone     : contains(aksPrivatePublic, 'private') ? privateDNSZone.outputs.privateDNSZoneName : 'placeholder.placeholder.placeholder'
    HubDNSIP     : hubDnsVM.outputs.VmPrivIp
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
    adUserId                 : ADUserID
  }
  name: 'onpremVpnVM'
  scope: rg
} 
module onpremNSG './modules/nsg/nsg_onprem.bicep' = {
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
    location           : location
    applianceAddress   : onpremVpnVM.outputs.VmPrivIp
    nsgId              : onpremNSG.outputs.onpremNsgId
    hubAddressPrefix   : hubAddressPrefix
    spokeAddressPrefix : spokeAddressPrefix
    subnetAddressPrefix: onpremAddressPrefix
    subnetName         : onpremSubnetName
    vnetName           : onpremVnetName
  }
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
