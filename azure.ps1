#connect to azure and script strings
Connect-AzAccount


$location = "westeurope"
$resourceGroupName = "zidane-sentia"
$storageAccountName = "zidanesentiastorage"
$keyVaultName = "zidane-sentia-key"
$keyVaultSpAppId = "cfa8b339-82a2-471a-a3c9-0fc0be7a4093"
$VN = "zidane-sentia-network"
$storageAccountKey = "key1"
$userID = "z@azidane2018gmail.onmicrosoft.com"
$IP = "sentiatestip"
$sitename = "zidanesentia"



#set subscription
Set-AzContext -SubscriptionId "1cd8f645-3307-424c-828a-77723a9c9cdf"


#create resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag @{Sentia=“pre-prod-resourcegroup"}


#create storage account
New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -skuname Standard_LRS -kind StorageV2 -Tag @{Sentia=“pre-prod-storage"} -EnableHierarchicalNamespace $True


#create Key Vault
New-AzKeyVault -Name $keyVaultName -ResourceGroupName $resourceGroupName -Location $location -tag @{Sentia=“pre-prod-key"}


#configure and connect key vault with the storage account
$storageaccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName
New-AzRoleAssignment -ApplicationId $keyVaultSpAppId -RoleDefinitionName 'Storage Account Key Operator Service Role' -Scope $storageaccount.Id 
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -UserPrincipalName $userId -PermissionsToStorage get, list, delete, set, update, regeneratekey, getsas, listsas, deletesas, setsas, recover, backup, restore, purge
$regenPeriod = [System.Timespan]::FromDays(20)
Add-AzKeyVaultManagedStorageAccount -VaultName $keyVaultName -AccountName $storageAccountName -AccountResourceId $storageaccount.id -ActiveKeyName $storageAccountKey -RegenerationPeriod $regenPeriod



#Set and retrieve a secret from Azure Key Vault
$secretvalue = ConvertTo-SecureString 'hVFkk965BuUv' -AsPlainText -Force
$secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'sentia' -SecretValue $secretvalue
(Get-AzKeyVaultSecret -vaultName $keyVaultName -name "sentia").SecretValueText


#Create Network 
$sub = New-AzVirtualNetworkSubnetConfig -Name sentiaSubnet -AddressPrefix "10.0.1.0/24"
New-AzVirtualNetwork -Name $VN -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $sub -Tag @{Sentia=“pre-prod-VN"}



#Enable service endpoint for Azure Storage on an existing virtual network and subnet.
Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vn | Set-AzVirtualNetworkSubnetConfig -Name sentiaSubnet -AddressPrefix "10.0.1.0/24" -ServiceEndpoint "Microsoft.Storage" | Set-AzVirtualNetwork



#Add a network rule for a virtual network and subnet.
$subnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $VN | Get-AzVirtualNetworkSubnetConfig -Name sentiaSubnet
Add-AzStorageAccountNetworkRule -ResourceGroupName $resourceGroupName -Name $storageAccountName -VirtualNetworkResourceId $subnet.id



#create webapp
New-AzAppServicePlan -Name newsite -ResourceGroupName $resourceGroupName -Location $location
New-AzWebApp -Name $sitename -AppServicePlan newsite -ResourceGroupName $resourceGroupName -Location $location

$i = Get-AzResource -Name newsite -ResourceGroupName $resourceGroupName
Set-AzResource -ResourceId $i.Id -tag @{Sentia=“pre-prod-appplan"} -force

$ii = Get-AzResource -Name $sitename -ResourceGroupName $resourceGroupName
Set-AzResource -ResourceId $ii.Id -tag @{Sentia=“pre-prod-web"} -force



# Get Connection String for Storage Account
$StorageKey=(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupname -Name $StorageaccountName).Value[0]

# Assign Connection String to App Setting 
Set-AzWebApp -ConnectionStrings @{ MyStorageConnStr = @{ Type="Custom"; Value="DefaultEndpointsProtocol=https;AccountName=$StorageaccountName;AccountKey=$StorageKey;" } } -Name $siteName -ResourceGroupName $ResourceGroupname



#connect website to key vault secret through app setting
$secreturi = (Get-AzKeyVaultSecret -vaultName $keyVaultName -name "sentia").id
$appsitval = "@Microsoft.KeyVault(SecretUri=$secreturi)"
Set-AzWebApp -Name $sitename -ResourceGroupName $resourceGroupName -AppSettings @{azurekeyvaultsentia=$appsitval}


#IP and Application Gateway ( load balancer ) 
$url = 'https://' + $sitename + '.azurewebsites.net/'
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -Name $IP -AllocationMethod Dynamic -Tag @{Sentia=“pre-prod-ip"}
$gipconfig = New-AzApplicationGatewayIPConfiguration -Name SentiaIPConfig -Subnet $subnet
$fipconfig = New-AzApplicationGatewayFrontendIPConfig -Name SentiaFrontendIPConfig -PublicIPAddress $pip
$frontendPort = New-AzApplicationGatewayFrontendPort -Name SentiaFrontendPort -Port 80
$defaultPool = New-AzApplicationGatewayBackendAddressPool -Name SentiadefaultPool 
$poolSettings = New-AzApplicationGatewayBackendHttpSettings -Name SentiaPoolSettings -Port 80 -Protocol Http -CookieBasedAffinity Enabled -RequestTimeout 120
$defaultListener = New-AzApplicationGatewayHttpListener -Name defaultListener -Protocol Http -FrontendIPConfiguration $fipconfig -FrontendPort $frontendport
$redirectConfig = New-AzApplicationGatewayRedirectConfiguration -Name Sentiaredirect -RedirectType Temporary -TargetUrl $url
$redirectRule = New-AzApplicationGatewayRequestRoutingRule -Name redirectRule -RuleType Basic -HttpListener $defaultListener -RedirectConfiguration $redirectConfig
$sku = New-AzApplicationGatewaySku -Name Standard_Small -Tier Standard -Capacity 2
$appgw = New-AzApplicationGateway -Name SentiaAppGateway -ResourceGroupName $resourceGroupName -Location $location -BackendAddressPools $defaultPool -BackendHttpSettingsCollection $poolSettings -FrontendIpConfigurations $fipconfig -GatewayIpConfigurations $gipconfig -FrontendPorts $frontendport -HttpListeners $defaultListener -RequestRoutingRules $redirectRule -RedirectConfigurations $redirectConfig -Sku $sku -Tag @{Sentia=“pre-prod-AG"}



Get-AzPublicIPAddress -ResourceGroupName $resourceGroupName -Name $IP











