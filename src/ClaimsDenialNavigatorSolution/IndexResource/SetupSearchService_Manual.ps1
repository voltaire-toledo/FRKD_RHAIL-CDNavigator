## This script adds indexers via API calls to complete the AI index set up process 
## hard coded for recs and parse containers based on previous bicep file.

# Load environment variables from .env file
if (Test-Path "$PSScriptRoot/../../../.env") {
    Get-Content "$PSScriptRoot/../../../.env" | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
}

$searchServiceName = $env:AZURE_SEARCH_SERVICE_NAME
$dataSourceConnectionString = $env:AZURE_STORAGE_CONNECTION_STRING
$storageAccountName = $env:AZURE_STORAGE_ACCOUNT_NAME
$containerNameRec = $env:CONTAINER_NAME_REC
$containerNameParse = $env:CONTAINER_NAME_PARSE
$rgName = $env:RESOURCE_GROUP_NAME


#uncomment these if needed. the modules below are needed to run script successfuly
az login
#Install-Module -Name Az -Force
#Install-Module -Name Az.search -Force


##### set additional variables for api calls 
$apiversion = '2024-07-01' 
$searchServiceName = $searchServiceName.Replace("`"","")
$storageAccountName = $storageAccountName.Replace("`"","")
$containerNameParse = $containerNameParse.Replace("`"","")
$containerNameRec = $containerNameRec.Replace("`"","")
$dataSourceConnectionString = $dataSourceConnectionString.Replace("`"","")
#$apiKey = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $searchServiceName | select Primary

$apiKey = az search admin-key show --resource-group $rgName --service-name $searchServiceName --query primaryKey
$apiKey =$apiKey.Replace("`"","")
#Write-Output $apiKey

##### create the api headers and bodies
$headers = @{ 'api-key' = "$apiKey"; 'Content-Type' = 'application/json'; }
$uri = "https://$searchServiceName.search.windows.net"

### create JSON for indexes 
$jsonRecsPath = '.\IndexResource\recsIndexProfile.json'
$jsonRecsContent = Get-Content -Path $jsonRecsPath 
$jsonRecsName = Get-Content -Path $jsonRecsPath | ConvertFrom-Json
$jsonRecsName = $jsonRecsName.name
$jsonParsePath = '.\IndexResource\parseIndexProfile.json'
$jsonParseContent = Get-Content -Path $jsonParsePath 
$jsonParseName = Get-Content -Path $jsonParsePath | ConvertFrom-Json
$jsonParseName = $jsonParseName.name

#edit json to have correct datasource name for indexer
$jsonRecIndexerPath = ".\IndexResource\indexerRec.json"
$jsonRecIndexerContent = Get-Content -Path $jsonRecIndexerPath -Raw | ConvertFrom-Json
$jsonRecIndexerContent.dataSourceName = "$($storageAccountName)recs"
$jsonRecIndexerName = $jsonRecIndexerContent.name
$jsonRecIndexerContent| ConvertTo-Json -Depth 32 | Set-Content -Path $jsonRecIndexerPath
$jsonRecIndexerContent = Get-Content -Path $jsonRecIndexerPath


$jsonParseIndexerPath = ".\IndexResource\indexerParse.json"
$jsonParseIndexerContent = Get-Content -Path $jsonParseIndexerPath -Raw | ConvertFrom-Json
$jsonParseIndexerContent.dataSourceName = "$($storageAccountName)parse"
$jsonParseIndexerName = $jsonParseIndexerContent.name
$jsonParseIndexerContent| ConvertTo-Json -Depth 32 | Set-Content -Path $jsonParseIndexerPath
$jsonParseIndexerContent = Get-Content -Path $jsonParseIndexerPath


#create datasource defs
######################################################################
$dataSourceDefinitionRec = @{
        'name' = "$($storageAccountName)recs";
        'type' = 'azureblob';
        'container' = @{
            'name' = $containerNameRec;
        };
        'credentials' = @{
            'connectionString' = $dataSourceConnectionString
        };
    }

$dataSourceDefinitionParse = @{
        'name' = "$($storageAccountName)parse";
        'type' = 'azureblob';
        'container' = @{
            'name' = $containerNameParse;
        };
        'credentials' = @{
            'connectionString' = $dataSourceConnectionString
        };
    }


try {
    # https://learn.microsoft.com/rest/api/searchservice/create-index
    ####create the 2 indexes 

    ##create parse index
    Invoke-WebRequest `
        -Method 'PUT' `
        -Uri "$uri/indexes/$($jsonParseName)?api-version=$apiversion" `
        -Headers $headers `
        -Body $jsonParseContent
    ##create recs index
    Invoke-WebRequest `
        -Method 'PUT' `
        -Uri "$uri/indexes/$($jsonRecsName)?api-version=$apiversion" `
        -Headers  $headers `
        -Body $jsonRecsContent

    # https://learn.microsoft.com/rest/api/searchservice/create-data-source
    Invoke-WebRequest `
            -Method 'PUT' `
            -Uri "$uri/datasources/$($dataSourceDefinitionParse['name'])?api-version=$apiversion" `
            -Headers $headers `
            -Body (ConvertTo-Json $dataSourceDefinitionParse)
        
    Invoke-WebRequest `
            -Method 'PUT' `
            -Uri "$uri/datasources/$($dataSourceDefinitionRec['name'])?api-version=$apiversion" `
            -Headers $headers `
            -Body (ConvertTo-Json $dataSourceDefinitionRec)

    # https://learn.microsoft.com/rest/api/searchservice/create-indexer
    Invoke-WebRequest `
            -Method 'PUT' `
            -Uri "$uri/indexers/$($jsonRecIndexerName)?api-version=$apiversion" `
            -Headers $headers `
            -Body $jsonRecIndexerContent

    Invoke-WebRequest `
            -Method 'PUT' `
            -Uri "$uri/indexers/$($jsonParseIndexerName)?api-version=$apiversion" `
            -Headers $headers `
            -Body $jsonParseIndexerContent
    }
 catch {
    Write-Error $_.ErrorDetails.Message
    throw
}

