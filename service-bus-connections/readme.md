---
page_type: sample
languages:
  - azurepowershell
products:
  - azure
  - azure-logic-apps
  - azure-resource-manager
  - azure-service-bus
---


# Connecting to Service Bus queues from Microsoft Azure Logic Apps

This sample is used to illustrate creating API Connections for a Service Bus to be used by a logic app that will use one service bus connection to read messages while using another service bus connection to send messages.

Review the [Sample File Definition](../file-definitions.md) documentation for a understanding of how these scripts function. 

This particular sample will use the output variables from the connectors-template.json

``` json
"outputs": {
    "serviceBusManagedApiId": {
      "type": "string",
      "value": "[variables('serviceBusConnectionId')]"
    },
    "serviceBusConnId1": {
      "type": "string",
      "value": "[resourceId('Microsoft.Web/connections', concat(variables('serviceBusConnectionName'), '-1'))]"
    },
    "serviceBusConnId2": {
      "type": "string",
      "value": "[resourceId('Microsoft.Web/connections', concat(variables('serviceBusConnectionName'), '-2'))]"
    },
    "logicAppName": {
      "type": "string",
      "value": "[variables('logicAppName')]"
    }
  }
```

To replace the {serviceBussConnId1},{serviceBussConnId2} and {serviceBusManagedApiId} values in the logic-app-definition-parameters.json and use the resulting value to update the logic app's definition.

``` json
{
    "$connections": {
        "value": {
            "servicebus-1": {
                "connectionId": "{serviceBusConnId1}",
                "connectionName": "servicebus-1",
                "id": "{serviceBusManagedApiId}"
            },
            "servicebus-2": {
                "connectionId": "{serviceBusConnId2}",
                "connectionName": "servicebus-2",
                "id": "{serviceBusManagedApiId}"
            }
        }
    }
}
```

## Prerequisites

- Install [Azure PowerShell 2.4.0](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-2.4.0) on your platform

## Setup

The sample provides options for either running directly from a command line or configuring an Azure DevOps pipeline.

### Command line

To run this sample from the command line, follow these steps.

1. Clone or download this sample repository
2. Sign in to Azure from you're command line tool of choice
   
``` powershell
Connect-AzAccount
```

3. Select the appropriate [Azure context](https://docs.microsoft.com/en-us/powershell/module/az.accounts/Select-AzContext?view=azps-2.4.0) to target the deployment for

4. Run the following command from the context of the powershell directory of the sample to execute a full deployment to Azure

``` powershell
./full-deploy.ps1 -groupId <groupId> -environment <environment> -location <region name>
```

### Azure DevOps

This sample uses the [Multi-stage YAML pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml). To setup the sample pipeline follow these steps.

1. Ensure the Multi-stage pipeline [preview feature](https://docs.microsoft.com/en-us/azure/devops/project/navigation/preview-features?view=azure-devops) is enabled. 
2. Clone or fork the samples repository into your own repository
3. Either:
   - Create an [Azure Resource Manager service connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#sep-azure-rm) named "Azure Samples Subscription" within your project that points to the Azure Subscription you wish to deploy to

   or

   - Edit all instances of `azureSubscription: 'Azure Samples Subscription'` within the ./powershell/azure-pipelines.yml file with the name of an existing Azure Resource Manager service connection within your project

> [!NOTE]
> The Azure Resource Manager service connection needs to either have the "Allow all pipelines to use this connection" checkbox checked, or you will need to authorize the pipeline you create in the next step to use the service connection.

4. Update the following ./pipeline/azure-pipelines.yml variables
   - groupId: with a value unique to you and/or your organization. All resources and resource groups created will start with this value
   - location: with the name of the region you would like to deploy the resources to
   - abbrevLocationName: with a shortened version of the location name that will used as part of the resource names
5. Create a new pipeline within your project that uses the ./powershell/azure-pipelines.yml from this sample
   
![Animated walk through of creating a new pipeline](../images/create-pipeline.gif)

## Supporting documentation

The following documentation has been provided to help assist in understanding the different pieces of this sample.

- [Concepts](../concepts-review.md): This will cover several of the defining concepts of this sample
- [Naming Conventions](../naming-convention.md): This will cover the naming conventions applied to the resources created as part of the sample. 
- [Sample File Definition](../file-definitions.md): This will describe the purpose of the different files within the sample.
- [Scaling](../api-connection-scale.md): This will cover the reason behind the instanceCount variable and why this sample has the ability to increase the number of copies of the logic apps that are deployed.

## Resources

This sample will create the following resources.

![Image depicting the resources deployed by this sample](../images/servicebus-sample.png)

### Shared-template

The shared template will create a single service bus resource with 2 queue's configured queue_1 and queue_2.

### Connectors-template

This template will create two Service Bus API Connections. Both configured with the connection strings to the service bus created by the shared_template

### Logic-app-template

This will create a shell of the logic app. The definition is blank to allow for the separation of the resource template from the definition.

### Logic-app-definition

This has a very simple logic app definition that will pull a message from queue_1, using one of the API Connections and send the message to queue_2 using the other API connection. The logic-app-definition-parameters.json file contains configuration for the connectors.

## Clean up

To remove the resource groups created by the sample, run the following command from the context of the powershell directory of the sample.

``` powershell
./clean-up.ps1 -groupId <groupId>
```

This will delete all resource groups that have a name that starts with the groupId provided. 