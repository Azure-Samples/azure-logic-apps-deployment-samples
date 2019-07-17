<#
 .SYNOPSIS
    Deploys a template for a logic app to Azure.

 .DESCRIPTION
    Deploys an Azure Resource Manager template with the LogicApp definition seperated within the directory

    .PARAMETER groupId
        The value used for constructing resources in the resource group and identifies the resources that are used together in a specific solution

    .PARAMETER location
        The region or location name to use for the resource group and the resources in that group

    .PARAMETER environment
        The alphabetical character that identifies the deployment environment to use in the name for each resource that's created in the resource group. For example, values include "d" for development, "t" for test, "s" for staging, and "p" for production.

    .PARAMETER abbrevLocationName
        The abbreviated region name that's used in resource names due to character limitations on some resource types. Defaults to the "location" parameter value.

    .PARAMETER deploymentName
        The name used for the deployment. If not given, a GUID is assigned as the deployment name.

    .PARAMETER instanceCount
        The number of resource group instances to create

    .PARAMETER overrideExistingLogicApp
        If true, the script runs the Azure Resource Manager template deployment for the logic app, even when the logic app already exists.
#>

param(

 [Parameter(Mandatory=$True)]
 [string]
 $groupId,

 [Parameter(Mandatory=$True)]
 [string]
 $location,

 [Parameter(Mandatory=$True)]
 [string]
 $environment,

 [Parameter(Mandatory=$False)]
 [string]
 $abbrevLocationName = $location,

 [Parameter(Mandatory=$False)]
 [string]
 $deploymentName = [guid]::NewGuid(),

 [Parameter(Mandatory=$False)]
 [int]
 $instanceCount = 1,

 [Parameter(Mandatory = $False)]
 [bool]
 $overrideExistingLogicApp = $True
)

Write-Host "Running shared deployment script"

& "${PSScriptRoot}\shared-deploy.ps1" -groupId $groupId `
    -location $location `
    -environment $environment `
    -abbrevLocationName $abbrevLocationName `
    -deploymentName $deploymentName;

Write-Host "Running logic app deployment script"

& "${PSScriptRoot}\logic-app-deploy.ps1" -groupId $groupId `
    -location $location `
    -environment $environment `
    -abbrevLocationName $abbrevLocationName `
    -deploymentName $deploymentName `
    -identifier "sample-sb-conn" `
    -instanceCount $instanceCount `
    -overrideExisting $overrideExistingLogicApp;