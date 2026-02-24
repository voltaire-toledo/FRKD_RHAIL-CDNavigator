 az login
 az resource list --resource-group "RHAILAutocreate-Test-2025" --query "[].{Name:name, Type:type, State:properties.provisioningState}" --output table
 
<# Connect-AzAccount
 Get-AzResource -ResourceGroupName "RHAILAutocreate-Test-2025"  | Select-Object Name, ResourceType, ProvisioningState#>
Get-AzStorageAccount -ResourceGroupName "RHAILAutocreate-Test-2025" -Name "7nlo4fzsdopoc"| Select-Object -ExpandProperty EnableSoftDelete

Get-AzSearchService -ResourceGroupName "RHAILAutocreate-Test-2025" -Name "rhailsearchsscsk5zcsgcns" | Select-Object -ExpandProperty Properties

#az storage account show --name "7nlo4fzsdopoc" --resource-group "RHAILAutocreate-Test-2025" --query "properties.enableSoftDelete"
 
 az cognitiveservices account show --name "RHAILModelsscsk5zcsgcns" --resource-group "RHAILAutocreate-Test-2025" --query "properties"
  