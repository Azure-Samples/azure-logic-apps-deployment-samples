<#
 .SYNOPSIS
    Deploys a logic app template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template with the LogicApp definition seperated within the directory

    .PARAMETER groupId
        The value used to construct resources within the resource group. Should identify the group of resources that are used together for the given solution

    .PARAMETER location
        Region used for the resource group and the region for resources contained within it

    .PARAMETER environment
        The environment letter provided will be used within every resource created within the resource group. Example values include d = development; t = test; s = staging; p = production

    .PARAMETER abbrevLocationName
        An abbreviated version of the region name. Used within the resource names and should be used to compress the names to account for the character limitations placed on some resource types. Defaults to the location")]

    .PARAMETER deploymentName
        Name given to the deployment. If not provided a GUID is assigned to the deployment

    .PARAMETER instanceCount
        The number of instances of the resource group to create

    .PARAMETER overrideExistingLogicApp
        Tells the script to execute the ARM template deployment for the logic app even when the logic app already exists
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

$result = & "${PSScriptRoot}\shared-deploy.ps1" -groupId $groupId `
    -location $location `
    -environment $environment `
    -abbrevLocationName $abbrevLocationName `
    -deploymentName $deploymentName;

Write-Host "Deploying Function App"

Push-Location "${$PSScriptRoot}../sample-function"

$deployCommand = "func azure functionapp publish {0}" -f $result.Outputs.functionAppName.Value

Invoke-Expression $deployCommand

Pop-Location

Write-Host "Running logic app deployment script"

& "${PSScriptRoot}\logic-app-deploy.ps1" -groupId $groupId `
    -location $location `
    -environment $environment `
    -abbrevLocationName $abbrevLocationName `
    -deploymentName $deploymentName `
    -identifier "sample-function-app" `
    -instanceCount $instanceCount `
    -overrideExisting $overrideExistingLogicApp;