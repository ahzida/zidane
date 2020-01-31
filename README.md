# zidane

What?

this script is created to deploy storage account, keyvault, web app, virtual network and app gateway. then connecting all resources together.

1- started the script with sitting some values to use later for naming the resources and calling it.
2- create data lake gen 2 by enabling (Hierarchical Name space).
3- key vault created key vault secret creted and connected to datalake gen 2 storage.
4- Vlan and subnet created and enabled service endpoint for Azure Storage on newly createed virtual network and subnet.
5- created a saas web app (as it's fast, low cost, easy to configure, scalable and many features).
6- connected the web app to the database through connection string.
7- connected the web app to the keyvault through app setting.
8- created an app gateway and public IP then i connected them to the web app so you can access this app through the app gateway.



How?

- you can use "Azure.ps1" script with az powershell module "https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.3.0" it will create all the resources in a resource group and at the end it will represent the app gatewat public IP address to access the site.

- you can select template deployment on azure and use the ARM Template " template.JSON "
