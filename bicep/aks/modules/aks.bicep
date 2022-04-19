param location string
param clusterName string
param nodeCount int = 3
param kubernetesVersion string = '1.21.9' // time writing stable release
param vmSize string = 'Standard_B4ms'
param networkPlugin string
param networkPolicy string
param enablePrivateCluster bool = false // will form part of question when private cluster code written
param podCidr string 
param serviceCidr string
param vnetSubnetID string
param serviceIP string
param dockerBridgeCidr string
param userAssignedId string

resource aks 'Microsoft.ContainerService/managedClusters@2022-01-01' = {
  name: clusterName
  location: location
  identity: {
 //   type: 'SystemAssigned'
 type:'UserAssigned'
userAssignedIdentities: {
  '${userAssignedId}' :{}
}
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${clusterName}-dns'
    enableRBAC: true
    agentPoolProfiles: [
      {
        name             : 'agentpool1'
        enableAutoScaling: false
        count            : nodeCount
        vmSize           : vmSize
        osType           : 'Linux'
        mode             : 'System'
        maxPods          : 30
        availabilityZones: []
        vnetSubnetID     : vnetSubnetID
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: networkPlugin
      networkPolicy: networkPolicy
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
      }
      outboundType: 'loadBalancer'

      podCidr         : contains (networkPlugin, 'kubenet') ?  podCidr : null
      serviceCidr     : serviceCidr
      dnsServiceIP    : serviceIP
      dockerBridgeCidr: dockerBridgeCidr

      podCidrs: contains (networkPlugin, 'kubenet') ? [
        podCidr
      ] : []

      serviceCidrs: [
        serviceCidr
      ]
      ipFamilies: [
        'IPv4'
      ]

    }
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }

  }
  sku: {
    name: 'Basic'
    tier: 'Free'
  }

}

output controlPlaneFQDN string =  aks.properties.fqdn
