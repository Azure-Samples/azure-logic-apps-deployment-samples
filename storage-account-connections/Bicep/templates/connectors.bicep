@description('The prefix for the name of the Logic App Connections.')
param workflowNamePrefix string

@allowed([
  'd' //dev
  't' //test
  's' //staging
  'p' //production
])
@description('The alphabetical character that identifies the deployment environment to use in the name for each created resource. For example, values include \'d\' for development, \'t\' for test, \'s\' for staging, and \'p\' for production.')
@maxLength(1)
param environment string

@description('The location of the deployment')
param location string = resourceGroup().location

@description('The name of the storage account that the API Connections will use.')
param storageAccountName string

@description('The Resource ID of the storage account that the API Connections will use.')
param storageAccountId string

var locationAbbr = {
  uksouth: 'uks'
  ukwest: 'ukw'
  northeurope: 'neu'
  westeurope: 'weu'
  westus: 'wus'
  eastus: 'eus'
  //Add other location abbreviations as required.
}
var baseName = '${workflowNamePrefix}-${environment}'
var baseConnectionsId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/'
var tablesConnectionName = '${baseName}-tables-${locationAbbr[location]}'
var tablesConnectionId = '${baseConnectionsId}azuretables'
var blobConnectionName = '${baseName}-blob-${locationAbbr[location]}'
var blobConnectionId = '${baseConnectionsId}azureblob'
var fileConnectionName = '${baseName}-file-${locationAbbr[location]}'
var fileConnectionId = '${baseConnectionsId}azurefile'
var queuesConnectionName = '${baseName}-queue-${locationAbbr[location]}'
var queuesConnectionId = '${baseConnectionsId}azurequeues'

resource tablesConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: tablesConnectionName
  location: location
  properties: {
    displayName: 'TableStorageConnection'
    customParameterValues: {}
    api: {
      id: tablesConnectionId
    }
    parameterValues: {
      storageaccount: storageAccountName
      sharedkey: listKeys(storageAccountId, providers('Microsoft.Storage', 'storageAccounts').apiVersions[0]).keys[0].value
    }
  }
}

resource queuesConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: queuesConnectionName
  location: location
  properties: {
    displayName: 'QueueStorageConnection'
    customParameterValues: {}
    api: {
      id: queuesConnectionId
    }
    parameterValues: {
      storageaccount: storageAccountName
      sharedkey: listKeys(storageAccountId, providers('Microsoft.Storage', 'storageAccounts').apiVersions[0]).keys[0].value
    }
  }
}

resource blobConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: blobConnectionName
  location: location
  properties: {
    displayName: 'BlobStorageConnection'
    customParameterValues: {}
    api: {
      id: blobConnectionId
    }
    parameterValues: {
      accountName: storageAccountName
      accessKey: listKeys(storageAccountId, providers('Microsoft.Storage', 'storageAccounts').apiVersions[0]).keys[0].value
    }
  }
}

resource fileConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: fileConnectionName
  location: location
  properties: {
    displayName: 'FileStorageConnection'
    customParameterValues: {}
    api: {
      id: fileConnectionId
    }
    parameterValues: {
      accountName: storageAccountName
      accessKey: listKeys(storageAccountId, providers('Microsoft.Storage', 'storageAccounts').apiVersions[0]).keys[0].value
    }
  }
}

output tablesManagedApiId string = tablesConnectionId
output tablesConnId string = tablesConnection.id
output fileManagedApiId string = fileConnectionId
output fileConnId string = fileConnection.id
output blobManagedApiId string = blobConnectionId
output blobConnId string = blobConnection.id
output queuesManagedApiId string = queuesConnectionId
output queuesConnId string = queuesConnection.id
