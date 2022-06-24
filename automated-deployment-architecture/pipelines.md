# Pipeline Deployment

There are Azure DevOps (ADO) pipelines available that will build all types of AKS cluster (public\private and kubenet\CNI) and they are found here: [ADO Build Pipelines](../bicep/aks/pipelines).

1. Fork the repository (or clone the repository to ADO) so that you are able to provision a pipeline from the YAML definition.

2. Follow standard instructions to create a pipeline and reference the YAML files provided. 

3. Create a Service Connection to your subscription (the service connection will need to be able to create managed identities). 

4. Define three variables using the ADO User Interface, these are for the mandatory parameter inputs ADUserID, location and ServiceConnectionName 

5. Check the pipeline YAML trigger for branches include an existent branch on your repo. 

5. Define an ADO Pipelines environment called "Production" and (optionally) set up an approval gate.