<#
.SYNOPSIS
    This script automates the creation of Azure resources using a Bicep template.

.DESCRIPTION
    The script performs the following tasks:
    1. Sets the execution policy to bypass for the current process.
    2. Defines variables for the resource group, location, Bicep file, tenant ID, and subscription ID.
    3. Installs Azure CLI if not already installed.
    4. Logs into Azure using the specified tenant ID.
    5. Sets the specified subscription as the default.
    6. Creates a new resource group in the specified location.
    7. Deploys resources using the Bicep template.
    8. Retrieves outputs from the deployment to create indexes.
    9. Executes a script to set up the search service.
    10. Measures and outputs the script execution time.

.PARAMETER newRG
    Name of the new resource group. All resources will be created here.

.PARAMETER loc
    The location where the resources will be created. Select the region closest to you.

.PARAMETER bicepFile
    Filepath to the Bicep file.

.PARAMETER tenant
    Tenant ID for Azure login.

.PARAMETER sub
    Subscription ID for Azure.

.EXAMPLE
    .\AddResource.ps1

.NOTES
    Author: RHAIL Dev team
    Date: 2025-03-06
#>


$TENANT_ID          = "173067a1-3a44-4188-b228-16116e7d918a"
$APP_SUBSCRIPTION   = "97f06315-af81-43d7-bbf1-c9db17d18fd6"
$INFRA_SUBSCRIPTION = "a842fb1b-f221-4b5c-940e-416626031548"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

New-Variable -name tenant -Value $TENANT_ID -Description "Tenant ID for Azure login" -Force
New-Variable -Name sub -Value $INFRA_SUBSCRIPTION -Description "ID of the Azure Sponsorship Sub" -Force
New-Variable -Name newRG -Value "ClaimCopilot-RG" -Description "Name of the new resource group. All resources will be here" -Force
New-Variable -name loc -Value "East US 2" -Description "The location you want your resources created in. Select region closest to you" -Force
New-Variable -name bicepFile -Value ./main.bicep -Description "Filepath to the bicep file" -Force
$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
Write-Output "[$timestamp] Start creation"


#check if successfully installed
az login --tenant $tenant
#add sub
az account set --subscription $sub
#create new resource group if it doesn't exist
az group create --name $newRG --location $loc 2>$null
#deploy the resources
try{
    az deployment group create --resource-group $newRG --template-file $bicepFile --name DeployResources_$timestamp --only-show-errors
    
    if ($LASTEXITCODE -ne 0) {
        throw "Deployment failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "Resources created !" -ForegroundColor Green
    
    #get outputs from deployment to create indexes
    Write-Host "Retrieving deployment outputs..." -ForegroundColor Cyan
    $searchServiceName = az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.searchServicesName.value -o tsv
    $connString = az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.dataSourceConnectionString.value -o tsv
    $storageAccount =  az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.storageAccountName.value -o tsv
    $containerRec = az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.containerNameRec.value -o tsv
    $containerParse = az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.containerNameParse.value -o tsv
    
    Write-Host "Search Service: $searchServiceName" -ForegroundColor Yellow
    Write-Host "Storage Account: $storageAccount" -ForegroundColor Yellow
    
    if ([string]::IsNullOrWhiteSpace($searchServiceName)) {
        throw "Failed to retrieve searchServiceName from deployment outputs"
    }

    .\IndexResource\SetupSearchService_v1.ps1 -searchServiceName $searchServiceName -dataSourceConnectionString $connString -storageAccountName $storageAccount -containerNameRec $containerRec -containerNameParse $containerParse -rgName $newRG

    Write-Host "Indexes created! Script complete" -BackgroundColor Green
}
catch{
    Write-Host "Deployment failed!" -ForegroundColor Red
    Write-Error $_.Exception.Message
    throw
}
