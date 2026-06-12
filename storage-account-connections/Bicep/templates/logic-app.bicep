@description('The prefix for the name of the Logic App.')
param workflowNamePrefix string

@description('The location of the deployment')
param location string = resourceGroup().location

@allowed([
  'd' //dev
  't' //test
  's' //staging
  'p' //production
])
@description('The alphabetical character that identifies the deployment environment to use in the name for each created resource. For example, values include \'d\' for development, \'t\' for test, \'s\' for staging, and \'p\' for production.')
@maxLength(1)
param environment string

@description('The API type identifier for the table connection')
param tablesManagedApiId string
@description('The Resource ID of the Table connection')
param tablesConnId string

@description('The API type identifier for the files connection')
param fileManagedApiId string
@description('The Resource ID of the Files connection')
param fileConnId string

@description('The API type identifier for the blob connection')
param blobManagedApiId string
@description('The Resource ID of the Blob connection')
param blobConnId string

@description('The API type identifier for the Queue connection')
param queuesManagedApiId string
@description('The Resource ID of the Queues connection')
param queuesConnId string

var logicAppName = '${workflowNamePrefix}-${environment}-${locationAbbr[location]}-la'

var locationAbbr = {
    uksouth: 'uks'
    ukwest: 'ukw'
    northeurope: 'neu'
    westeurope: 'weu'
    westus: 'wus'
    eastus: 'eus'
    //Add other location abbreviations as required.
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  location: location
  name: logicAppName
  properties: {
    definition: json(loadTextContent('workflow.json'))
    parameters: {
      '$connections': {
        value: {
          azuretables: {
            connectionId: tablesConnId
            connectionName: 'azuretables'
            id: tablesManagedApiId
          }
          azureblob: {
            connectionId: blobConnId
            connectionName: 'azureblob'
            id: blobManagedApiId
          }
          azurefile: {
            connectionId: fileConnId
            connectionName: 'azurefile'
            id: fileManagedApiId
          }
          azurequeues: {
            connectionId: queuesConnId
            connectionName: 'azurequeues'
            id: queuesManagedApiId
          }
        }
      }
    }
  }
}

@description('The name of the Logic App.')
output logicAppName string = logicApp.name
