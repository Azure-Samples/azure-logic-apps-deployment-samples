<#
    .SYNOPSIS
        Deploys a logic app to Azure, including the connections, definition, and separate Azure Resource Manager template.

    .PARAMETER groupId
        The value used for constructing resources in the resource group and identifies the resources that are used together in a specific solution

    .PARAMETER location
        The region or location name to use for the resource group and the resources in that group

    .PARAMETER environment
        The alphabetical character that identifies the deployment environment to use in the name for each resource that's created in the resource group. For example, values include "d" for development, "t" for test, "s" for staging, and "p" for production.

    .PARAMETER identifier
        The value that's appended to the names for the resource group and logic app in that resource group. This value identifies the purpose or function for that group and logic app.

    .PARAMETER abbrevLocationName
        The abbreviated region name that's used in resource names due to character limitations on some resource types. Defaults to the "location" parameter value.

    .PARAMETER deploymentName
        The name used for the deployment. If not given, a GUID is assigned as the deployment name.

    .PARAMETER connectorsParametersFilePath
        The path to the parameters file for the connectors' Azure Resource Manager template. Defaults to the file in the local directory.
    
    .PARAMETER connectorsTemplateFilePath
        The path to the connectors' Azure Resource Manager template. Defaults to the file in the local directory.

    .PARAMETER logicAppParametersFilePath
        The path to the parameters file for the logic app's Azure Resource Manager template. Defaults to the file in the local directory.

    .PARAMETER logicAppTemplateFilePath
        The path to the logic app's Azure Resource Manager template. Defaults to the file in the local directory.

    .PARAMETER logicAppDefinitionParametersFilePath
        The path to the parameters file for the logic app's definition file. Defaults to the file in the local directory.

    .PARAMETER logicAppDefinitionPath
        Path to the logic app's definition file. Defaults to the file in the local directory.

    .PARAMETER instanceCount
        The number of resource group instances to create

    .PARAMETER overrideExisting
        If true, the script runs the Azure Resource Manager template deployment for the logic app, even when the logic app already exists.

    .EXAMPLE
        Deploys a logic app to the "westus" region by using the default values.

        ./logic-app-deploy.ps1 -groupId cse01 -location westus -environment d -identifier sample-sb-conn
    .EXAMPLE
        Deploys six instances for a logic app to the "westus" region.

        ./logic-app-deploy.ps1 -groupId cse02 -location westus -environment d -identifier sample-sb-conn -instanceCount 6
    .EXAMPLE
        Deploys six instances for a logic app to the "northcentralus" region by using the "ncus" abbreviation.
        
        ./logic-app-deploy.ps1 -groupId cse03 -location northcentralus -environment d -identifier sample-sb-conn -instanceCount 6 -abbrevLocationName ncus
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

    [Parameter(Mandatory = $True)]
    [string]
    $identifier,

    [Parameter(Mandatory = $False)]
    [string]
    $abbrevLocationName = $location,

    [Parameter(Mandatory = $False)]
    [string]
    $deploymentName = [guid]::NewGuid(),

    [Parameter(Mandatory = $False)]
    [string]
    $connectorsParametersFilePath = "../templates/connectors-parameters.json",

    [Parameter(Mandatory = $False)]
    [string]
    $connectorsTemplateFilePath = "../templates/connectors-template.json",

    [Parameter(Mandatory = $False)]
    [string]
    $logicAppParametersFilePath = "../templates/logic-app-arm-parameters.json",

    [Parameter(Mandatory = $False)]
    [string]
    $logicAppTemplateFilePath = "../templates/logic-app-template.json",

    [Parameter(Mandatory = $False)]
    [string]
    $logicAppDefinitionParametersFilePath = "../templates/logic-app-definition-parameters.json",

    [Parameter(Mandatory = $False)]
    [string]
    $logicAppDefinitionPath = "../templates/logic-app-definition.json",

    [Parameter(Mandatory = $False)]
    [int]
    $instanceCount = 1,

    [Parameter(Mandatory = $False)]
    [bool]
    $overrideExisting = $True
)

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
    $connectorsParametersFilePath = Set-RelativeFilePath -filePath $connectorsParametersFilePath
    $connectorsTemplateFilePath = Set-RelativeFilePath -filePath $connectorsTemplateFilePath
    $logicAppParametersFilePath = Set-RelativeFilePath -filePath $logicAppParametersFilePath
    $logicAppDefinitionParametersFilePath = Set-RelativeFilePath -filePath $logicAppDefinitionParametersFilePath
    $logicAppTemplateFilePath = Set-RelativeFilePath -filePath $logicAppTemplateFilePath
    $logicAppDefinitionPath = Set-RelativeFilePath -filePath $logicAppDefinitionPath
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

Function Set-LogicAppDeployment {
    <#
        .SYNOPSIS
            Create or update the instance for the logic app deployment.
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The instance number to deploy")]
        [int]$instance
    )

    $resourceGroupName = Get-ResourceGroupName -instance $instance

    Set-ResourceGroup -resourceGroupName $resourceGroupName;

    $armParameters = @{
        groupId      = $groupId
        environment  = $environment
        locationName = $abbrevLocationName
        identifier   = $identifier
        instance     = $instance
    };
    
    Write-Host "Deploying Azure Resource Manager template for connectors"
    $connectorsOutput = New-ResourceManagerTemplateDeployment -parametersFilePath $connectorsParametersFilePath `
        -templateFilePath $connectorsTemplateFilePath `
        -resourceGroupName $resourceGroupName `
        -armParameters $armParameters;

    $logicAppResource = Set-LogicAppResource `
        -resourceGroupName $resourceGroupName `
        -logicAppName $connectorsOutput.Outputs.logicAppName.Value`
        -armParameters $armParameters;
    
    Write-Host "Updating token values with output values"
    $definitionParameters = Set-DynamicParameters -sourceFilePath $logicAppDefinitionParametersFilePath -sourceParameters $connectorsOutput.Outputs;
    $definition = Set-DynamicParameters -sourceFilePath $logicAppDefinitionPath -sourceParameters $connectorsOutput.Outputs;
    
    Set-LogicAppDefinition -definitionParameters $definitionParameters -definition $definition -logicAppResource $logicAppResource
}

Function Get-ResourceGroupName {
    <#
        .SYNOPSIS
            Return the resource group name for the instance number that's passed as input.
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The instance number to deploy")]
        [int]$instance
    )

    # Let's use zero-based indexes for resource group names. 
    # That way, a single instance deployment isn't appended by an extra "-1", which adds confusion.

    if($instance -eq 1){
        return "{0}{1}rgp{2}-{3}" -f $groupId, $environment, $location, $identifier
    } else {
        return "{0}{1}rgp{2}-{3}-{4}" -f $groupId, $environment, $location, $identifier, ($instance - 1)
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
        foreach ($key in $armParameters.Keys) {
            New-Parameter -parameters $parametersFromFile -name $key -value $armParameters[$key]   
        }

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

Function Set-LogicAppResource {
    <#
        .SYNOPSIS
            Create or update the logic app resource in Azure.
        .DESCRIPTION
            Check whether the logic app resource exists. 
            If not or if the "overrideExisting" parameter is true, create an Azure Resource Manager 
            template deployment for the logic app.
        .OUTPUTS
            The current logic app resource in Azure when execution ends
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The name of the resource group for where to deploy the logic app resource")]
        [string]$resourceGroupName,
        [Parameter(Mandatory = $True, HelpMessage = "The name for the logic app resource to create")]
        [string]$logicAppName,
        [Parameter(Mandatory = $True, HelpMessage = "The script parameters to append to the deployment")]
        [hashtable]$armParameters
    )

    # If the "overrideExisting" parameter is set to true, always create a new deployment, whether or not the logic app exists.
    if($overrideExisting -eq $True){
        Write-Host "Deploying Azure Resource Manager template for logic app"
        $outputs = New-ResourceManagerTemplateDeployment -parametersFilePath $logicAppParametersFilePath `
            -templateFilePath $logicAppTemplateFilePath `
            -resourceGroupName $resourceGroupName `
            -armParameters $armParameters;
    }

    Write-Host "Checking whether the logic app exists: '$logicAppName'"
    $logicAppResource = Get-LogicAppResource `
        -resourceGroupName $resourceGroupName `
        -logicAppName $logicAppName;    

    # Even if the "overrideExisting" is false, if the logic app doesn't exist we need to create the resource.
    if ($null -eq $logicAppResource) {
        Write-Host "Deploying Azure Resource Manager template for logic app"
        $outputs = New-ResourceManagerTemplateDeployment -parametersFilePath $logicAppParametersFilePath `
            -templateFilePath $logicAppTemplateFilePath `
            -resourceGroupName $resourceGroupName `
            -armParameters $armParameters;

        $logicAppResource = Get-LogicAppResource `
            -resourceGroupName $resourceGroupName `
            -logicAppName $logicAppName;  
    }
  
    return $logicAppResource
}

Function Get-LogicAppResource {
    <#
        .SYNOPSIS
            Get the current logic app resource in Azure.
        .OUTPUTS
            The current logic app resource in Azure when execution ends
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The name for the resource group to search for the logic app")]
        [string]$resourceGroupName,
        [Parameter(Mandatory = $True, HelpMessage = "The name for the logic app to get")]
        [string]$logicAppName
    )

    return Get-AzResource `
        -ResourceGroupName $resourceGroupName `
        -ResourceName $logicAppName `
        -ResourceType Microsoft.Logic/workflows `
        -ErrorAction SilentlyContinue;    
}

Function Set-DynamicParameters {
    <#
        .SYNOPSIS
            Read the JSON file from the specified file path, replace tokens, and return the result as an object.
        .OUTPUTS
            The result from the updates as an object
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The path for the file to read and where to replace tokens")]
        [string]$sourceFilePath,
        [Parameter(Mandatory = $True, HelpMessage = "The hash table with the parameters to iterate through and use for replacing tokens")]
        [hashtable]$sourceParameters
    )
    $result = (Get-Content $sourceFilePath -Encoding UTF8 -Raw) 
    $result = Set-TokenValue -InputObject $result -parameters $sourceParameters;
    $result = ConvertFrom-Json -InputObject $result;

    return $result;
}

Function Set-TokenValue {
    <#
        .SYNOPSIS
            Replace the token values in the string that is passed as input with the parameter values that are also passed as input.
        .DESCRIPTION
            Iterate through each parameter that's passed as input and replace 
            all instances for the "parameter.key" value with the "parameter.value" 
            value found in the string that's passed as input.
        .OUTPUTS
            The result from the updates
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The value to search for the tokens to replace")]
        [string] $InputObject,
        [Parameter(Mandatory = $True, HelpMessage = "The hash table with the parameters to iterate through and use for replacing tokens")]
        [hashtable] $parameters
    )

    foreach ($key in $parameters.Keys) {
        $InputObject = $InputObject -replace "{$($key)}", $parameters[$key].Value;
    }
    return $InputObject;
}

Function Set-LogicAppDefinition {
    <#
        .SYNOPSIS
            Update the logic app definition in Azure.
    #>
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "The parameters to pass into the update for the logic app definition")]
        [object]$definitionParameters,
        [Parameter(Mandatory = $True, HelpMessage = "The logic app definition to update")]
        [object]$definition,
        [Parameter(Mandatory = $True, HelpMessage = "The logic app resource to update")]
        [object]$logicAppResource
    )
    Write-Host "Updating the logic app definition"
    $logicAppResource.Properties.parameters = $definitionParameters;
    $logicAppResource.Properties.definition = $definition;
    $logicAppResource | Set-AzResource -Force;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

# Fix the PSScriptRoot value for older versions of PowerShell 
if (!$PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

# Fix file paths when working directory differs from the script directory and relative paths are used
Set-RelativeFilePaths

# Register resource providers used by the deployment
$resourceProviders = @("microsoft.logic");
if ($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach ($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

# Create the logic apps
For ($i = 1; $i -le $instanceCount; $i++) {
    Set-LogicAppDeployment -instance $i;
}
