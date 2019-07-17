<#
    .SYNOPSIS
    Deploys the shared 

    .DESCRIPTION
    Deploys an Azure Resource Manager template with the LogicApp definition seperated within the directory

    .PARAMETER groupId
        The value used to construct resources within the resource group. Should identify the group of resources that are used together for the given solution

    .PARAMETER location
        Region used for the resource group and the region for resources contained within it

    .PARAMETER environment
        The environment letter provided will be used within every resource created within the resource group. Example values include d = development; t = test; s = staging; p = production

    .PARAMETER abbrevLocationName
        OPTIONAL: An abbreviated version of the region name. Used within the resource names and should be used to compress the names to account for the character limitations placed on some resource types. Defaults to the location")]

    .PARAMETER deploymentName
        OPTIONAL: Name given to the deployment. If not provided a GUID is assigned to the deployment

    .PARAMETER identifier
        OPTIONAL: Value appended to the end of the resource group and the logic app within the resource group

    .PARAMETER parametersFilePath
        OPTIONAL: Path to the parameter file. Defaults to the file contained within the local directory

    .PARAMETER templateFilePath
        OPTIONAL: Path to the template file. Defaults to the file contained within the local directory
#>

param(
    [Parameter(Mandatory = $True)]
    [string]
    $groupId,

    [Parameter(Mandatory = $True)]
    [string]
    $location,

    [Parameter(Mandatory = $True)]
    [string]
    $environment,

    [Parameter(Mandatory = $False)]
    [string]
    $abbrevLocationName = $location,

    [Parameter(Mandatory = $False)]
    [string]
    $deploymentName = [guid]::NewGuid(),

    [Parameter(Mandatory = $False)]
    [string]
    $identifier = "shared",

    [Parameter(Mandatory = $False)]
    [string]
    $parametersFilePath = "../templates/shared-parameters.json",

    [Parameter(Mandatory = $False)]
    [string]
    $templateFilePath = "../templates/shared-template.json"
)

Function RegisterRP {
    <#
        .SYNOPSIS
            Registers the azure resource provider
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The name of the resource provider to register")]
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

Function Set-RelativeFilePaths {
    <#
        .SYNOPSIS
            Fixes relative paths that cannot be evaluated as is
        .DESCRIPTION
            Validates that the file paths can be evaluated as passed in. 
            In the event the paths are relitive and can't be found, 
            will attempt to fix by prepending the scripts execution root path to the path given
    #>
    Param()
    $parametersFilePath = Set-RelativeFilePath -filePath $parametersFilePath
    $templateFilePath = Set-RelativeFilePath -filePath $templateFilePath
}

Function Set-RelativeFilePath {
    <#
        .SYNOPSIS
            Validate an individual file path and prepends script execution root path when the path fails
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The path of the file to test to see if it exists.")]
        [string]$filePath
    )

    if (Test-Path $filePath) {
        return $filePath;
    }
    else {
        return "{0}\{1}" -f $PSScriptRoot, $filePath;
    }
}

Function Set-ResourceGroup {
    <#
        .SYNOPSIS
            Checks if the resource group exists, if not will create the resource group
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The name of the resource group to create if it doesn't exist")]
        [string]$resourceGroupName
    )
    
    Write-Host "Working with Resource group name '$resourceGroupName'"

    Write-Host "Checking if resource group exists"
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (!$resourceGroup) {
        Write-Host "Resource group '$resourceGroupName' does not exist. Creating new resource group";
        
        Write-Host "Creating resource group '$resourceGroupName' in location '$location'";
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
    else {
        Write-Host "Using existing resource group '$resourceGroupName'";
    }
}

Function New-ArmTemplateDeployment {
    <#
        .SYNOPSIS
            Create a new ARM template deployment 
        .OUTPUTS
            The results of the ARM template deployment
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The path to the parameter file to use for the deployment")]
        [string]$parametersFilePath,
        [Parameter(Mandatory = $True, HelpMessage = "The name of the resource group to deploy to")]
        [string]$resourceGroupName,
        [Parameter(Mandatory = $True, HelpMessage = "The path to the template file to use for the deployment")]
        [string]$templateFilePath,
        [Parameter(Mandatory = $True, HelpMessage = "Values to append to the parameters prior to deployment")]
        [hashtable]$armParameters
    )
    if (Test-Path $parametersFilePath) {
        Write-Host "Loading parameters from file";
        $parametersFromFile = Get-Content -Raw -Encoding UTF8 -Path $parametersFilePath | ConvertFrom-Json
        
        Write-Host "Adding script parameters";
        New-Parameter -parameters $parametersFromFile -name "groupId" -value $groupId
        New-Parameter -parameters $parametersFromFile -name "environment" -value $environment
        New-Parameter -parameters $parametersFromFile -name "locationName" -value $locationName

        Write-Host "Starting deployment...";
        return New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterObject $parametersFromFile;
    }
    else {
        Write-Host "Starting deployment...";
        return New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterObject $armParameters;
    }
}

Function New-Parameter {
    <#
        .SYNOPSIS
            Appends a parameter to the hashtable of parameters passed in
    #>
    Param (
        [Parameter(Mandatory = $True, HelpMessage = "Hashtable to add the parameter to")]
        [hashtable]$parameters,
        [Parameter(Mandatory = $True, HelpMessage = "Name of the parameter to add")]
        [string]$name,
        [Parameter(Mandatory = $True, HelpMessage = "Value of the parameter to add")]
        [string]$value
    )
    $parameters | Add-Member -MemberType NoteProperty -Name $name -Value @{value = $value }
}

Function Set-AzureStorageTable {
    <#
        .SYNOPSIS
            Create the table defined if it does not already exist
    #>
    Param (
        [Parameter(Mandatory = $True, HelpMessage = "Context for the storage account to create in")]
        [object]$Context,
        [Parameter(Mandatory = $True, HelpMessage = "Name of the table to create")]
        [string]$Name
    )

    Write-Host "Checking if storage table $Name exists"
    $existing = Get-AzureStorageTable -Name $name -Context $Context -ErrorAction SilentlyContinue
    if (!$existing) {
        Write-Host "Storage table $Name does not exist, creating"
        New-AzureStorageTable -Name $name -Context $Context
    }
    else {
        Write-Host "Storage table $Name exists"
    }
}

Function Set-AzureStorageQueue {
    <#
        .SYNOPSIS
            Create the queue defined if it does not already exist
    #>
    Param (
        [Parameter(Mandatory = $True, HelpMessage = "Context for the storage account to create in")]
        [object]$Context,
        [Parameter(Mandatory = $True, HelpMessage = "Name of the queue to create")]
        [string]$Name
    )

    Write-Host "Checking if storage queue $Name exists"
    $existing = Get-AzureStorageQueue -Name $Name.ToLower() -Context $Context -ErrorAction SilentlyContinue
    if (!$existing) {
        Write-Host "Storage queue $Name does not exist, creating"
        New-AzureStorageQueue -Name $Name.ToLower() -Context $Context
    }
    else {
        Write-Host "Storage queue $Name exists"
    }
}

Function Set-AzureStorageShare {
    <#
        .SYNOPSIS
            Create the file share directory defined if it does not already exist
    #>
    Param (
        [Parameter(Mandatory = $True, HelpMessage = "Context for the storage account to create in")]
        [object]$Context,
        [Parameter(Mandatory = $True, HelpMessage = "Name of the file share to create")]
        [string]$Name
    )

    Write-Host "Checking if storage share $Name exists"
    $existing = Get-AzureStorageShare -Name $Name.ToLower() -Context $Context -ErrorAction SilentlyContinue
    if (!$existing) {
        Write-Host "Storage share $Name does not exist, creating"
        New-AzureStorageShare -Name $Name.ToLower() -Context $Context
    }
    else {
        Write-Host "Storage share $Name exists"
    }
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

if (!$PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

Set-RelativeFilePaths

$resourceProviders = @("Microsoft.Storage");
if ($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach ($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

$resourceGroupName = "{0}{1}rgp{2}-{3}" -f $groupId, $environment, $location, $identifier

Set-ResourceGroup -resourceGroupName $resourceGroupName

$armParameters = @{
    groupId      = $groupId
    environment  = $environment
    locationName = $abbrevLocationName
};

$output = New-ArmTemplateDeployment -parametersFilePath $parametersFilePath `
    -resourceGroupName $resourceGroupName `
    -templateFilePath $templateFilePath `
    -armParameters $armParameters

$storageAccountContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $output.Outputs.storageAccountName.Value).Context

Set-AzureStorageQueue -Name sampleQueue1 -Context $storageAccountContext
Set-AzureStorageQueue -Name sampleQueue2 -Context $storageAccountContext

Set-AzureStorageTable -Name sampleTable1 -Context $storageAccountContext
Set-AzureStorageTable -Name sampleTable2 -Context $storageAccountContext

Set-AzureStorageShare -Name sampleShare1 -Context $storageAccountContext
Set-AzureStorageShare -Name sampleShare2 -Context $storageAccountContext
