# Naming conventions for Azure Resources

It is critical to have a naming convention in place for your resources. A naming convention gives you the predictable names of resources from one environment to another. This allows for a dramatic reduction in the volume of parameter file management required to achieve the level of resource duplication required to achieve many enterprise level solutions. The naming convention that is in place for the resources created for these samples is comprised of several parts as defined below.

## Group Id

Represents an identifier for the functional grouping of resources. This is a higher level of grouping as we will have multiple resource groups defined for a given business solution.

## Environment

A letter to delineate the environment the resource was for e.g.

| Environment | Letter |
| ----------- | ------ |
| Development | d |
| Test | t |
| Integration | i |
| Production | p |
 
## Resource Type

The resource type is an abbrev for the type of resource being created. e.g.

| Resource type | abbrev |
| ------------- | ------ |
| Storage Account | sa |
| Storage Account v2 | sa2 |
| Function Application | fa |
| logic app | la |
| Integration Account | iact |
| Service Bus | sb |
| Network Security Group | nsg |
| Resource Group | rgp |
| Event hub | eh |
| Event Grid Subscription | egs |
| Log Analytics Workspace | law | 
| Log analytics solution | las |

## Region 

The region the resource is deployed as evaluated by viewing the resources .location property. E.g. West US = westus Central US = centralus. This can be replaced with an abbreviated location named defined. This is especially helpful for regions that have really long names like northcentralus.

## Additional identifying info
 
Since you might have more than a single storage account or function app, logic app within a resource group an abbrev might be required to help distinguish it’s purpose. If the resource allows for it, adding a hyphen or underscore may be appropriate for this additional information. 

## Naming convention applied

The format for applying this naming convention would look like so:

{GroupID}{Environment}{Resource Type}{Region}-{Optional Purpose}

Some examples:

| Group Id | Environment | Resource Type | Region | Optional Info | Resource Name |
| --- | --- | --- | --- | --- | --- |
| cse01 | Development | Storage Account V2 | West US | ingest | cse01dsa2westusingest |
| cse01 | Test | Logic App | Central US | sample-sb-conn | cse01tlacentralus-sample-sb-conn |
| cse01 | Development | Resource Group | Central US | Shared Resources | cse01drgpentralus-shared |