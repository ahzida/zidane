# Zidane ARM Template



# What?

This script is created to deploy storage account, keyvault, web app, virtual network and app gateway, then connecting all resources together.

1- Started the script with setting some values to use later for naming the resources and calling it.

2- Create data lake gen 2 by enabling (Hierarchical Name space).
https://docs.microsoft.com/en-gb/azure/storage/common/storage-account-create?tabs=azure-powershell

3- Key vault and key vault secret created and connected to datalake gen 2 storage.

4- VLan and subnet created and enabled service endpoint for Azure Storage on newly createed virtual network and subnet.

5- Created a SAAS web app (as it's fast, low cost, easy to configure, scalable).

6- Connected the web app to the database through connection string.

7- Connected the web app to the key vault through app settings.

8- Created an app gateway and public IP then i connected them to the web app so you can access this app through the app gateway.



# How?

You can use two methods to deploy the resources:


1- You can use "Azure.ps1" script with az powershell module "https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.3.0" it will create all the resources in a resource group and at the end it will represent the app gateway public IP address to access the site.

2- you can select template deployment on azure and use the ARM Template " template.JSON "


# Note:

Instead of storing Resource Manager templates on your local machine, you may prefer to store them in an external location. You can store templates in a source control repository (such as GitHub). Or, you can store them in an Azure storage account for shared access in your organization.

To deploy an external template, use the TemplateUri parameter. Use the URI in the example to deploy the sample template from GitHub.

#Azure PowerShell

$resourceGroupName = Read-Host -Prompt "Enter the Resource Group name"
$location = Read-Host -Prompt "Enter the location (i.e. centralus)"

New-AzResourceGroup -Name $resourceGroupName -Location $location
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-storage-account-create/azuredeploy.json
