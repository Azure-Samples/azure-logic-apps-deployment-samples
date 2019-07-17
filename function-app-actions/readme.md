---
page_type: sample
languages:
  - azurepowershell
products:
  - azure
  - azure-functions
  - azure-logic-apps
  - azure-resource-manager
---

# Function App action within a Microsoft Azure Logic App

This sample illustrates configuring a Function App action within a Logic app deployment. Why is this tricky?

A function app action wants the resource ID of the function app. A resource ID has the structure of...

```
/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{functionAppName}/functions/{nameOfFunction}
```

You can use an Azure Resource Manager function to get the resource ID of the function app like [this](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-create-deploy-template#reference-dependent-resources) documentation suggests. However, this technique requires the definition to be a part of the template. It's the deployment of the template itself that allows the function to evaluate and replace the value in the definition. That means every time the definition is updated, the developer not only needs to incorporate the deployment with the template, they also need to modify the definition outside of the designer to accomplish it. 

We want to minimize any manual intervention between export of definition from Azure to committing to source code repository. One way we could do that would be to pass the subscriptionId, resourceGroupName, and functionAppName as parameters by taking the output from the connectors-template.json...

``` json
"outputs": {
    "functionAppName": {
      "type": "string",
      "value": "[variables('functionAppName')]"
    },
    "functionAppResourceGroup": {
      "type": "string",
      "value": "[variables('sharedResourceGroupName')]"
    },
    "subscriptionId": {
      "type": "string",
      "value": "[subscription().subscriptionId]"
    },
    "logicAppName": {
      "type": "string",
      "value": "[variables('logicAppName')]"
    }
  }
```

And defining the logic-app-definition-parameters.json like so.

```json
{
    "$armValues": {
        "value": {
            "functionAppName": "{functionAppName}",
            "functionAppResourceGroup": "{functionAppResourceGroup}",
            "subscriptionId": "{subscriptionId}"
        }
    }
}
```

With those in place we should be able to define our ID like so:

```
"id": "/subscriptions/@parameters('$armValues')['subscriptionId']/resourceGroups/@parameters('$armValues')['functionAppResourceGroup']/providers/Microsoft.Web/sites/@parameters('$armValues')['functionAppName']/functions/AwesomeFunction"
```

Unfortunately, this won't work. Why? One of the great things about that function app action is that it makes the management and passing around of the function keys not required. When we update the definition with the ID to the function, the action goes out to that function app to list the keys. When it does that, it doesn't wait until after the parameters are evaluated. It uses the raw value passed in so we get an error like this...

```
Set-AzResource : LinkedAuthorizationFailed : The client has permission to perform action 'Microsoft.Web/sites/functions/listSecrets/action' on 
scope '/subscriptions/**********/resourceGroups/**********/providers/Microsoft.Logic/workflows/********', however the linked subscription '@parameters('$armValues')['subscriptionId']' was not found. 
At C:\source\arming-logic-apps\FunctionAppActions\powershell\logic-app-deploy.ps1:435 char:25
+     $logicAppResource | Set-AzResource -Force;
+                         ~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [Set-AzResource], ErrorResponseMessageException
    + FullyQualifiedErrorId : LinkedAuthorizationFailed,Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.SetAzureResourceCmdlet
```

Notice the "however the linked subscription '@parameters('$armValues')['subscriptionId']' was not found."

In order to get the definition deployed, that value already needs to be set to the resource ID of the function app. So we can't get away from a manual update of the definition to make it dynamic from one environment to another. 

We can at least keep the template and definition separate though. To do that we just need to change how we're injecting those values by changing that "id" value to this...

```
"id": "/subscriptions/{subscriptionId}/resourceGroups/{functionAppResourceGroup}/providers/Microsoft.Web/sites/{functionAppName}/functions/AwesomeFunction"
```

This will allow our scripts to do a token replacement and inject the values in before pushing to Azure.

## Prerequisites

- Install [Azure PowerShell 2.4.0](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-2.4.0) on your platform
- Install [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#v2) on your platform

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

- [Concepts](../concept-review.md): This will cover several of the defining concepts of this sample
- [Naming Conventions](../naming-convention.md): This will cover the naming conventions applied to the resources created as part of the sample. 
- [Sample File Definition](../file-definitions.md): This will describe the purpose of the different files within the sample.
- [Scaling](../api-connection-scale.md): This will cover the reason behind the instanceCount variable and why this sample has the ability to increase the number of copies of the logic apps that are deployed.

## Resources

This sample will create the following resources.

![Image depicting the resources deployed by this sample](../images/function-app-sample.png)

Review the [Sample File Definition](../file-definitions.md) documentation for an understanding of how these scripts function. 

This samples contents have the following specifics implemented...

### shared-template.json

The shared content will deploy the function application and all of it's dependent resources. The full-deploy.ps1 also has bits to publish the source from the ./sample=function. Running that script will require the azure function CLI installed on the machine. Keep in mind that full-deploy.ps1 is provided for local execution from a developer machine. the vision for that deployment would that the function apps code would be within it's own CI/CD pipeline.

### connectors-template.json

This template will actually not deploy anything. It will however provide the parameters that will be injected into the definition. We use this approach to maintain consistency with the method for injecting parameters into a Logic app with the other samples.

### logic-app-template.json

This will create a shell of logic app. The definition is blank to allow for the separation of resource template from the definition.

### logic-app-definition.json

This has a very simple definition that will use a timer as a trigger and call the AwesomeFunction provided every time the app is triggered.

## Clean up

To remove the resource groups created by the sample, run the following command from the context of the powershell directory of the sample.

``` powershell
./clean-up.ps1 -groupId <groupId>
```

This will delete all resource groups that have a name that starts with the groupId provided. 