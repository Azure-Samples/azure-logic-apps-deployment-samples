# Set up an Azure API Management action for Azure Logic Apps

**This sample is a work in progress. Work remaining:**

* Automate import of function app into API Management.
* Update logic app definition to use API Management action instead of function app action.
* Update readme.md with relevant information about the sample. Most of the content will be the same as the function app sample.

Differences are:

  * Automate the function app's import.
  * Secure the function app from traffic not routed through API Management.

## Prerequisites

* Install [Azure PowerShell 2.4.0](https://docs.microsoft.com/powershell/azure/install-az-ps?view=azps-2.4.0) on your platform.
* Install [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local#v2) on your platform.

## Description

TODO: Add content here

## Set up sample

To set up, deploy, and run this sample, you can use the command line or set up an Azure DevOps pipeline.

### Command line

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

## Created resources

This sample creates these resources:

TODO: add API management resource to the diagram

![Resources created and deployed by this sample](../images/function-app-sample.png)

To learn about the scripts in this sample and how they work, review [Samples file structure and definitions](../file-definitions.md).


TODO: Update descriptions to include the API management bits. 

This sample also implements these template and definition files:

| File name | Description |
|-----------|-------------|
| `shared-template.json` | This template deploys the Azure function app and all its dependent resources. <p>The `full-deploy.ps1` script not only creates Azure resources for the function app but can publish that app's source from `./sample=function`. You must publish the app first before the logic app definition can work. To run this script, you must have the Azure Function CLI installed on your computer. Remember that the `full-deploy.ps1` script is used for local execution from a development computer. The idea behind this deployment is that the function app's code gets its own CI/CD pipeline. |
| `connectors-template.json` | This template provides the parameters to inject into the logic app definition but doesn't actually deploy anything. This approach is consistent with the method for injecting parameters into a logic app across the other samples. |
| `logic-app-template.json` | This template creates a shell for a logic app definition, which is blank to support separating the template from the definition. |
| `logic-app-definition.json` | This file defines a basic logic app that uses a timer as a trigger and calls the provided `AwesomeFunction` each time that the logic app gets triggered. |
|||

## Clean up

When you're done with the sample, delete the resource groups that were created by the sample. To remove all the resource groups with names that start with a specific `groupId` value, run this command from the PowerShell directory that contains this sample:

```powershell
./clean-up.ps1 -groupId <groupId>
```
