@description('The prefix for the name of the application. All resource names will be based upon the prefix.')
param appNamePrefix string

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

var deploymentNameSuffix = uniqueString(deployment().name)

module sharedResources 'shared.bicep' = {
  name: 'shared-resource-deploy-${deploymentNameSuffix}'
  params: {
    storageAccountNamePrefix: appNamePrefix
    location: location
    environment: environment
  }
}

module connectors 'connectors.bicep' = {
  name: 'connectors-deploy-${deploymentNameSuffix}'
  params: {
    storageAccountId: sharedResources.outputs.storageAccountId
    storageAccountName: sharedResources.outputs.storageAccountName
    workflowNamePrefix: appNamePrefix
    location: location
    environment: environment
  }
}

module logicApp 'logic-app.bicep' = {
  name: 'logic-app-deploy-${deploymentNameSuffix}'
  params: {
    workflowNamePrefix: appNamePrefix
    environment: environment
    location: location
    tablesConnId: connectors.outputs.tablesConnId
    tablesManagedApiId: connectors.outputs.tablesManagedApiId
    blobConnId: connectors.outputs.blobConnId
    blobManagedApiId: connectors.outputs.blobManagedApiId
    queuesConnId: connectors.outputs.queuesConnId
    queuesManagedApiId: connectors.outputs.queuesManagedApiId
    fileConnId: connectors.outputs.fileConnId
    fileManagedApiId: connectors.outputs.fileManagedApiId
  }
}
