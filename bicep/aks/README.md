# Bicep Deployment for AKS Kubenet and CNI deployment

In this section you will find bicep code to deploy AKS as a kubenet or CNI network configuration.

This code can be deployed using `az cli` or `powershell` as detailed [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli)  

For convenience you can also follow the quickstart deployment below to get started. 

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


5.  Run the following command to deploy using az cli (networkPlugin parameter value 'kubenet' for a kubenet deployment or 'azure' to provision a CNI based cluster)

```
 az deployment sub create --name aks --template-file main.bicep --location [region] --parameters adUserId=[paste-asUserId-here] networkPlugin=[kubenet\azure]
 ```

 example : 

 ```
 az deployment sub create --name aks --template-file main.bicep --location [region] --parameters adUserId=11111111-2222-3333-4444-555555555555 networkPlugin=kubenet
 ```

6. Once your deployment has finished you can log on to the supporting VMs using Azure bastion. The username is `localadmin` and passwords can be found in the keyvault. The AKS cluster using kubectl (see page links below).

For further information on the deployment, setting up SSH to the hosts and advanced troubleshooting please refer to the docker series pages [here (kubenet)](../../aks/README-kubenet.md) and [here (cni)](../../aks/README-advanced.md).