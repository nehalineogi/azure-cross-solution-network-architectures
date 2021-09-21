
# APIM Developer Portal Identity Integration

This architecture shows how to enable access to the developer portal using both Azure AD (AAD B2B) and Azure AD B2C. Includes screen captures showing the overall sign in experience.

# Reference Architecture
![AAD Identity Provider](images/identity/apim-identity-architecture.png)


# Azure Documentation

[AAD Dev Portal Integration](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-aad)

[B2C Dev Portal Integration](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-aad-b2c)

# Design Components and Considerations

0. **Traffic Flows**
   
   1. Blue/Cyan : Backend API Connections
   2. Green: Developer Portal Sign in experience using AAD
   3. Red: Developer Portal Sign-in experience  using B2C
  

1. Note: The above diagram shows the APIM internal mode with Application gateway but it can be used with External and Default mode as well. Detailed implementation of [internal](README-internal.md) and [external](README-external.md) is explained in previous sections in this series.
2. Basic Authentication is the default methad the is available with API Management.
3. AAD Auth allows access to the developer portal from users from Azure AD or Corporate AD accounts sync'd to AAD using Azure AD Connect
4. AAD B2C Auth (Requires Premium Tier)
5. There are three different tenants
   1. AAD Tenant(Custom Domain: penguintrails.com, default domain: xxxx.onmicrosoft.com)
   2. B2C Tenant (nnb2cdomain.onmicrosoft.com) associated with AAD tenant(penguintrails.com)
   3. Tenant where APIM resources are deployed.


# Pre-requisites
Using Azure documentation link [here](https://docs.microsoft.com/en-us/azure/api-management/import-and-publish) ensure that you've external APIM in the internal mode.

Refer to common documentation link [here](README-common.md) for more details on pre-requisites
1. APIM in deployed in internal mode.
2. Products,APIs and subscriptions created
3. VPN or Private Connectivity is optional in this design
4. Internal and External APIs routable from APIM subnet
5. Azure Provided default DNS resolution for API endpoints.
6. Developer Portal Published
7. Troubleshooting Notes - [here](README-troubleshooting.md).

# Basic Auth

This method is the default method that comes with API management and is based on Username and Password.

## APIM Side (Default Configuration)


![AAD Identity Provider](images/identity/basic-auth.png)

## User Experience is as follows:

#### When accessing developer portal the user gets a sign in page
![AAD Identity Provider](images/identity/basic-sign-up-experience.png)

## Confirmation Email goes to the user email ID

![AAD Identity Provider](images/identity/basic-confirmation-email.png)



## User gets automatically added in APIM
![AAD Identity Provider](images/identity/basic-users.png)

# Azure AD

## APIM Side Configuration

![AAD Identity Provider](images/identity/aad-add-identity-provider.png)
![AAD Identity Provider](images/identity/aad-indentity-provider.png)

## Azure AD Tenant side Configuration

### Register the application

![AAD Identity Provider](images/identity/aad-register-app-developer-portal.png)
![AAD Identity Provider](images/identity/add-permissions-microsoft-graph.png)


![AAD Identity Provider](images/identity/aad-id-token.png)

### Import the AAD Group

![AAD Identity Provider](images/identity/apim-developer-aad-group.png)
#### If permissions are not setup correctly it will result in this error
![AAD Identity Provider](images/identity/graph-api-error.png)

## AAD User Experience
![AAD Identity Provider](images/identity/aad-signup-experience.png)
## User is automatically added in APIM
![AAD Identity Provider](images/identity/aad-users-after-registration.png)




# Azure AD B2C

## Azure Documentation
[AAD Dev Portal Integration](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-aad-b2c)
[AAD Dev Portal Integration](https://docs.microsoft.com/en-us/azure/active-directory-b2c/secure-api-management?tabs=app-reg-ga)

## Pre-requisites
Make sure the following prequisites are completed. More documentation here.

[Azure AD B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant)

[Application registered in your tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga)

[User flows created in your tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-user-flow)
	
[Published API in Azure API Management](https://docs.microsoft.com/en-us/azure/api-management/import-and-publish)


## An Azure AD B2C tenant
![b2c Dev Portal](images/identity/b2c-tenant.png)

## Signup and Signin User flows that are created in your tenant
![b2c Dev Portal](images/identity/b2c-tenant-signin-up-user-flow.png)
![b2c Dev Portal](images/identity/idp.png)
![b2c Dev Portal](images/identity/b2c-claims.png)
![b2c Dev Portal](images/identity/b2c-user-attributes.png)



## An application that's registered in b2C  tenant

![b2c Dev Portal](images/identity/b2c-register-application.png)
![b2c Dev Portal](images/identity/b2c-redirect-URI-grant.png)
![b2c Dev Portal](images/identity/b2c-register-application.png)





## APIM Configuration in Azure Portal

Add Identity Provider to APi Management Portal
![b2c Dev Portal](images/identity/b2c-add-identity-provider.png)

## Publish the API in Azure API Management

![b2c Dev Portal](images/identity/b2c-publish-portal.png)

## Full Sign in experience

![b2c Dev Portal](images/identity/b2c-sign-up-experience.png)

## User Created
![b2c Dev Portal](images/identity/b2c-users.png)




# TODO:

1. [Protect backend API](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-protect-backend-with-aad)