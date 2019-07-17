<#
    .SYNOPSIS
    Deploy the shared resources.

    .DESCRIPTION
    Deploys an Azure Resource Manager template with the LogicApp definition seperated within the directory

    .PARAMETER groupId
        The value used for constructing resources in the resource group and identifies the resources that are used together in a specific solution

    .PARAMETER location
        The region or location name to use for the resource group and the resources in that group

    .PARAMETER environment
        The alphabetical character that identifies the deployment environment to use in the name for each resource that's created in the resource group. For example, values include "d" for development, "t" for test, "s" for staging, and "p" for production.

    .PARAMETER abbrevLocationName
        OPTIONAL: The abbreviated region name that's used in resource names due to character limitations on some resource types. Defaults to the "location" parameter value.

    .PARAMETER deploymentName
        OPTIONAL: The name used for the deployment. If not given, a GUID is assigned as the deployment name.

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
            Register the Azure resource provider.
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
            Fix relative paths that can't be evaluated as given.
        .DESCRIPTION
            Validate whether the file paths can be evaluated as they're passed as input.
            If the paths are relative and can't be found, try to fix by prepending the 
            root path for script execution to the given path.
    #>
    Param()
    $parametersFilePath = Set-RelativeFilePath -filePath $parametersFilePath
    $templateFilePath = Set-RelativeFilePath -filePath $templateFilePath
}

Function Set-RelativeFilePath {
    <#
        .SYNOPSIS
            Validate a single file path and prepend the root path for script execution when the path fails.
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The path of the file to test whether the file exists")]
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
            Check whether the resource group exists. If not, create the resource group.
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The name for the resource group to create, if not already existing")]
        [string]$resourceGroupName
    )
    
    Write-Host "Working with resource group name: '$resourceGroupName'"

    Write-Host "Checking whether the resource group exists"
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

Function New-ResourceManagerTemplateDeployment {
    <#
        .SYNOPSIS
            Create an Azure Resource Manager template deployment.
        .OUTPUTS
            The results from the Azure Resource Manager template deployment
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The path for the parameter file to use for deployment")]
        [string]$parametersFilePath,
        [Parameter(Mandatory = $True, HelpMessage = "The name for the resource group to use for deployment")]
        [string]$resourceGroupName,
        [Parameter(Mandatory = $True, HelpMessage = "The path to the template file to use for the deployment")]
        [string]$templateFilePath,
        [Parameter(Mandatory = $True, HelpMessage = "The values to append to the parameters before deployment")]
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
            Append a parameter to the hash table for parameters that are passed as input.
    #>
    Param (
        [Parameter(Mandatory = $True, HelpMessage = "The hash table where to add the parameter")]
        [hashtable]$parameters,
        [Parameter(Mandatory = $True, HelpMessage = "The name for the parameter to add")]
        [string]$name,
        [Parameter(Mandatory = $True, HelpMessage = "The value for the parameter to add")]
        [string]$value
    )
    $parameters | Add-Member -MemberType NoteProperty -Name $name -Value @{value = $value }
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

if (!$PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

Set-RelativeFilePaths

$resourceProviders = @("microsoft.servicebus");
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

New-ResourceManagerTemplateDeployment -parametersFilePath $parametersFilePath `
    -resourceGroupName $resourceGroupName `
    -templateFilePath $templateFilePath `
    -armParameters $armParameters
