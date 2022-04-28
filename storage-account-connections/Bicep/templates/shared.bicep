@description('The prefix for the storage account name')
param storageAccountNamePrefix string

@allowed([
  'd' //dev
  't' //test
  's' //staging
  'p' //production
])
@description('The alphabetical character that identifies the deployment environment to use in the name for each created resource. For example, values include \'d\' for development, \'t\' for test, \'s\' for staging, and \'p\' for production.')
@maxLength(1)
param environment string = 'd'

@description('The location of the deployment')
param location string = resourceGroup().location

@description('The array of blob containers to create')
param containers array = [
  'samplecontainer1'
  'samplecontainer2'
]
@description('The array of storage queues to create')
param queues array = [
  'samplequeue1'
  'samplequeue2'
]
@description('The array of storage tables to create')
param tables array = [
  'sampletable1'
  'sampletable2'
]
@description('The array of file shares to create')
param fileShares array = [
  'sampleshare1'
  'sampleshare2'
]

var locationAbbr = {
  uksouth: 'uks'
  ukwest: 'ukw'
  northeurope: 'neu'
  westeurope: 'weu'
  westus: 'wus'
  eastus: 'eus'
  //Add other location abbreviations as required.
}
var baseName = '${storageAccountNamePrefix}${environment}'
var storageAccountName = toLower('${baseName}${locationAbbr[location]}sa')

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  location: location
  properties: {
    accessTier: 'Hot'
  }
}

resource storageContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-04-01' = [for item in containers: {
  name: '${storageAccount.name}/default/${toLower(item)}'
}]

resource storageQueues 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-08-01' = [for item in queues: {
  name: '${storageAccount.name}/default/${toLower(item)}'
}]

resource storageTables 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-08-01' = [for item in tables: {
  name: '${storageAccount.name}/default/${toLower(item)}'
}]

resource storageFileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = [for item in fileShares: {
  name: '${storageAccount.name}/default/${toLower(item)}'
}]

@description('The name of the storage account')
output storageAccountName string = storageAccountName
@description('The Resource ID of the storage account')
output storageAccountId string = storageAccount.id
