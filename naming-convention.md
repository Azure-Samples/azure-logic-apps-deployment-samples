# Naming conventions for Azure resources

This topic describes the naming convention that these samples use when creating the resources in the Azure Logic Apps samples for continuous integration (CI) and continuous deployment (CD) pipelines. This convention follows this format:

`<Group ID><Environment><Resource type><Region>-<Optional info>`

Based on each identifier that's described in this topic, here are some examples:

| Group ID | Environment | Resource type | Region | Optional info | Resource name |
|----------|-------------|---------------|--------|---------------|---------------|
| cse01 | Development | Storage account V2 | West US | Ingest | cse01dsa2westusingest |
| cse01 | Test | Logic app | Central US | Sample Service Bus connection | cse01tlacentralus-sample-sb-conn |
| cse01 | Development | Resource group | Central US | Shared resources | cse01drgpentralus-shared |
|||||||

## Group ID

This label describes the higher-level functionality for a resource group because you can define multiple resource groups for a specific business solution.

## Environment

This character represents the environment where the resource is used, for example:

| Environment | Character |
|-------------|-----------|
| Development | d |
| Test | t |
| Integration | i |
| Production | p |
|||

## Resource type

These characters are an acronym for the resource type, for example:

| Resource type | Acronym |
|---------------|---------|
| Storage account | sa |
| Storage account V2 | sa2 |
| Function app | fa |
| Logic app | la |
| Integration account | iact |
| Service Bus | sb |
| Network security group | nsg |
| Resource group | rgp |
| Event hub | eh |
| Event Grid subscription | egs |
| Log Analytics workspace | law |
| Log Analytics solution | las |
|||

## Region

The region where to deploy the resource as defined by the resource definition's `.location` property. For regions with long names, such as North Central US, you can use the designated abbreviation, for example, "West US" is `westus` and "Central US" is `centralus`.

## Optional information or identification

If a solution uses more than one resource that has the same type, such as multiple storage accounts or function apps, those resources might need more information to identify its purpose. If the resource name permits, add a hyphen and a suitable label for this information.
