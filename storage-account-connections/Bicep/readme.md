---
page_type: sample
languages:
  - bicep
products:
  - azure
  - logic-apps
  - azure-resource-manager
  - azure-storage
  - bicep
  - azure-pipelines
---

# Connect to Azure Storage accounts from Azure Logic Apps and deploy with Azure DevOps Pipelines

This sample shows how to create a logic app that connects to different Azure Storage containers (Blob, Table, Queue, and File) and deploy the app by using Azure DevOps Pipelines. The logic app definition isn't complex, so the goal for this sample focuses on how to create these connections for use by the logic app definition. To learn more about the template and definition files in this sample and how they work, review [Samples file structure and definitions](../../file-definitions.md).

## How this sample works

This sample uses the outputs from creating Azure Storage connections and defines these output variables in the `connectors-template.json` file:

``` json
"outputs": {
   "tablesManagedApiId": {
      "type": "string",
      "value": "[variables('tablesConnectionId')]"
   },
   "tablesConnId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Web/connections', variables('tablesConnectionName'))]"
   },
   "fileManagedApiId": {
      "type": "string",
      "value": "[variables('fileConnectionId')]"
   },
   "fileConnId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Web/connections', variables('fileConnectionName'))]"
   },
   "blobManagedApiId": {
      "type": "string",
      "value": "[variables('blobConnectionId')]"
   },
   "blobConnId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Web/connections', variables('blobConnectionName'))]"
   },
   "queuesManagedApiId": {
      "type": "string",
      "value": "[variables('queuesConnectionId')]"
   },
   "queuesConnId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Web/connections', variables('queuesConnectionName'))]"
   },
   "logicAppName": {
      "type": "string",
      "value": "[variables('logicAppName')]"
   }
}
```

The `logic-app-definition-parameters.json` file replaces the various token values and updates the logic app's definition with the resulting values:

``` json
{
   "$connections": {
      "value": {
         "azuretables": {
            "connectionId": "{tablesConnId}",
            "connectionName": "azuretables",
            "id": "{tablesManagedApiId}"
         },
         "azureblob": {
            "connectionId": "{blobConnId}",
            "connectionName": "azureblob",
            "id": "{blobManagedApiId}"
         },
         "azurefile": {
            "connectionId": "{fileConnId}",
            "connectionName": "azurefile",
            "id": "{fileManagedApiId}"
         },
         "azurequeues": {
            "connectionId": "{queuesConnId}",
            "connectionName": "azurequeues",
            "id": "{queuesManagedApiId}"
         }
      }
   }
}
```

> [!IMPORTANT]
>
> Pay specific attention to the different `parameterValues` sections in each storage connection. Some differences exist in how these managed APIs are defined, which often causes some confusion. Both the `azureblob` and `azurefile` APIs want `accountname` and `accesskey` values, while the `azurequeues` and `azuretables` APIs want `storageaccount` and `sharedkey` values.

## Prerequisites

* Install [Azure PowerShell 2.4.0](https://docs.microsoft.com/powershell/azure/install-az-ps?view=azps-2.4.0) on your platform.

## Set up sample

To set up, deploy, and run this sample, you can use the command line or set up an Azure DevOps pipeline.

### Command line

To run this sample from the command line, follow these steps.

1. Clone or download this sample repository.

1. Sign in to Azure by running this command from any command line tool that you want.

   ```powershell
   Connect-AzAccount
   ```

1. To target your deployment, select the appropriate [Azure context](https://docs.microsoft.com/powershell/module/az.accounts/Select-AzContext?view=azps-2.4.0) to use.

1. To push a full deployment for this sample to Azure, run this command from the PowerShell directory that contains this sample:

   ```powershell
   ./full-deploy.ps1 -groupId <groupId> -environment <environment> -location <regionName>
   ```

### Azure DevOps

This sample uses [multi-stage YAML pipelines](https://docs.microsoft.com/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml). To set up the sample pipeline, follow these steps:

1. Make sure that the [multi-stage pipeline preview feature](https://docs.microsoft.com/azure/devops/project/navigation/preview-features?view=azure-devops) is enabled.

1. Clone or fork the samples repository into your own repository.

1. Choose one of these steps:

   * Create an [Azure Resource Manager service connection](https://docs.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#sep-azure-rm) that has the name "Azure Samples Subscription" in your project that points to the Azure subscription that you want to use for deployment.

   * Edit all instances of `azureSubscription: 'Azure Samples Subscription'` in the `./powershell/azure-pipelines.yml` file by using the name for an existing Azure Resource Manager service connection in your project.

   > [!NOTE]
   > To use the Azure Resource Manager service connection, make sure that the connection has selected the **Allow all pipelines to use this connection** checkbox. Otherwise, you must authorize the pipeline that you create in the next step.

1. Update these `./pipeline/azure-pipelines.yml` variables:

   * `groupId`: A value that's unique to you or your organization and is used to start the names for all resources and resource groups that are created

   * `location`: The name for the Azure region where you want to deploy the resources

   * `abbrevLocationName`: The abbreviated region name that's used in resource names

1. Create a new pipeline in your project that uses the `./powershell/azure-pipelines.yml` file from this sample.

   ![Animated walkthrough for creating a new pipeline](../images/create-pipeline.gif)

## Supporting documentation

To learn more about the different parts in these samples, review these topics:

* [Concepts](../concept-review.md) introduces the main concepts that underlie these samples.

* [Naming convention](../naming-convention.md) describes the naming convention to use when creating the resources in these samples.

* [Samples file structure and definitions](../file-definitions.md) explains the purpose for each file in these samples.

* [Scaling](../api-connection-scale.md) expands on the reasons why these samples provide the capability to scale by increasing the number of copies for the logic apps deployed and organizing resources into separate resource groups.

## Resources

This sample creates these resources:

![Resources created and deployed by this sample](../images/storage-sample.png)

To learn about the scripts in this sample and how they work, review [Samples file structure and definitions](../file-definitions.md).

This sample also implements these template and definition files:

| File name | Description |
|-----------|-------------|
| `shared-template.json` | This template creates a single storage account resource that has two blob containers. The `shared-deploy.ps1` script adds two samples for each of these items: queues, file shares, and tables. |
| `connectors-template.json` | This template creates an API connection resource for Azure Tables, Files, Blobs, and Queues. |
| `logic-app-template.json` | This template creates a shell for a logic app definition, which is blank to support separating the template from the definition. |
| `logic-app-definition.json` | This file defines a basic logic app that gets a message from `samplequeue1`, creates a blob file from the message content, writes an entity into the storage table, and creates a file in the file share. |
| `logic-app-definition-parameters.json` | This file contains the setup information for the Azure Service Bus connectors. |
|||

## Clean up

When you're done with the sample, delete the resource groups that were created by the sample. To remove all the resource groups with names that start with a specific `groupId` value, run this command from the PowerShell directory that contains this sample:

```powershell
./clean-up.ps1 -groupId <groupId>
```
