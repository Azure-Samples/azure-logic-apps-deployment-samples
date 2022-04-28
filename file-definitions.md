# Samples file structure and definitions

All the samples that create a continuous integration (CI) and continuous delivery (CD) pipeline for Azure Logic Apps follow a similar file structure. Although some minor differences exist, each sample contains the files described in this topic.

## ARM Templates Based Deployments

### PowerShell scripts

The scripts in each sample follow the workflow that's described by this diagram:

![Script flow](./images/script-flow.png)

| Script file name | Description |
|------------------|-------------|
| `full-deploy.ps1` | Runs both the `logic-app-deploy.ps1` and `shared-deploy.ps1` scripts for a sample. <p>This script is provided for convenience during deployment and isn't meant for use in a CI/CD pipeline. However, the deployments for the shared resources and logic app resource happen inside different CI/CD pipelines. |
| `logic-app-deploy.ps1` | Brings all the logic app pieces together and performs these actions: <p>1. Deploy the templates for the API connectors. <p>2. Take the output from the connectors deployment and inject the values into both the logic app definition template and logic app definition's parameters file. <p>3. Deploy the number of logic app instances that's defined by the input parameters. <p>The parameters that pass into this script are also used for naming your logic app resources, based on the [naming convention](./naming-convention.md) used by these samples. |
| `shared-deploy.ps1` | Deploys the `shared-template.json` template and is a variation on the standard PowerShell script that you get when you export from an Azure resource. <p>This script differs by using the parameters that pass into the script's execution to construct the parameters that pass into resource deployment. These parameters are used to implement the [naming convention](./naming-convention.md) used throughout these samples. |
| `clean-up.ps1` | Removes all the resources that are deployed by a sample. Examines your subscription, finds all the resource groups that start with the group ID that's passed in, and deletes those groups. <p>**Caution**: Proceed carefully when you run this script. |
|||

### Templates

| Template file name | Description |
|--------------------|-------------|
| `connectors-template.json` | This Azure Resource Manager template sets up the resources that deploy to the same resource group as the logic app. <p>Generally, these resources include the API connections used by the logic app. This template must provide the outputs that get injected into the `logic-app-definition.json` file and `logic-app-definition-parameters.json` file. |
| `connectors-parameters.json` (optional) | This file contains parameters that deploy with the `connectors-template.json` file. <p>- If this file is provided, the parameters that pass in during script execution get appended to the parameters defined in this file. <p>- If this file isn't provided, the parameters that pass in during script execution get passed along as a hash table to the connectors template during deployment. |
| `logic-app-definition.json` | This file contains your logic app's workflow definition, or "code". The separation between the logic app's definition file and the Resource Manager template used for deployment is critical to supporting multiple environments. <p>These samples are designed to use the [Visual Studio Code extension for Azure Logic Apps](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-logicapps) so that you can download the logic app's current workflow definition, add that definition to source control, and set up a CI/CD pipeline that deploys to multiple environments. |
| `logic-app-definition-parameters.json` | This file contains parameters that deploy with the `logic-app-definition.json` file. <p>**Important**: Make sure that the parameters that are defined in this file are also defined in the `logic-app-definition.json` file. <p>The `logic-app-deploy.ps1` script replaces tokens in both the `logic-app-definition.json` file and the `logic-app-definition-parameters.json` file. The replaced tokens are defined by the output from the `connectors-template.json` file. |
| `logic-app-template.json` | This Azure Resource Manager template sets up the logic app but is mostly generic without much content. <p>**Note**: Some samples require that the template run one time to succeed. In other words, this template only deploys the first time when the logic app deploys to an environment. When this requirement exists, the `overrideExisting` parameters in the `logic-app-deploy.ps1` script must be set to `false`. |
| `logic-app-template-parameters.json` (optional) | This file contains parameters that deploy with the `logic-app-template.json` file. <p>- If this file is provided, the parameters that pass in during script execution get appended to the parameters defined in this file. <p>- If this file isn't provided, the parameters that pass in during script execution get passed along as a hash table to the logic app template during deployment. |
| `shared-template.json` | This Azure Resource Manager template sets up the shared resources used by the logic app and deploys those resources to a separate resource group for these reasons: <p>- **Separate concerns**: These resources, such as databases, storage accounts, and event hubs, are most likely used by resources other than just the logic app. <p>- **Scaling**: These samples provide the capability to scale the logic app's implementations, or more specifically, the API connection implementations. The shared resources in this resource group don't require the scaling capability that other resources require. For more information, see the [Scaling](./api-connection-scale.md) topic. <p>- **Lifecycle management**: The lifespan for the shared resources in this resource group likely differ from the logic app. For example, future demands might require that you replace the logic app with an alternative solution. Separate resource groups gives you the flexibility to replace logic apps without having to cherry pick resources from a single resource group that stores all the resources together. <p>- **Rate of change**: Usually, the rate of change in shared resources templates is much lower than the rate of change in logic apps. |
| `shared-template-parameters.json` (optional) | This file contains the parameters that deploy with the `shared-template.json` file. <p>- If this file is provided, the parameters that pass in during script execution get appended to the parameters defined in this file. <p>- If this file isn't provided, the parameters that pass in during script execution get passed along as a hash table to the shared resources template during deployment. |
|||

## Bicep Based Deployments

TODO

### Templates

### Azure Pipelines
