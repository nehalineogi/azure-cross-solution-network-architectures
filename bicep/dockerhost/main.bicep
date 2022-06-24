@minLength(36)
@maxLength(36)
@description('Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query id -o tsv')
param adUserId string  = ''

@description('Set the resource group name, this will be created automatically')
@minLength(3)
@maxLength(10)
param ResourceGroupName string = 'dockerhost'

@description('Set the size for the VM')
@minLength(6)
param HostVmSize string = 'Standard_D2_v3'

targetScope            = 'subscription'

var location = deployment().location // linting warning here, but for this deployment it is at subscription level and so if we have a separate parameter specified here, 
                                     // there will be two "location" options on the "Deploy to Azure" custom deployment and this is confusing for the user.
                                

var VnetName           = 'dockervnet'
var subnetname         = 'dockersubnet'
var VnetAddressPrefix  = '172.16.0.0/16'
var subnetprefix       = '172.16.24.0/24'
var bastionSubnet      = '172.16.1.0/24'
var bastionNetworkName = 'AzureBastionSubnet'
var subnet1ref         = '${dockernetwork.outputs.vnid}/subnets/${dockernetwork.outputs.subnetname}'
var bastionNetworkref  = '${dockernetwork.outputs.vnid}/subnets/${dockernetwork.outputs.bastionSubnetName}'
var VmHostnamePrefix   = 'docker-host-'
var VmAdminUsername    = 'localadmin'

var repoName           = 'nehalineogi'
var branchName         = 'main'
var githubPath         = 'https://raw.githubusercontent.com/${repoName}/azure-cross-solution-network-architectures/${branchName}/bicep/dockerhost/scripts/'
  
resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: ResourceGroupName
  location: location
}
module kv './modules/kv.bicep' = {
  params: {
    location: location
    adUserId: adUserId
  }
  name: 'kv'
  scope: rg
}
module dockerhost1 './modules/vm.bicep' = {
  params: {
    location     : location
    adminusername: VmAdminUsername
    keyvault_name: kv.outputs.keyvaultname
    vmname       : '${VmHostnamePrefix}1'
    subnet1ref   : subnet1ref
    vmSize       : HostVmSize
    githubPath   : githubPath
    adUserId     : adUserId
  }
  name: '${VmHostnamePrefix}1'
  scope: rg
} 

module dockerhost2 './modules/vm.bicep' = {
  params: {
    location     : location
    adminusername: VmAdminUsername
    keyvault_name: kv.outputs.keyvaultname
    vmname       : '${VmHostnamePrefix}2'
    subnet1ref   : subnet1ref
    vmSize       : HostVmSize
    githubPath   : githubPath
    adUserId     : adUserId
  }
  name: '${VmHostnamePrefix}2'
  scope: rg
  dependsOn: [
    dockerhost1
  ]
} 

module dockernetwork './modules/network.bicep' = {
  params: {
    addressPrefix     : VnetAddressPrefix
    location          : location
    subnetname        : subnetname
    subnetprefix      : subnetprefix
    bastionNetworkName: bastionNetworkName
    bastionSubnet     : bastionSubnet
    virtualNetworkName: VnetName
  }

  name: 'dockernetwork'
  scope: rg
} 

module defaultNSG './modules/nsg.bicep' = {
  name: 'hubNSG'
  params:{
    location: location
    destinationAddressPrefix:dockernetwork.outputs.subnet1addressPrefix
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

module onpremNsgAttachment './modules/nsgAttachment.bicep' = {
  name: 'onpremNsgAttachment'
  params:{
    nsgId              : defaultNSG.outputs.nsgId
    subnetAddressPrefix: dockernetwork.outputs.subnet1addressPrefix                    
    subnetName         : dockernetwork.outputs.subnetname
    vnetName           : dockernetwork.outputs.vnName
  }
  scope:rg
}

module bastionNsgAttachment './modules/nsgAttachment.bicep' = {
  name: 'bastionNsgAttachment'
  params:{
    nsgId              : bastionNSG.outputs.nsgId
    subnetAddressPrefix: dockernetwork.outputs.bastionsubnetprefix                   
    subnetName         : dockernetwork.outputs.bastionSubnetName
    vnetName           : dockernetwork.outputs.vnName
  }
  scope:rg
}
module Bastion './modules/bastion.bicep' = {
  params:{
    bastionHostName: 'bastion'
    location: location
    subnetRef: bastionNetworkref
  }
  scope:rg
  name: 'bastion'
  }
