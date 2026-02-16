@description('Azure region where resources should be deployed')
param location string = resourceGroup().location

@description('UTC timestamp used to create distinct deployment scripts for each deployment')
param utcValue string = utcNow()

@description('Desired name of the storage account')
param storageAccountName string = uniqueString(resourceGroup().id, deployment().name, 'blob')

@description('Name of the blob container')
param containerNameRec string = 'recs'

@description('Name of the blob container')
param containerNameParse string = 'parse'

@description('Name of the blob as it is stored in the blob container')
param filename string = 'SubmittedUserFeedback.txt'

@minLength(3)
@maxLength(24)
@description('Provide a name for the search service. Use only lower case letters and numbers. The name must be unique across Azure.')
param searchServicesName string = 'rhailsearch${uniqueString(resourceGroup().id)}'

@description('Azure OpenAI account name')
param accounts_RHAILAIDev_name string = 'RHAILModel${uniqueString(resourceGroup().id)}'

@description('Azure OpenAI deployment name (this is the model deployment, not the account name)')
param openAIDeploymentName string = 'gpt5${uniqueString(resourceGroup().id)}'

@description('Azure OpenAI deployed model name')
param openAIModelName string = 'gpt-5'

@description('Azure OpenAI deployed model version (latest listed in Foundry catalog)')
param openAIModelVersion string = '2025-08-07'

// Create storage account and containers
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'

  resource blobService 'blobServices' = {
    name: 'default'

    resource containerRecs 'containers' = {
      name: containerNameRec
    }

    resource containerParse 'containers' = {
      name: containerNameParse
    }
  }
}

resource searchServices 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchServicesName
  location: location
  tags: {
    ProjectType: 'aoai-your-data-service'
  }
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'Enabled'
    networkRuleSet: {
      ipRules: []
      bypass: 'None'
    }
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    disableLocalAuth: false
    authOptions: {
      apiKeyOnly: {}
    }
    disabledDataExfiltrationOptions: []
    semanticSearch: 'free'
  }
}

resource openAI 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' = {
  name: accounts_RHAILAIDev_name
  location: location
  tags: {
    azopenai: 'rhaildev'
  }
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: accounts_RHAILAIDev_name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

// NOTE: The 'capacity' value must align with your Azure OpenAI quota.
// Model availability varies by region and subscription access.

resource openAIDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview' = {
  parent: openAI
  name: openAIDeploymentName
  sku: {
    name: 'Standard'
    capacity: 90
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: openAIModelName
      version: openAIModelVersion
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
    raiPolicyName: 'Microsoft.Default'
  }
}

output storageAccountName string = storageAccountName
output containerNameRec string = containerNameRec
output containerNameParse string = containerNameParse
output dataSourceConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storage.listKeys().keys[0].value};'
output searchServicesName string = searchServicesName
output openAIAccountName string = accounts_RHAILAIDev_name
output openAIDeploymentName string = openAIDeploymentName
output openAIModel string = '${openAIModelName}:${openAIModelVersion}'
