# Bicep Deployment for AKS Kubenet and CNI deployment

In this section you will find bicep code to deploy a public or private AKS cluster as either kubenet or CNI network configured.

This code can be deployed using `az cli` or `powershell` as detailed [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli)  

For convenience you can also follow the quickstart deployment below to get started. 

For configuration of Front Door for ingress, this is currently best done after deployment of the cluster by following the instructions [AKS Private Cluster with Azure Front Door](../../aks/README-private-cluster-with-AFD.md)

There are also ADO pipelines available that will build all types of AKS cluster (public\private and kubenet\CNI) and they are found here: [ADO Build Pipelines](../aks/pipelines/)

# Quickstart deployment

### Task 1: clone the repository and deploy

1. Open cloud shell and clone this repository 

``` 
git clone https://github.com/nehalineogi/azure-cross-solution-network-architectures 
```

2. Navigate to the bicep location that contains the code

```
cd azure-cross-solution-network-architectures/bicep/aks/
```

3. Retrieve your signed-in user ID below (this is used to apply access to Keyvault).

```
az ad signed-in-user show --query objectId -o tsv
```

4. (optional) If you wish to customise or change the main.bicep or related module code, you can do this now and save your changes locally.  


5.  Run the following command to deploy using az cli

```
 az deployment sub create --name aks --template-file main.bicep --location [region] --parameters ADUserID=[paste-asUserId-here] KubenetOrCNINetworkPolicy=[kubenet\azure] PublicOrPrivateCluster=[public\private]
 ```

 example : 

 ```
 az deployment sub create --name aks --template-file main.bicep --location [region] --parameters ADUserID=11111111-2222-3333-4444-555555555555 KubenetOrCNINetworkPolicy=kubenet PublicOrPrivateCluster=public
 ```

6. Once your deployment has finished you can log on to the supporting VMs using Azure bastion. The username is `localadmin` and passwords can be found in the keyvault. The AKS cluster using kubectl (see page links below).

For further information on the deployment, setting up SSH to the hosts and advanced troubleshooting please refer to the docker series pages [here (kubenet)](../../aks/README-kubenet.md) and [here (cni)](../../aks/README-advanced.md).

As an alternative you may wish to use your own device or an alternative VM to run the steps above, for this you will need to ensure all the tools are installed including az cli, git, az cli aks tools. There is a helpful powershell script that may aid you with this task - [Tool deployment script](./scripts/install_edge_and_azcli.ps1)