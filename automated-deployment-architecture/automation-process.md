# Automation Process

This series includes architectures which can be deployed automatically via "Deploy to Azure" buttons found below the architectural diagrams throughout this series. 

This section discusses the method used to build the environments using Bicep, transpiling to ARM template to allow a custom deployment to Azure. 

## Reference Architecture

![Build Process](images/workflow-build-deploytoazure.png)

1. Azure resources are built in Bicep to define the entire environment, code can be found here ([Bicep Code](/bicep)).
2. The bicep code is transpiled to a standard ARM template using the ```bicep build``` command. Each design will have it's own ARM template hosted in this repo.
3. A "Deploy to Azure" button is configured to allow a custom deployment using the hosted ARM template. Instructions for using this facility can be found [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-azure-button).

4. The "Deploy to Azure" button is embedded into the markdown pages in this series for each deployable architecture.