### add timer
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

New-Variable -Name newRG -Value "DemoResourceGroup" -Description "Name of the new resource group. All resources will be here" -Force
New-Variable -name loc -Value "East US 2" -Description "The location you want your resources created in. Select region closest to you" -Force
New-Variable -name bicepFile -Value .\Create-Resources.bicep -Description "Filepath to the bicep file" -Force
New-Variable -name tenant -Value "a0cd96fb-d02f-45bd-9b83-6b72e7f56f7d" -Force
New-Variable -Name sub -Value "7e619287-10da-4c1c-83d1-67a75a5d6298" -Description "ID of the Azure Sub"
$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
Write-Output "[$timestamp] Start creation"

#install necessary modules
# Check if Azure CLI is installed
if (Get-Command az -ErrorAction SilentlyContinue) {
    Write-Output "Azure CLI is already installed."
} else {
    Write-Output "Azure CLI is not installed. Installing now..."
    # Download and install Azure CLI
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
    Start-Process msiexec.exe -ArgumentList '/I AzureCLI.msi /quiet' -Wait
    Remove-Item .\AzureCLI.msi
    Write-Output "Azure CLI installation completed."
}

#check if successfully installed

az login --tenant $tenant
az account set --subscription $sub
#create new resource group
az group create --name $newRG --location $loc
#deploy the resources
try{
    az deployment group create --resource-group $newRG --template-file $bicepFile --name DeployResources_$timestamp --only-show-errors
    Write-Host "Resources created !" -ForegroundColor Green
    #get outputs from deployment to create indexes
    $searchServiceName = az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.searchServicesName.value
    $connString = az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.dataSourceConnectionString.value
    $storageAccount =  az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.storageAccountName.value
    $containerRec = az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.containerNameRec.value
    $containerParse = az deployment group show -g $newRG -n DeployResources_$timestamp --query properties.outputs.containerNameParse.value

    .\IndexResource\SetupSearchService_v1.ps1 -searchServiceName $searchServiceName -dataSourceConnectionString $connString -storageAccountName $storageAccount -containerNameRec $containerRec -containerNameParse $containerParse -rgName $newRG

    Write-Host "Indexes created! Script complete" -BackgroundColor Green
    #### write execution time
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    Write-Host "Script execution time: $executionTime" 
}
catch{

      Write-Error $_.ErrorDetails.Message
        throw
}