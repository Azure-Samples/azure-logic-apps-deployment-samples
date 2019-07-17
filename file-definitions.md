# File Definitions

All of the samples within this repository have a similar file structure within them. There may be some minor deviations but for the most part they will contain of the following files.

## Scripts

The flow of the scripts can be visualized in this workflow diagram.

![Script flow](./images/script-flow.png)

### full-deploy.ps1

This script will kick off both the shared-deploy.ps1 and logic-app-deploy.ps1 scripts and is provided for convenience during development. 

> This will deploy all of the resources, including the shared resources in a single script execution. This will negate the value of having the shared resources defined in a separate ARM Template. In a enterprise system solution, these resources would not need to be deployed nearly as frequently as changes made to application code.

### azure-pipelines.yml

This is a pipeline definition that can be used in place of the full-deploy.ps1 to execute a full deployment of all of the resources for that sample. 

> This will deploy all of the resources, including the shared resources in a single pipeline. This will negate the value of having the shared resources defined in a separate ARM Template. In a enterprise system solution, these resources would not need to be deployed nearly as frequently as changes made to application code.

### logic-app-deploy.ps1

This script is what gets the job done. It is responsible for bringing all of the logic app pieces together. It will perform the following actions:

- Deploy the API Connectors templates
- Use the output from the API Connectors deployment to inject values into both the logic-app-definition.json and the logic-app-definition-parameters.json
- Deploy the volume of instances defined by the input parameters

The parameters passed into the script are also used to implement the [Naming conventions](./naming-convention.md) for the logic app resources.

### shared-deploy.ps1

This script is used to deploy the shared-template.json. This is a variation of the standard PowerShell script you would get from an export from the Azure Resources. The difference being that it uses the parameters passed into the script execution to construct parameters to pass into the deployment. Those specific parameters are responsible for implementing the [Naming conventions](./naming-convention.md) used throughout the samples. 

### clean-up.ps1

This script is used to remove all of the resources deployed by the sample. It will look into the subscription and find all resource groups that start with the groupId passed in and delete them. Use with caution.

## Templates

### contectors-template.json

This is the Azure Resource Manager template for configuring the resources that will reside within the same resource group as the logic app. Generally those will be the API Connections that the logic app depends on. It will need to output information that will be injected into both the logic-app-definition.json and logic-app-definition-parameters.json files.

### connectors-parameters.json (optional)

This is the parameters file that will be sent with the connectors-template.json file for deployment. If a file is provided, the parameters that are passed into the script execution will be appended to the parameters defined within this file. If this file is not found the parameters that are passed into the script execution will be passed as a hashtable to the deployment of the template.

### logic-app-definition.json

This file contains the definition (aka the code) of the logic app. The samples are designed with the goal of using the [VS Code Extension: Azure Logic Apps](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-logicapps) to download the current version of the logic app from a development environment to be checked into source code and enable a CI/CD pipeline to distribute to many environments. The seperation of the definition file from the template is critical to achieve the development workflow goal.

### logic-app-definition-parameters.json

This file contains the parameters that will be deployed with the definition file. It is important to ensure that the parameters defined here are also defined within the logic-app-definition.json file. 

> The logic-app-deploy.ps1 script will execute a token replacement on both the logic-app-definition.json file and the logic-app-definition-parameters.json files. The tokens it will replace are defined by the output from the connectors-template.json file.

### logic-app-template.json

The file contains the template for the logic app itself. For the most part they will be very generic and not have a lot of meat in them. 

> There are some samples that will require the template to only be deployed the first time the logic app is deployed to an environment. When this is required the overrideExisting parameters of the logic-app-deploy.ps1 script will need to be set to false.

### logic-app-parameters.json (optional)

This is the parameters file that will be sent with the logic-app-template.json file for deployment. If a file is provided, the parameters that are passed into the script execution will be appended to the parameters defined within this file. If this file is not found the parameters that are passed into the script execution will be passed as a hashtable to the deployment of the template.

### shared-template.json

This the template for the resources the logic app is dependent on. They are deployed to a separate resource group for several reasons.

- Separation of concerns: These resources most likely have greater needs then just logic app. e.g. Databases, Storage Accounts, Event Hubs that are used by more than just the logic app. 
- Scaling: See [Why Scale?](./api-connection-scale.md) for greater explanation. These samples have the ability to scale the  instances. More specifically the API Connections Implementations. We don't want the resources defined within this resource group to also be scaled with those resources. 
- Life cycle management: The life span of the resources within this resource group will most likely be different than the logic app. e.g. Future demands may require the replacement of the logic app with some future alternative solution. Separation of the resource groups gives the flexibility to do that replacement without having to cherry pick resources out of a single resource group
- Rate of change: It is most likely that the rate of change in these resources templates will be much slower than that of the logic app.

### shared-parameters.json (optional)

This is the parameters file that will be sent with the shared-template.json file for deployment. If a file is provided, the parameters that are passed into the script execution will be appended to the parameters defined within this file. If this file is not found the parameters that are passed into the script execution will be passed as a hashtable to the deployment of the template.
