# Bicep Deployment for docker single host and multi host architectures

In this section you will find bicep code to deploy the single and multihost foundational platforms as described in the docker section of the AKS learning series. 

This code can be deployed in the usual way using `az cli` or `powershell` as detailed [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli)  

For convenience you can follow the quickstart deployment below to get started quickly. 

# Quickstart deployment

### Task 1: clone the repository and deploy

1. Open cloud shell and clone this repository 

``` 
git clone https://github.com/nehalineogi/azure-cross-solution-network-architectures 
```

2. Navigate to the bicep location that contains the code

```
cd azure-cross-solution-network-architectures/bicep/dockerhost/
```

3. Retrieve your signed-in user ID below (this is used to apply access to Keyvault).

```
az ad signed-in-user show --query objectId -o tsv
```

3.  Run the following command to deploy using az cli

```
 az deployment create --name docker --template-file .\main.bicep --location uksouth --parameters adUserId=paste-asUserId-here 
 ```

 example deployment command: 

 ```
 az deployment create --name docker --template-file .\main.bicep --location uksouth --parameters adUserId=11111111-2222-3333-4444-555555555555
 ```

4. sing Azure Bastion, log in to the VMs using the username `localadmin` and passwords from keyvault.